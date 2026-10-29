package Preq::Model::Field::Id 0.001;

use v5.36;

use parent 'Preq::Model::Field::Text';

=head1 NAME

Preq::Model::Field::Id - Requirement identifier field

=head1 SYNOPSIS

	use Preq::Model::Field::Id;

	my $id = Preq::Model::Field::Id->new;
	$id->set('REQ-001');

=head1 DESCRIPTION

A field holding a requirement identifier: C<REQ-> followed by three or more
digits, for example C<REQ-001>.

It is a L<Preq::Model::Field::Text>, so the same rules for text apply
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

L<Preq::Model::Field::Text>, L<Preq::Manual::Format>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Maurolepis Dreki.

This is free software, licensed under the Artistic License 2.0. See the
F<LICENSE> file in the distribution, or
L<https://opensource.org/license/artistic-2-0>.

=cut
