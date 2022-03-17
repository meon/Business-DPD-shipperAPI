package Business::DPD::shipperAPI::Data::Parcel;

our $VERSION = '0.01';

use 5.010;
use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

has 'weight' => (
    isa      => 'Num',
    is       => 'ro',
    required => 1,
);
has 'width' => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
);
has 'height' => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
);
has 'depth' => (
    isa      => 'Int',
    is       => 'ro',
    required => 1,
);
has 'parcel_no' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_parcel_no',
);
has 'reference1' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_reference1',
);
has 'reference2' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_reference2',
);
has 'reference3' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    predicate => 'has_reference3',
);

sub as_data {
    my ($self) = @_;

    return {
        weight => $self->weight,
        width  => $self->width,
        height => $self->height,
        depth  => $self->depth,
        ($self->has_parcel_no  ? (parcel_no  => $self->parcel_no)  : ()),
        ($self->has_reference1 ? (reference1 => $self->reference1) : ()),
        ($self->has_reference2 ? (reference2 => $self->reference2) : ()),
        ($self->has_reference3 ? (reference3 => $self->reference3) : ()),
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Business::DPD::shipperAPI::Data::Parcel - parcel data object

=cut

