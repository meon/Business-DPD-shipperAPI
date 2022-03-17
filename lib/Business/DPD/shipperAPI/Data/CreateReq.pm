package Business::DPD::shipperAPI::Data::CreateReq;

our $VERSION = '0.01';

use 5.010;
use Moose;
use MooseX::StrictConstructor;
use DateTime;

use namespace::autoclean;

with qw(Business::DPD::shipperAPI::Role::AuthAttrs);

has 'pickup_id' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has 'product' => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
    default  => 1,
);
has 'pickup_date' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => sub {$_[0]->_next_working_day_date},
);
has 'pickup_time' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => '0800',
);
has 'reference' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'parcels' => (
    isa      => 'ArrayRef[Business::DPD::shipperAPI::Data::Parcel]',
    is       => 'ro',
    required => 1,
);
has 'address_recipient' => (
    isa      => 'Business::DPD::shipperAPI::Data::Address',
    is       => 'ro',
    required => 1,
);

sub as_data {
    my ($self) = @_;
    my %req_data = (
        jsonrpc => '2.0',
        method  => 'create',
        params  => {
            DPDSecurity => {
                SecurityToken => {
                    ClientKey => $self->api_key,
                    Email     => $self->login_email,
                }
            },
            shipment => [
                {   addressRecipient => $self->address_recipient->as_data,
                    addressSender    => {id => $self->pickup_id,},
                    delisId          => $self->delis_id,
                    parcels          => {parcel => [map {$_->as_data} @{$self->parcels}],},
                    pickup           => {
                        date       => $self->pickup_date,
                        timeWindow => {beginning => $self->pickup_time,}
                    },
                    product   => $self->product,
                    reference => $self->reference,
                }
            ],
        }
    );
    return \%req_data;
}

sub _next_working_day_date {
    my ($self) = @_;
    my $dt = DateTime->now(time_zone => 'local');
    do {
        $dt->add(days => 1);
    } while ($dt->day_of_week > 5);    # 1..5 -> Mon..Fri
    return $dt->strftime('%Y%m%d');
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Business::DPD::shipperAPI::Data::CreateReq - create request data object

=cut
