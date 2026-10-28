package Specman::Model::Field::Id 0.001;

use v5.36;

use parent 'Specman::Model::Field::Text';

=head1 NAME

Specman::Model::Field::Id - Requirement identifier field

=head1 SYNOPSIS

	use Specman::Model::Field::Id;

	my $id = Specman::Model::Field::Id->new;
	$id->set('REQ-001');

=head1 DESCRIPTION

A field holding a requirement identifier: C<REQ-> followed by three or more
digits, for example C<REQ-001>.

It is a L<Specman::Model::Field::Text>, so the same rules for text apply
first.

=cut

sub _validate($self) {
	my @errors = $self->SUPER::_validate;
	return @errors if @errors;

	my $value = $self->{value};
	return () if !defined $value || $value =~ /\AREQ-[0-9]{3,}\z/;
	return ("'$value' is not a requirement ID (REQ- followed by three or more digits)");
}

1;

=head1 SEE ALSO

L<Specman::Model::Field::Text>, L<Specman::Manual::Format>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.

=cut
