package Plack::Middleware::Memento::Handler;

our $VERSION = '0.01';

use strict;
use warnings;
use Role::Tiny;
use namespace::clean;

requires 'get_all_mementos';

1;
