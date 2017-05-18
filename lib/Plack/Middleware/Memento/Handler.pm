package Plack::Middleware::Memento::Handler;

our $VERSION = '0.01';

use strict;
use warnings;
use Role::Tiny;
use namespace::clean;

requires 'get_all_mementos';

sub wrap_original_resource_request {
    return;
}

sub wrap_memento_request {
    return;
}

1;
