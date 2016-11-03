# js2pl.pm
package Js2pl;
use strict;
use warnings;
use utf8;
use Data::Dumper;

use Exporter 'import';
our @EXPORT = qw(array hash string regex);

{
    package Js2pl::Array;
    sub new {
        my ($class, $value) = @_;
        $value ||= [];
        return bless { array => $value }, $class;
    }

    sub self {
        my ($self) = @_;
        return wantarray ? @{$self->{array}} : $self->{array};
    }

    sub push {
        my ($self, $val) = @_;
        push @{$self->{array}}, $val; 
    }

    sub shift {
        my ($self, $val) = @_;
        return shift @{$self->{array}}; 
    }

    sub join {
        my ($self, $text) = @_;
        my @t = map {$_->{string}} @{$self->{array}};
        return join $text, @t;
    }

    sub length {
        my ($self) = @_;
        return scalar @{$self->{array}};
    }
}

sub array {
    return Js2pl::Array->new(shift);
}

{
    package Js2pl::String;
    sub new {
        my $class = shift;
        my $value = shift || "";
        return bless { string => $value }, $class;
    }

    sub split {
        my ($self, $rex) = @_;
        my @ret = split $rex, $self->{string};
        @ret = map {Js2pl::string($_)} @ret;
        return Js2pl::array(\@ret);
    }

    sub slice {
        my $self = shift;
        my $begin = shift;
        my $end = shift;
        if (defined $end) {
            if ($end < 0) {
                my $length = length $self->{string};
                $end = $length - $end;
            }
            return Js2pl::string(substr($self->{string}, $begin, $end - $begin));
        } 
        else {
            return Js2pl::string(substr $self->{string}, $begin);
        }
    }

    sub trim {
        my $self = shift;
        my $s = $self->{string};
        $s =~ s/^\s*(.*?)\s*$/$1/;
        return Js2pl::string($s);
    }

    sub length {
        my $self = shift;
        return length $self->{string};
    }

    sub charAt {
        my $self = shift;
        my $index = shift;
        return substr $self->{string}, $index, 1;
    }

    sub replace {
        my $self = shift;
        my $pattern = shift;
        my $replace = shift;
        my $s = $self->{string};
        $s =~ s/$pattern/$replace/;
        return Js2pl::string($s);
    }

    sub match {
        my $self = shift;
        my $pattern = shift;
        my @m = $self->{string} =~ $pattern;
        if (@m) {
            unshift @m, $self->{string};
            return \@m;
        }
        return;
    }
}

sub string {
    return Js2pl::String->new(shift);
}

{
    package Js2pl::RegEx;
    sub new {
        my $class = shift;
        my $value = shift || "";
        return bless { regex => $value }, $class;
    }
    sub exec {
        my ($self, $target) = @_;
        my @m = $target->{string} =~ $self->{regex};
        if (@m) {
            unshift @m, $target->{string};
            return \@m;
        }
        return;
    }
}
sub regex {
    return Js2pl::RegEx->new(shift);
}

{
    package Js2pl::Hash;
    sub new {
        my $class = shift;
        my $value = shift || {};
        return bless { hash => $value }, $class;
    }
    sub keys {
        my ($self) = @_;
        my @k = keys %{$self->{hash}};
        return Js2pl::array(\@k);
    }
}

sub hash {
    return Js2pl::Hash->new(shift);
}

1;
