#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.014;
use autodie;
use Data::Dumper;

use Regexp::Rules;
use Test::More;

grammar Arith {
   rule TOP { (?&additive) };
   rule additive  { (?&multitive) (?: ([+-])  (?&multitive) )* };
   rule multitive { (?&primary)   (?: ([*\/]) (?&primary)   )* };
   token primary { ( [0-9]+ ) | (?: [(] (?&additive) [)] ) };
};

note Arith->regexp;
note Dumper(Arith->parse('(3+5)*2'));

# -------------------------------------------------------------------------

subtest 'sexp' => sub {
    my $ret = Arith->parse('3+5*2', Regexp::Rules::SexpAction::);
    is $ret, '(+ 3 (* 5 2))', '3+5*2';
    my $ret = Arith->parse('(3+5)*2', Regexp::Rules::SexpAction::);
    is $ret, '(* (+ 3 5) 2)', '(3+5)*2';
};

# -------------------------------------------------------------------------

package Calculator {
    sub TOP {
        my ($class, $children) = @_;
        @$children;
    }
    sub multitive {
        my ($class, $children) = @_;
        if (defined $^N) {
            my $ret = eval '(' . join($^N, @$children) . ')';
            die $@ if $@;
            $ret;
        } else {
            $children->[0];
        }
    }
    sub additive {
        my ($class, $children) = @_;
        if (defined $^N) {
            my $ret = eval '(' . join($^N, @$children) . ')';
            die $@ if $@;
            $ret;
        } else {
            $children->[0];
        }
    }
    sub primary {
        $^N
    }
}

subtest 'action' => sub {
    my $ret = Arith->parse('3+5', Calculator::);
    is $ret, 8;
};

done_testing;
