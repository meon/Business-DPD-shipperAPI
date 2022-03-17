package Business::DPD::shipperAPI::Data::Address;

our $VERSION = '0.01';

use 5.010;
use Moose;
use MooseX::StrictConstructor;
use Geography::Countries qw(country);

use namespace::autoclean;

has 'type' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default  => 'b2b',
);
has 'name' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'name_detail' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_name_detail',
);
has 'street' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'house_number' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'zip' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'country' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'city' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'phone' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_phone',
);
has 'email' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_email',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my %args;
    if (@_ == 1 && !ref $_[0]) {
        %args = %{$_[0]};
    }
    else {
        %args = @_;
    }

    if (my $shn = delete($args{street_house_number})) {
        my @shn_parts = split(/\s+/, $shn);
        $args{house_number} = pop(@shn_parts);
        $args{street}       = join(' ', @shn_parts);
    }

    return $class->$orig(%args);
};

sub as_data {
    my ($self) = @_;

    my (undef, undef, $country_no) = country($self->country);

    return {
        city        => $self->city,
        country     => $country_no,
        houseNumber => $self->house_number,
        name        => $self->name,
        street      => $self->street,
        type        => $self->type,
        zip         => $self->zip,
        ($self->has_phone       ? (phone      => $self->phone)       : ()),
        ($self->has_email       ? (email      => $self->email)       : ()),
        ($self->has_name_detail ? (nameDetail => $self->name_detail) : ()),
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Business::DPD::shipperAPI::Data::address - address data object

=cut

