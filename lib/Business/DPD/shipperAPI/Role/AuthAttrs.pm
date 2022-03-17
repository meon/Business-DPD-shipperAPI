package Business::DPD::shipperAPI::Role::AuthAttrs;

our $VERSION = '0.01';

use 5.010;
use Moose::Role;

has 'login_email' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'delis_id' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);
has 'api_key' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

1;

__END__

=head1 NAME

Business::DPD::shipperAPI::Role::AuthAttrs - API authentication attributes role

=cut

