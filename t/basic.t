use strict;
use Test::More;
use Plack::Middleware::Memento;

BEGIN {
    $pkg = 'Plack::Middleware::Memento';
    use_ok $pkg;
}

done_testing;
