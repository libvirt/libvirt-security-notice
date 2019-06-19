#!/usr/bin/perl

use strict;
use warnings;

use Sort::Versions;

if (int(@ARGV) != 1) {
    die "syntax: $0 CHANGESET\n";
}

my $changeset = shift @ARGV;

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

my @branches;
my %tags;
my %branches;

$branches{"master"} = [];
# Most tags live on master so lets get them first
for my $tag (get_tags("--contains", $changeset, "--merged", "master")) {
    push @{$branches{"master"}}, $tag;
    $tags{$tag} = 1;
}
push @branches, "master";

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

    unless (exists($branches{$tagbranches[0]})) {
        $branches{$tagbranches[0]} = [];
        push @branches, $tagbranches[0];
    }
    push @{$branches{$tagbranches[0]}}, $tag;
}


foreach my $branch (sort versioncmp @branches) {
    print "    <branch>\n";
    print "      <name>$branch</name>\n";
    foreach my $tag (sort versioncmp @{$branches{$branch}}) {
        print "      <tag state=\"vulnerable\">$tag</tag>\n";
    }
    print "      <change state=\"vulnerable\">$changeset</change>\n";

    if ($branch eq "master") {
        print "      <change state=\"fixed\"></change>\n";
    }
    print "    </branch>\n";
}
