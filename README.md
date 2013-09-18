# NAME

Regexp::Rules - Write your rules in Perl6 like syntax.

# SYNOPSIS

    use Regexp::Rules;

    grammar Arith {
        rule TOP { (?&additive) };
        rule additive { (?&multitive) ( [+-] (?&multitive) )* };
        rule multitive { (?&primary) ( [*/] (?&primary) )* };
        token primary { [0-9]+ };
    };

    my $ret = Arith->parse('3+5');
    use Data::Dumper; warn Dumper($ret);

Output is:

    $VAR1 = [
            'TOP',
            [
                [
                'additive',
                [
                    [
                    'multitive',
                    [
                        [
                        'primary',
                        '5'
                        ]
                    ]
                    ]
                ]
                ],
                [
                'multitive',
                [
                    [
                    'primary',
                    '3'
                    ]
                ]
                ]
            ]
            ];

# DESCRIPTION

Regexp::Rules is yet another parser library, has a Perl6 rules like grammar.

This library is under construction. Patches welcome. Any API may change without notice.

__Current implementation was broken. I want to fix.__

# MOTIVATION

I want a parser library like Perl6 rules, but respects Perl5.

# SYNOPSIS AGAIN

    grammar NAME {
        rule TOP { REGEXP_BODY };
        token NAME { REGEXP_BODY };
        rule NAME { REGEXP_BODY };
    }

Grammar binded with namespace.

grammar block takes one or more rules and tokens.

You must write TOP rule. It's entry point for parsing.

# HOW TO USE Grammar CLASS.

After you write a ` grammar SimpleGrammar { ... } `, you can call `SimpleGrammar->parse($expresssion[, $action])`.

`$action` is optional. Regexp::Rules uses Regexp::Rules::DefaultAction by default. It constructs very simple AST, was showed at SYNOPSIS section.

You can write your own action like following.



# HOW IT WORKS



# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Perl6::Rules](http://search.cpan.org/perldoc?Perl6::Rules)

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
