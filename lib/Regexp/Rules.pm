package Regexp::Rules;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";
use parent qw(Exporter);

use Parse::Keyword {
    grammar => \&parse_grammar,
    rule    => \&parse_rule,
    token   => \&parse_token,
};
our @EXPORT = qw(grammar rule token);
use Carp ();

our $PACKAGE;
our @RULES;
our @TOKENS;
our $TOP_OK;
our $ACTION;
our @STACK;

our $NESTED;
BEGIN {
    $NESTED = qr/ \{( [^{}] | (??{ $NESTED }) )* \} /x ;
    # $NESTED = qr!\A ( \{ (?: [^{}] | (??{ $NESTED }) )* \} )!x;
}

sub grammar {
    my ($name, $block) = @_;
    local $PACKAGE = $name;
    local @RULES;
    local @TOKENS;
    local $TOP_OK;
    $block->();

    unless ($TOP_OK) {
        Carp::croak "Missing TOP rule in $name";
    }

    my $re = _construct_regexp();

    no strict 'refs';
    unshift @{"${name}::ISA"}, 'Regexp::Rules::Base';
    *{"${name}::regexp"} = sub { $re };
}

sub _prepare {
    push @STACK, [];
}

sub _finalize {
    my $name = shift;
    my $top = pop @STACK;
    push $STACK[-1], $ACTION->$name($top);
}

sub _compile_re {
    my ($name, $re, $is_token) = @_;
    my $arg = $is_token ? '$^N' : do {
        "Regexp::Rules::_pop_stack('$name')"
    };
    return "    (?<$name>  (?> (?{ Regexp::Rules::_prepare() }) $re (?{ Regexp::Rules::_finalize('$name') })))";
}

sub _construct_regexp {
    my @inner;
    for my $rule (@RULES) {
        my ($name, $re) = @$rule;
        push @inner, _compile_re($name, $re, 0);
    }
    for my $token (@TOKENS) {
        my ($name, $re) = @$token;
        $re = "(?:$re)";
        push @inner, _compile_re($name, $re, 1);
    }
    my $inner = join("\n", @inner);
    use re 'eval';
    my $re = qr{
  (?&TOP)
  (?(DEFINE)
$inner
  )}msx;
    return $re;
#   qr{
#       (?&additive)
#       (?(DEFINE)
#           # additive <- multitive ([+-] multitive)*
#           (?<additive>
#               (?> (?&multitive) (?: ([+-]) (?&multitive) (?{ $a=shift @stack; $b=shift @stack; push @stack, [$^N, $a, $b] }))*) )
#           # multitive <- primary ([*/] primary)*
#           (?<multitive>
#               (?> (?&primary) (?:([*/]) (?&primary)  (?{ $a= shift @stack; $b = shift @stack; push @stack, [$^N, $a, $b] }))*) )
#           # primary <- [0-9]+ / [(] additive [)]
#           (?<primary>
#                   (?>([0-9]+)(?{ push @stack, $^N }) | [(] (?&additive) [)]) )
#       )
#   }msx;
}

sub rule {
    my ($name, $re) = @_;
    if ($name eq 'TOP') {
        $TOP_OK++;
    }
    push @RULES, [$name, $re];
}

sub token   {
    my ($name, $re) = @_;
    push @TOKENS, [$name, $re];
}

sub parse_grammar {
    lex_read_space;
    die "syntax error." unless lex_peek(1024) =~ /\A([A-Z0-9a-z:]+)/;
    my $name = $1;
    lex_read(length($1));
    lex_read_space;
    die "syntax error!" unless lex_peek eq '{';
    my $block= parse_block;
    lex_read_space;

    return (sub { $name, $block });
}

