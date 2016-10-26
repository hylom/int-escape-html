# js2pl.pm
package Js2pl;
use Exporter 'import';

{
    package Js2pl::Array;
    sub new {
        my $class = shift;
        my $array = shift || [];
        return bless { array => $array }, $class;
    }
}

sub make_array {
    my $array = shift;
    return Js2pl::Array->new($array);
}
