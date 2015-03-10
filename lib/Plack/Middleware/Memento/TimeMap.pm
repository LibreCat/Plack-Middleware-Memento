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
    my $uri = $env->{PATH_INFO};

    $uri =~ s/$path_match// or return;

    my $mementos = $self->_handler->get_all_mementos($uri);

    [ 200,
        [
            'Content-Type' => 'application/link-format',
        ],
        [   
            qq|<$uri>; rel="original",|,
            qq|<>; rel="self"; type="application/link-format",|,
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

sub _to_link_format {
    my ($self, @mementos) = @_;
    my $body = join(",\n", map {
        my ($uri, $datetime) = @$_;
        qq|<$uri>; rel="memento"; datetime="$datetime"|;
    } @mementos);
    "$body\n";
}

1;