sub parse_rule {
    lex_read_space;

    # parse name
    die "syntax error?" unless lex_peek(1024) =~ /\A([A-Z0-9a-z:]+)/;
    my $name = $1;
    lex_read(length($1));
    lex_read_space;

    # TODO: support balanced parens like `rule foo { x{1,3} }`
    die "syntax error!!" unless lex_peek(1024) =~ qr{\A ( $NESTED )}x;
    my $re = $1;
    lex_read(length($1));
    $re =~ s/\A\{//;
    $re =~ s/\}\z//;
    lex_read_space;

    return (sub { $name, $re });
}

# token NAME REGEXP
sub parse_token {
    lex_read_space;

    # parse name
    die "syntax error?" unless lex_peek(1024) =~ /\A([A-Z0-9a-z:]+)/;
    my $name = $1;
    lex_read(length($1));
    lex_read_space;

    # TODO: support balanced parens like `token foo { x{1,3} }`
    die "syntax error!!" unless lex_peek(1024) =~ qr{\A ( $NESTED )}x;
    my $re = $1;
    lex_read(length($1));
    $re =~ s/\A\{//;
    $re =~ s/\}\z//;
    lex_read_space;

    return (sub { $name, $re });
}

package Regexp::Rules::Base {
    sub parse {
        my ($class, $expression, $action) = @_;
        local $ACTION = $action // 'Regexp::Rules::DefaultAction';
        local @STACK = ([]);
        my $regexp = $class->regexp;
        my $ok = ($expression =~ /\A(?:$regexp)\z/);
        return $ok ? shift $STACK[0] : undef;
    }
}

package Regexp::Rules::DefaultAction {
    our $AUTOLOAD;
    sub DESTROY { }
    sub AUTOLOAD {
        my ($class, $stuff) = @_;
        my $meth = substr $AUTOLOAD, length('Regexp::Rules::DefaultAction::');
        # use Data::Dumper; warn Dumper([$meth, $stuff]);
        if (defined $^N) {
            if (@$stuff == 0) {
                $^N;
            } else {
                [$^N, $stuff];
            }
        } else {
            @$stuff == 1 ? $stuff->[0] : $stuff;
        }
    }
}

package Regexp::Rules::SexpAction {
    our $AUTOLOAD;
    sub DESTROY { }
    sub AUTOLOAD {
        my ($class, $stuff) = @_;
        my $meth = substr $AUTOLOAD, length('Regexp::Rules::SexpAction::');
        # use Data::Dumper; warn Dumper([$meth, $stuff]);
        if (defined $^N) {
            if (@$stuff == 0) {
                $^N;
            } else {
                "($^N " . join(" ", @$stuff) . ")";
            }
        } else {
            join(' ', @$stuff);
        }
    }
}

1;
__END__

=for stopwords binded

=encoding utf-8

=head1 NAME

Regexp::Rules - (EXPERIMENTAL) Write your rules in Perl6 like syntax.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Regexp::Rules is yet another parser library, has a Perl6 rules like grammar.

This library is under construction. Patches welcome. Any API may change without notice.

B<Current implementation was broken. I want to fix.>

=head1 MOTIVATION

I want a parser library like Perl6 rules, but respects Perl5.

=head1 HOW DO I WRITE GRAMMARS?

    grammar NAME {
        rule TOP { REGEXP_BODY };
        token NAME { REGEXP_BODY };
        rule NAME { REGEXP_BODY };
    }

Grammar binded with namespace.

grammar block takes one or more rules and tokens.

You must write TOP rule. It's entry point for parsing.

So, you need to put parenthesis if you want to capture it. Then, you can use C<$^N> in your action.

=head1 HOW DO I USE GRAMMARS?

After you write a C< grammar SimpleGrammar { ... } >, you can call C<< SimpleGrammar->parse($expresssion[, $action]) >>.

C<$action> is optional. Regexp::Rules uses Regexp::Rules::DefaultAction by default. It constructs very simple AST, was showed at SYNOPSIS section.

=head1 HOW DO I WRITE ACTIONS?

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

So, C<$^N> is a last captured stuff. See L<perlvar>. You can use it for last captured result, especially an operator.

You can get a children nodes from arguments.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Perl6::Rules>

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

