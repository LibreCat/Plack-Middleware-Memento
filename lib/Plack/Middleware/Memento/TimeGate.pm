package Plack::Middleware::Memento::TimeGate;

use strict;
use warnings;
use Plack::Request;
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
    my $uri = $env->{PATH_INFO};

    $uri =~ s/$path_match// or return;

    my $req = Plack::Request->new($env);
    my $datetime = $req->header('Accept-Datetime');

    my $memento_uri = $self->_handler->get_memento($uri, $datetime) || return $self->_not_found;    

    [ 302,
        [
            'Vary' => 'accept-datetime',
            'Location' => $memento_uri,
            'Content-Type' => 'text/plain; charset=UTF-8',
            'Link' => qq|<$uri>; rel="original",<>; rel="timegate", <>; rel="timemap"|,
        ],
        [ ],
    ];
}

sub _handler {
    my($self) = @_;
    $self->{_handler} ||= do {
        my $class = Plack::Util::load_class($self->handler, 'Plack::Middleware::Memento::Handler');
        $class->new($self->options || {});
    };
}

sub _not_found {
    my($self) = @_;
    [ 404,
        [
            'Content-Type' => 'text/plain; charset=UTF-8',
        ],
        [ ],
    ];
}

1;

