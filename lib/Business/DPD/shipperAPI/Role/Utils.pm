package Business::DPD::shipperAPI::Role::Utils;

our $VERSION = '0.01';

use 5.010;
use Moose::Role;

sub _get_update_status_reason {
    my ($headers) = @_;
    my $status = $headers->{Status};
    unless (HTTP::Status::status_message($status)) {
        $headers->{Reason} = sprintf('(%d) %s', $status, $headers->{Reason});
        $status = $headers->{Status} = 503;
    }
    return $status;
}

1;

__END__

=head1 NAME

Business::DPD::shipperAPI::Role::Utils - helper funtions

=cut

