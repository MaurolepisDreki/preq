package Specman::Model::Field::Date 0.001;

use v5.36;

use parent 'Specman::Model::Field::Text';

=head1 NAME

Specman::Model::Field::Date - Calendar date field

=head1 SYNOPSIS

	use Specman::Model::Field::Date;

	my $created = Specman::Model::Field::Date->new;
	$created->set('2026-10-27');

=head1 DESCRIPTION

A field holding a calendar date in the form C<YYYY-MM-DD>, such as a
requirement's C<created> date. The date must exist: C<2026-02-29> is
invalid, C<2024-02-29> is not.

It is a L<Specman::Model::Field::Text>, so the same rules for text apply
first.

=cut

sub _validate($self) {
	my @errors = $self->SUPER::_validate;
	return @errors if @errors;

	my $value = $self->{value};
	return () unless defined $value;

	my ($y, $m, $d) = $value =~ /\A([0-9]{4})-([0-9]{2})-([0-9]{2})\z/
		or return ("'$value' is not a date (YYYY-MM-DD)");
	return ("'$value' is not a valid date")
		unless $m >= 1 && $m <= 12 && $d >= 1 && $d <= _days_in_month($y, $m);
	return ();
}

sub _days_in_month($y, $m) {
	return 29 if $m == 2 && ($y % 4 == 0 && $y % 100 != 0 || $y % 400 == 0);
	return (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)[$m - 1];
}

1;

=head1 SEE ALSO

L<Specman::Model::Field::Text>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.

=cut
