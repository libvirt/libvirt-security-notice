#!/usr/bin/perl

use strict;
use warnings;

use Sort::Versions;

if (int(@ARGV) != 1) {
    die "syntax: $0 CHANGESET\n";
}

my $changeset = shift @ARGV;

# branch name to hash with keys
#   - brokenchanges -> list of commit ids
#   - brokentags -> hash of tag names to '1'
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

sub get_branch {
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

sub add_branch {
    my $name = shift @_;

    return if exists $branches{$name};

    $branches{$name} = {
       "brokenchanges" => [$changeset],
       "brokentags" => {},
    };
}

sub add_broken_tag {
    my $branch = shift @_;
    my $tag = shift @_;

    $tags{$tag} = 1;
    $branches{$branch}->{"brokentags"}->{$tag} = 1;
}

add_branch("master");

# Most tags live on master so lets get them first
for my $tag (get_tags("--contains", $changeset, "--merged", "master")) {
    add_broken_tag("master", $tag);
}

# Now we need slower work to find branches for
# few remaining tags
for my $tag (get_tags("--contains", $changeset)) {

    next if exists $tags{$tag};

    my @tagbranches = get_branch($tag);
    if (int(@tagbranches) == 0) {
        if ($tag eq "v2.1.0") {
            @tagbranches = ("master")
        } else {
            print "Tag $tag doesn't appear in any branch\n";
            next;
        }
    }

    if (int(@tagbranches) > 1) {
        print "Tag $tag appears in multiple branches\n";
    }
    my $branch = $tagbranches[0];

    add_branch($branch);
    add_broken_tag($branch, $tag);
}


foreach my $branch (sort versioncmp keys %branches) {
    print "    <branch>\n";
    print "      <name>$branch</name>\n";
    foreach my $tag (sort versioncmp keys %{$branches{$branch}->{"brokentags"}}) {
        print "      <tag state=\"vulnerable\">$tag</tag>\n";
    }
    foreach my $commit (@{$branches{$branch}->{"brokenchanges"}}) {
        print "      <change state=\"vulnerable\">$commit</change>\n";
    }

    if ($branch eq "master") {
        print "      <change state=\"fixed\"></change>\n";
    }
    print "    </branch>\n";
}
