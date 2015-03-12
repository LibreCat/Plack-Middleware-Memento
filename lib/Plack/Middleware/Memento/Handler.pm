package Plack::Middleware::Memento::Handler;

use strict;
use warnings;
use Moo::Role;

requires 'get_memento';
requires 'get_all_mementos';

1;
