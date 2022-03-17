package Business::DPD::shipperAPI;

our $VERSION = '0.01';

use 5.010;
use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::StrictConstructor;
use URI;
use URI::QueryParam;
use Log::Any qw($log);
use Future '0.44';
use Future::AsyncAwait;
use Future::HTTP::AnyEvent;
use HTTP::Exception;
use Run::Env;
use JSON;
use Time::HiRes qw(time);

use Business::DPD::shipperAPI::Data::CreateReq;
use Business::DPD::shipperAPI::Data::CreateResp;

use namespace::autoclean;

with qw(
    Business::DPD::shipperAPI::Role::AuthAttrs
    Business::DPD::shipperAPI::Role::Utils
);

has 'shipment_service_url' => (
    isa      => Uri,
    is       => 'ro',
    required => 1,
    coerce   => 1,
    lazy     => 1,
    default  => sub {
        (   Run::Env->production
            ? 'https://api.dpd.sk/shipment/json'
            : 'https://capi.dpd.sk/shipment/json'
        )
    },
);

has 'pickup_id' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_pickup_id',
);

has 'user_agent' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default =>
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36',
    lazy => 1,
);
has '_ua' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {Future::HTTP::AnyEvent->new()},
);
has '_json' => (
    is   => 'ro',
    lazy => 1,
    default =>
        sub {JSON->new()->utf8->pretty(Run::Env->debug ? 1 : 0)->canonical(Run::Env->debug ? 1 : 0)}
    ,
);

async sub _post_req {
    my ($self, $body_data) = @_;

    my $timer = time();
    my ($resp_body, $headers) = await $self->_ua->http_post(
        $self->shipment_service_url,
        $self->_json->encode($body_data),
        headers => {
            'Accept'       => 'application/json',
            'Content-Type' => 'application/json',
        },
    );

    my $status = _get_update_status_reason($headers);
    $log->debugf('api call status %d finished in %.3fs', $status, time() - $timer);
    HTTP::Exception->throw($status, status_message => $headers->{Reason})
        if ($status != 200);

    my $resp_data = eval {$self->_json->decode($resp_body)};
    HTTP::Exception->throw(500, status_message => sprintf('response body parsing error: %s', $@))
        if $@;

    return $resp_data;
}

sub call_create {
    my ($self, %args) = @_;
    return $self->call_create_ft(%args)->get;
}

async sub call_create_ft {
    my ($self, %args) = @_;

    my $req_data = Business::DPD::shipperAPI::Data::CreateReq->new(
        pickup_id   => $self->pickup_id,
        login_email => $self->login_email,
        api_key     => $self->api_key,
        delis_id    => $self->delis_id,
        %args,
    )->as_data;

    my $res_data = await $self->_post_req($req_data);

    return Business::DPD::shipperAPI::Data::CreateResp->new(
        resp_data => $res_data,
        _ua       => $self->_ua,
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Business::DPD::shipperAPI - Slovak DPD shipperAPI implementation

=head1 SYNOPSIS

    use Business::DPD::shipperAPI;

=head1 SEE ALSO

L<Business::DPD>

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2021 jkutej@cpan.org

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
