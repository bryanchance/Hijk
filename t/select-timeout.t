#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Hijk;
use Time::HiRes;

my $parent_pid = $$;
pipe(my $rh, my $wh) or die "Failed to create pipe: $!";

my $pid = fork;
die "Fail to fork then start a plack server" unless defined $pid;

if ($pid == 0) {
    Time::HiRes::sleep(0.5);
    for (1..10) {
        kill('HUP', $parent_pid);
        Time::HiRes::sleep(0.1);
    }
    exit;
}

$SIG{HUP} = sub { warn "SIGHUP received\n" };

my $timeout = 2;
vec(my $rin = '', fileno($rh), 2) = 1;

my $start = Time::HiRes::time;
Hijk::_select($rin, undef, undef, $timeout);
my $elapsed = Time::HiRes::time - $start;

{
    my $msg = sprintf("handle signal during select, took=%.2fs, expected at least=%.2fs", $elapsed, $timeout);
    if ($elapsed >= $timeout) {
        pass($msg);
    } else {
        TODO: {
            local $TODO = "We don't know why, but this fails on various BSDs etc. It is known, and probably some general OS issue. Don't clutter CPANtesters with it";
            fail($msg);
        }
    }
}

done_testing;
