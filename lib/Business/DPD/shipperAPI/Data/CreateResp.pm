package Business::DPD::shipperAPI::Data::CreateResp;

our $VERSION = '0.01';

use 5.010;
use Moose;
use MooseX::StrictConstructor;
use Future::AsyncAwait;
use Future::HTTP::AnyEvent;
use Time::HiRes qw(time);
use Log::Any qw($log);

with qw(Business::DPD::shipperAPI::Role::Utils);

use namespace::autoclean;

has 'resp_data' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
);

has '_ua' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {Future::HTTP::AnyEvent->new()},
);

has '_result' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {$_[0]->resp_data->{result}->{result}->[0]},
);

has 'is_success' => (
    isa      => 'Bool',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
        eval {$_[0]->_result->{success}}
    },
);

has 'label_url' => (
    isa      => 'URI',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {URI->new($_[0]->_result->{label})},
);
has 'mpsid' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {$_[0]->_result->{mpsid}},
);
has 'error_msg' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    lazy     => 1,
    default  => sub {
        eval {
            join("\n", map {(ref($_) eq 'HASH' ? $_->{value} : $_)} @{$_[0]->_result->{messages}})
                // '';
        }
    },
);

sub get_label_pdf {
    my ($self, %args) = @_;
    return $self->get_label_pdf_ft(%args)->get;
}

async sub get_label_pdf_ft {
    my ($self) = @_;

    my $timer = time();
    my ($resp_body, $headers) = await $self->_ua->http_get($self->label_url);

    my $status = _get_update_status_reason($headers);
    $log->debugf('labels fetch status %d finished in %.3fs', $status, time() - $timer);
    HTTP::Exception->throw($status, status_message => $headers->{Reason})
        if (int($status / 100) != 2);

    return $resp_body;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Business::DPD::shipperAPI::Data::CreateResp - response for create request

=cut
