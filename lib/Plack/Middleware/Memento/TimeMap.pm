package Plack::Middleware::Memento::TimeMap;

use strict;
use warnings;
use Plack::Util ();
use Plack::Util::Accessor qw(path handler options);
use parent qw(Plack::Middleware);

sub call {
    my($self, $env) = @_;
    my $res = $self->_handle($env);
    if ($res) {
      return $res;
    }
    $self->app->($env);
}

sub _handle {
    my($self, $env) = @_;

    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};

    $path =~ s/$path_match// or return;

    my $mementos = $self->_handler->get_all_mementos($path);
    use Data::Dumper;
    [ 200,
        [
            'Content-Type' => 'application/link-format',
        ],
        [ Dumper($mementos) ],
    ];
}

sub _handler {
    my($self) = @_;
    $self->{_handler} ||= do {
        my $class = Plack::Util::load_class($self->handler, 'Plack::Middleware::Memento::Handler');
        $class->new($self->options || {});
    };
}

1;

