# js2pl.pm
package Js2pl;
use Exporter 'import';

{
    package Js2pl::Array;
    sub new {
        my $class = shift;
        my $value = shift || [];
        return bless { array => $value }, $class;
    }

    sub self {
        my $self = shift;
        return wantarray ? @{$self->{array}} : $self->{array};
    }

    sub push {
        my ($self, $val) = @_;
        push @{$self->{array}}, $val; 
    }

    sub join {
        my ($self, $text) = @_;
        return join $text, @{$self->{array});
    }

    sub length {
        my $self = shift;
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
        my @ret = split /$rex/, $self->{string};
        return array(\@ret);
    }

    sub slice {
        my $self = shift;
        my $begin = shift;
        my $end = shift;
        if (defined $end) {
            my $length = length $self->{string};
            $length = ($end > 0) ? $length -= $end : $end;
            return substr $self->{string}, $begin, $length;
        } 
        else {
            return string(substr $self->{string}, $begin);
        }
    }
    sub trim {
        my $s = $self->{string};
        $s =~ s/^\s*(.*?)\s*$/$1/;
        return string($s);
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
        my @m = $target =~ /$self->{regex}/;
        if (@m) {
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
        my @k = keys %($self->{hash});
        return array(\@k);
    }
}
sub hash {
    return Js2pl::Hash->new(shift);
}

1;
