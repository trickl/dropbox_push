#!/usr/bin/perl
my $blanked = 0;
open (IN, "xscreensaver-command -watch |");
while (<IN>) {
    if (m/^(BLANK|LOCK)/) {
        if (!$blanked) {
            touch $1;
            $blanked = 1;
        }
    } elsif (m/^UNBLANK/) {
        rm $1;
        $blanked = 0;
    }
}
