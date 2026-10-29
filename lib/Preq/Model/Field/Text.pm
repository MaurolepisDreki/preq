package Preq::Model::Field::Text 0.001;

use v5.36;

use parent 'Preq::Model::Field';

=head1 NAME

Preq::Model::Field::Text - Single-line text field

=head1 SYNOPSIS

	use Preq::Model::Field::Text;

	my $title = Preq::Model::Field::Text->new;
	$title->set('Store requirements as text files');

=head1 DESCRIPTION

A field holding a single line of text, such as a requirement's C<title> or
C<author>.

A value is invalid if it is empty, contains a line break, or is not a plain
string.

=head1 METHODS

=head2 get

	my $text = $field->get;

Returns the text, or C<undef> if the field has no value.

=cut

sub get($self) {
	return $self->{value};
}

=head2 set

	$field->set($text);

Sets the text. C<undef> clears the field.

=cut

sub set($self, $value) {
	$self->_store($value);
	return;
}

sub _validate($self) {
	my $value = $self->{value};
	return () unless defined $value;
	return ('is not text') if ref $value;
	return ('is empty') if $value eq '';
	return ('contains a line break') if $value =~ /[\r\n]/;
	return ();
}

1;

=head1 SEE ALSO

L<Preq::Model::Field>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Maurolepis Dreki.

This is free software, licensed under the Artistic License 2.0. See the
F<LICENSE> file in the distribution, or
L<https://opensource.org/license/artistic-2-0>.

=cut
