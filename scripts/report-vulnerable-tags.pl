#!/usr/bin/perl

use strict;
use warnings;

use Sort::Versions;

if (int(@ARGV) != 1) {
    die "syntax: $0 NOTICE.XML\n";
}

my @broken;
my $broken;
my @fixed;
my $fixed;
my $notice = shift @ARGV;
my @notice;

open NOTICE, $notice or die "cannot read $notice: $!";
my $master;
my $discard;
for my $line (<NOTICE>) {
    push @notice, $line unless $discard;
    if ($line =~ m,<repository>,) {
        $discard = 1;
    } elsif ($line =~ m,<name>master</name>,) {
        $master = 1;
    } elsif ($line =~ m,</branch>,) {
        $master = 0;
    } elsif ($master) {
        if ($line =~ m,<change state="(vulnerable|fixed)">([a-zA-Z0-9]+)</change>,) {
            if ($1 eq "vulnerable") {
                push @broken, $2;
            } else {
                push @fixed, $2;
            }
        }
    }
}
close NOTICE;

if (int(@broken)) {
    $broken = $broken[0];
}
if (int(@fixed)) {
    $fixed = $fixed[$#fixed];
}

# branch name to hash with keys
#   - brokenchanges -> list of commit ids
#   - brokentags -> hash of tag names to '1'
#   - fixedchanges -> list of commit ids
#   - fixedtags -> hash of tag names to '1'
my %branches;

# tag name to '0' (fixed) or '1' (broken)
my %tags;


sub get_tags {
    my @args = @_;

    my @tags;
    open GIT, "-|", "git", "tag", @args or
    die "cannot query 'git tags @args': $!\n";

    while (<GIT>) {
        chomp;

        # Drop anything except  vN.N.N style tags
        # where 'N' is only digits.
        if (/^v(\d+)(\.\d+)+$/) {
            push @tags, $_;
        }
    }

    close GIT;

    return @tags;
}

sub get_branches {
    my $tag = shift;

    my @branches;
    open GIT, "-|", "git", "branch", "--all", "--contains", $tag or
    die "cannot query 'git branch --all --contains $tag': $!\n";

    while (<GIT>) {
        chomp;

        if (m,^\s*remotes/origin/(v.*-maint)$,) {
            push @branches, $1;
        }
    }

    close GIT;

    return @branches;
}

sub get_cherry_picks {
    my $branch = shift @_;
    my $tag = shift @_;

    open GIT, "-|", "git", "log", "$tag..origin/$branch" or
        die "cannot query 'git log $tag..origin/$branch': $!\n";

    my $commit;
    my %cherrypicks;
    while (<GIT>) {
        chomp;

        if (/^commit ([a-zA-Z0-9]+)/) {
            $commit = $1;
        } elsif (/cherry picked from commit ([a-zA-Z0-9]+)/) {
            $cherrypicks{$1} = $commit;
        }
    }

    return %cherrypicks;
}

sub get_fuzzy_picks {
    my $branch = shift @_;
    my $tag = shift @_;

    my %subjects;

    for my $commit (@fixed) {
        open GIT, "-|", "git", "show", "--no-patch", "--format=%s", $commit
            or die "cannot query 'git show --no-patch --format=%s $commit': $!";
        my $subject = <GIT>;
        chomp $subject;
        close GIT;

        $subjects{$subject} = $commit;
    }

    open GIT, "-|", "git", "log", "--format=%H %s", "$tag..origin/$branch" or
        die "cannot query 'git log --format='%h %s' $tag..origin/$branch': $!\n";

    my $commit;
    my %fuzzypicks;
    while (<GIT>) {
        if (/([a-zA-Z0-9]+)\s(.*)$/) {
            if (exists $subjects{$2}) {
                $fuzzypicks{$subjects{$2}} = $1;
            }
        }
    }

    return %fuzzypicks;
}

sub add_branch {
    my $name = shift @_;

    return if exists $branches{$name};

    $branches{$name} = {
       "brokenchanges" => [@broken],
       "brokentags" => {},
       "fixedchanges" => [],
       "fixedtags" => {},
    };
}

sub delete_branch {
    my $name = shift @_;

    if (int(keys %{$branches{$name}->{"brokentags"}})) {
        print "Branch $name shouldn't have broken tags\n";
    }
    delete $branches{$name};
}

sub add_broken_tag {
    my $branch = shift @_;
    my $tag = shift @_;

    $tags{$tag} = 1;
    $branches{$branch}->{"brokentags"}->{$tag} = 1;
}

sub add_fixed_tag {
    my $branch = shift @_;
    my $tag = shift @_;

    $tags{$tag} = 0;
    $branches{$branch}->{"fixedtags"}->{$tag} = 1;
}

sub add_fixed_commit {
    my $branch = shift @_;
    my $commit = shift @_;

    push @{$branches{$branch}->{"fixedchanges"}}, $commit;
}

add_branch("master");

if (defined $fixed) {
    # Mark any tags containing the fix as known so they
    # get excluded when later finding vulnerable tags
    for my $tag (get_tags("--contains", $fixed)) {
        $tags{$tag} = 0;
    }


    # Record the first tag in master which has the fix, if any
    my @fixedtags = sort versioncmp get_tags("--contains", $fixed, "--merged", "master");
    if (int(@fixedtags)) {
        add_fixed_tag("master", $fixedtags[0]);
    }

    for my $commit (@fixed) {
        add_fixed_commit("master", $commit);
    }
}

if (defined $broken) {
    # Most tags live on master so lets get them first
    for my $tag (get_tags("--contains", $broken, "--merged", "master")) {

        next if exists $tags{$tag};

        add_broken_tag("master", $tag);
    }

    for my $branch (get_branches($broken)) {
        add_branch($branch);
    }
}

if (defined $fixed) {
    # Try to match up fixed commit with cherry-picks
    for my $branch (sort versioncmp keys %branches) {
        next if $branch eq "master";

        my $basetag = $branch;
        $basetag =~ s/-maint//;
        my @bits = split /\./, $basetag;

        if (int(@bits) == 2) {
            $basetag = $basetag . ".0";
        }

        my %cherrypicks = get_cherry_picks($branch, $basetag);

        my @missing;
        for my $commit (@fixed) {
            if (exists $cherrypicks{$commit}) {
                my $cherry = $cherrypicks{$commit};
                add_fixed_commit($branch, $cherry);
            } else {
                push @missing, $commit;
            }
        }

        if (int(@missing)) {
            my @unfixed = @missing;
            my %fuzzypicks = get_fuzzy_picks($branch, $basetag);
            @missing = ();
            for my $commit (@unfixed) {
                if (exists $fuzzypicks{$commit}) {
                    my $fuzzy = $fuzzypicks{$commit};
                    add_fixed_commit($branch, $fuzzy);
                } else {
                    push @missing, $commit;
                }
            }
        }

        # If all fixes on master exist on branch, then
        # identify any tags holding the last cherry-pick
        # so the branch gets marked as non-vulnerable.
        if (int(@missing) == 0) {
            my $bfixed = $branches{$branch}->{fixedchanges}->[$#{$branches{$branch}->{fixedchanges}}];
            # Mark any tags containing the fix as known so they
            # get excluded when later finding vulnerable tags
            for my $tag (get_tags("--contains", $bfixed)) {
                $tags{$tag} = 0;
            }

            # Record the first tag in master which has the fix, if any
            my @fixedtags = sort versioncmp get_tags("--contains", $bfixed, "--merged", $branch);
            if (int(@fixedtags)) {
                add_fixed_tag($branch, $fixedtags[0]);
            }
        }
    }
}

if (defined $broken) {
    # Now we need slower work to find branches for
    # few remaining tags
    for my $tag (get_tags("--contains", $broken)) {
        next if exists $tags{$tag};

        # Hack as tag was mistakenly not on master branch
        if ($tag eq "v2.1.0") {
            $branches{"master"}->{"brokentags"}->{$tag} = 1;
            next;
        }

        die "malformed tag $tag" unless $tag =~ /(v.*)\.(\d+)$/;
        my $branch = "$1-maint";

        if (!exists $branches{$branch}) {
            print "Tag $tag mapped to branch $branch which doesn't exist\n";
            next;
        }

        add_broken_tag($branch, $tag);
    }
}

if (defined $fixed) {
    for my $branch (get_branches($fixed)) {
        delete_branch($branch);
    }
}

open NOTICE, ">$notice.tmp" or die "cannot create $notice.tmp: $!";
foreach my $line (@notice) {
    print NOTICE $line;
}

foreach my $branch (sort versioncmp keys %branches) {
    print NOTICE "    <branch>\n";
    print NOTICE "      <name>$branch</name>\n";

    foreach my $tag (sort versioncmp keys %{$branches{$branch}->{"brokentags"}}) {
        print NOTICE "      <tag state=\"vulnerable\">$tag</tag>\n";
    }
    foreach my $change (@{$branches{$branch}->{"brokenchanges"}}) {
        print NOTICE "      <change state=\"vulnerable\">$change</change>\n";
    }

    foreach my $tag (sort versioncmp keys %{$branches{$branch}->{"fixedtags"}}) {
        print NOTICE "      <tag state=\"fixed\">$tag</tag>\n";
    }
    foreach my $change (@{$branches{$branch}->{"fixedchanges"}}) {
        print NOTICE "      <change state=\"fixed\">$change</change>\n";
    }
    print NOTICE "    </branch>\n";
}

print NOTICE "  </product>\n";
print NOTICE "\n";
print NOTICE "</security-notice>\n";
close NOTICE;

rename "$notice.tmp", "$notice" or die "cannot replace $notice: $!";
