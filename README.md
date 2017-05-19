# NAME

Plack::Middleware::Memento - Enable the Memento protocol

# SYNOPSIS

    use Plack::Builder;
    use Plack::App::Catmandu::Bag;

    builder {
        enable 'Memento', handler => 'Catmandu::Bag', store => 'authority', bag => 'person';
        Plack::App::Catmandu::Bag->new(
            store => 'authority',
            bag => 'person',
        )->to_app;
    };

# DESCRIPTION

This is an early minimal release, documentation and tests are lacking.

# AUTHOR

Nicolas Steenlant <nicolas.steenlant@ugent.be>

# COPYRIGHT

Copyright 2017- Nicolas Steenlant

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
