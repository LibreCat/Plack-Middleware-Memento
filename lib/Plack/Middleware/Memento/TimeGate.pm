package Plack::Middleware::Memento::TimeGate;

use strict;
use warnings;
use Plack::Request;
use Plack::Util ();
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(
    timegate_path
    timemap_path
    handler
    options
);

sub call {
    my($self, $env) = @_;
    my $res = $self->_handle_timegate_request($env) ||
        $self->_handle_timemap_request($env);
    if ($res) {
      return $res;
    }
    $self->app->($env);
}

sub _handle_timegate_request {
    my($self, $env) = @_;

    my $path_match = $self->timegate_path or return;
    my $uri = $env->{PATH_INFO};

    $uri =~ s/$path_match// or return;

    my $req = Plack::Request->new($env);
    my $datetime = $req->header('Accept-Datetime');

    my $memento_uri = $self->_handler->get_memento($uri, $datetime) ||
        return $self->_handle_not_found;    

    return [ 302,
        [
            'Vary' => 'accept-datetime',
            'Location' => $memento_uri,
            'Content-Type' => 'text/plain; charset=UTF-8',
            'Link' => qq|<$uri>; rel="original",<>; rel="timegate", <>; rel="timemap"|,
        ],
        [ ],
    ];
}

sub _handle_timemap_request {
    my($self, $env) = @_;

    my $path_match = $self->timemap_path or return;
    my $uri = $env->{PATH_INFO};

    $uri =~ s/$path_match// or return;

    my $mementos = $self->_handler->get_all_mementos($uri);

    [ 200,
        [
            'Content-Type' => 'application/link-format',
        ],
        [   
            qq|<$uri>; rel="original",\n|,
            qq|<>; rel="self"; type="application/link-format",\n|,
            $self->_to_link_format(@$mementos),
        ],
    ];
}

sub _handler {
    my($self) = @_;
    $self->{_handler} ||= do {
        my $class = Plack::Util::load_class($self->handler, 'Plack::Middleware::Memento::Handler');
        $class->new($self->options || {});
    };
}

sub _handle_not_found {
    my($self) = @_;
    [ 404, [ 'Content-Type' => 'text/plain; charset=UTF-8' ], [] ];
}

sub _to_link_format {
    my ($self, @mementos) = @_;
    my $body = join(",\n", map {
        my ($uri, $datetime) = @$_;
        qq|<$uri>; rel="memento"; datetime="$datetime"|;
    } @mementos);
    "$body\n";
}

1;

