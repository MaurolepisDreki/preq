package Preq::Model::Field::Markdown 0.001;

use v5.36;

use parent 'Preq::Model::Field';

=head1 NAME

Preq::Model::Field::Markdown - Markdown text field

=head1 SYNOPSIS

	use Preq::Model::Field::Markdown;

	my $body = Preq::Model::Field::Markdown->new;
	$body->set("Each requirement shall be stored as one text file.\n");

=head1 DESCRIPTION

A field holding text written in CommonMark Markdown, such as a requirement's
body. Any text is valid Markdown, so the only invalid value is one that is
not a plain string.

=head1 METHODS

=head2 get

	my $markdown = $field->get;

Returns the Markdown text, or C<undef> if the field has no value.

=cut

sub get($self) {
	return $self->{value};
}

=head2 set

	$field->set($markdown);

Sets the Markdown text. C<undef> clears the field.

=cut

sub set($self, $value) {
	$self->_store($value);
	return;
}

sub _validate($self) {
	my $value = $self->{value};
	return () if !defined $value || !ref $value;
	return ('is not text');
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
