package Plack::Middleware::Memento;

use strict;
use warnings;

our $VERSION = '0.01';

use Plack::Request;
use Plack::Util;
use DateTime::Format::Mail;
use parent 'Plack::Middleware';
use namespace::clean;

sub timegate_path {
    $_[0]->{timegate_path} ||= '/timegate';
}

sub timemap_path {
    $_[0]->{timemap_path} ||= '/timemap';
}

sub _handler_options {
    my ($self) = @_;
    $self->{_handler_options} ||= do {
        my $options = {};
        for my $key (keys %$self) {
            next if $key =~ /(?:^_)|(?:^(?:handler|timegate_path|timemap_path)$)/;
            $options->{$key} = $self->{$key};
        }
        $options;
    };
}

sub _handler {
    my ($self) = @_;
    $self->{_handler} ||= do {
        my $class = Plack::Util::load_class($self->{handler}, 'Plack::Middleware::Memento::Handler');
        $class->new($self->_handler_options);
    };
}

sub _build__rfc2822 {
    $_[0]->{_rfc2822} ||= DateTime::Format::Mail->new;
}

sub call {
    my ($self, $env) = @_;
    $self->_handle_timegate_request($env) ||
        $self->_handle_timemap_request($env) ||
        $self->app->($env);
}

sub _handle_timegate_request {
    my ($self, $env) = @_;

    my $prefix = $self->timegate_path;
    my $uri_r = $env->{PATH_INFO};
    $uri_r =~ s/^${prefix}// or return;
    $uri_r || return $self->_not_found;

    my $req = Plack::Request->new($env);

    my $mementos = $self->_handler->get_all_mementos($uri_r, $req) ||
        return $self->_not_found;

    my $dt = $self->_rfc2822->parse_datetime($req->header('Accept-Datetime'));

    for my $mem (@$mementos) {
        $mem->[2] = abs($mem->[1]->epoch - $dt->epoch);
    }

    my ($closest_mem) = sort { $a->[2] <=> $b->[2] } @$mementos;

    my @links = (
        $self->_original_link($uri_r),
        $self->_timemap_link($req->base, $uri_r, 'timemap', $mementos),
    );

    if (@$mementos == 1) {
        push @links, $self->_memento_link($closest_mem, 'first last memento');
    } elsif ($closest_mem->[0] eq $mementos->[0]->[0]) {
        push @links, $self->_memento_link($closest_mem, 'first memento');
        push @links, $self->_memento_link($mementos->[-1], 'last memento');
    } elsif ($closest_mem->[0] eq $mementos->[-1]->[0]) {
        push @links, $self->_memento_link($mementos->[0], 'first memento');
        push @links, $self->_memento_link($closest_mem, 'last memento');
    } else {
        push @links, $self->_memento_link($mementos->[0], 'first memento');
        push @links, $self->_memento_link($closest_mem, 'memento');
        push @links, $self->_memento_link($mementos->[-1], 'last memento');
    }

    [ 302,
        [
            'Vary' => 'accept-datetime',
            'Location' => $closest_mem->[0],
            'Content-Type' => 'text/plain; charset=UTF-8',
            'Connection' => 'close',
            'Content-Length' => '0',
            'Link' => join(",\n", @links),
        ],
        [ ],
    ];
}

sub _handle_timemap_request {
    my ($self, $env) = @_;

    my $prefix = $self->timemap_path;
    my $uri_r = $env->{PATH_INFO};
    $uri_r =~ s/^${prefix}// or return;
    $uri_r || return $self->_not_found;

    my $req = Plack::Request->new($env);

    my $mementos = $self->_handler->get_all_mementos($uri_r, $req) ||
        return $self->_not_found;

    my @links = (
        $self->_original_link($uri_r),
        $self->_timemap_link($req->base, $uri_r, 'self', $mementos),
        $self->_timegate_link($req->base, $uri_r),
    );

    if (@$mementos == 1) {
        push @links, $self->_memento_link($mementos->[0], 'first last memento');
    } else {
        if (my $first_mem = shift @$mementos) {
            push @links, $self->_memento_link($first_mem, 'first memento');
        }
        if (my $last_mem = pop @$mementos) {
            push @links, $self->_memento_link($last_mem, 'last memento');
        }
        push @links, map { $self->_memento_link($_, 'memento') } @$mementos;
    }

    [ 200,
        [
            'Content-Type' => 'application/link-format',
        ],
        [
            join(",\n", @links),
        ],
    ];
}

sub _not_found {
    my ($self) = @_;
    [ 404, [ 'Content-Type' => 'text/plain; charset=UTF-8' ], [] ];
}

sub _original_link {
    my ($self, $uri_r) = @_;
    qq|<$uri_r>; rel="original"|;
}

sub _timemap_link {
    my ($self, $base_url, $uri_r, $rel, $mementos) = @_;
    my $uri_t = join($base_url, $self->timemap_path, $uri_r);
    my $from = $self->rfc2822->format_datetime($mementos->[0]->[1]);
    my $until = $self->rfc2822->format_datetime($mementos->[-1]->[1]);
    qq|<$uri_t>; rel="$rel"; type="application/link-format"; from="$from"; until="$until"|;
}

sub _timegate_link {
    my ($self, $base_url, $uri_r) = @_;
    my $uri_t = join($base_url, $self->timegate_path, $uri_r);
    qq|<$uri_t>; rel="timegate"|;
}

sub _memento_link {
    my ($self, $mem, $rel) = @_;
    my $uri_m = $mem->[0];
    my $datetime = $self->rfc2822->format_datetime($mem->[1]);
    qq|<$uri_m>; rel="$rel"; datetime="$datetime"|;
}

1;

