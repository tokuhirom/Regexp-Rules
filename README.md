# NAME

Regexp::Rules - Write your rules in Perl6 like syntax.

# SYNOPSIS

    use Regexp::Rules;

    grammar Arith {
        rule TOP { (?&additive) };
        rule additive  { (?&multitive) (?: ([+-])  (?&multitive) )* };
        rule multitive { (?&primary)   (?: ([*\/]) (?&primary)   )* };
        token primary { ( [0-9]+ ) | (?: [(] (?&additive) [)] ) };
    };

    my $ret = Arith->parse('3+5');
    use Data::Dumper; warn Dumper($ret);

Output is:

    $VAR1 = [
                '+',
                [
                    '3',
                    '5'
                ]
            ];

# DESCRIPTION

Regexp::Rules is yet another parser library, has a Perl6 rules like grammar.

This library is under construction. Patches welcome. Any API may change without notice.

__Current implementation was broken. I want to fix.__

# MOTIVATION

I want a parser library like Perl6 rules, but respects Perl5.

# HOW DO I WRITE GRAMMARS?

    grammar NAME {
        rule TOP { REGEXP_BODY };
        token NAME { REGEXP_BODY };
        rule NAME { REGEXP_BODY };
    }

Grammar binded with namespace.

grammar block takes one or more rules and tokens.

You must write TOP rule. It's entry point for parsing.

So, you need to put parenthesis if you want to capture it. Then, you can use `$^N` in your action.

# HOW DO I USE GRAMMARS?

After you write a ` grammar SimpleGrammar { ... } `, you can call `SimpleGrammar->parse($expresssion[, $action])`.

`$action` is optional. Regexp::Rules uses Regexp::Rules::DefaultAction by default. It constructs very simple AST, was showed at SYNOPSIS section.

# HOW DO I WRITE ACTIONS?

Action class is separated from grammars. It's plain old perl class.

You can write your own action like following.

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

So, `$^N` is a last captured stuff. See [perlvar](http://search.cpan.org/perldoc?perlvar). You can use it for last captured result, especially an operator.

You can get a children nodes from arguments.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Perl6::Rules](http://search.cpan.org/perldoc?Perl6::Rules)

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
