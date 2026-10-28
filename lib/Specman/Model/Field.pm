package Specman::Model::Field 0.001;

use v5.36;

use parent 'Specman::Model::Node';

=head1 NAME

Specman::Model::Field - Field model for Specman

=head1 SYNOPSIS

	use Specman::Model::Field;

=head1 DESCRIPTION

Abstract base class for a field within a Specman model.

Validation and change notification are inherited from
L<Specman::Model::Node>.

Subclasses must implement C<get>, C<set> and C<_validate>; the default
implementations die with C<NotImplemented>. C<set> must call C<_changed>
after changing the value.

Subclasses holding a single value can implement C<set> with
C<_store($value)>, which stores the value in C<< $self->{value} >> and calls
C<_changed>, but only if the value differs from the current one.

At the field level, a field with no value (C<undef>) is valid. Whether a
field must have a value is decided by the record containing it.

=head1 METHODS

=head2 new

	my $field = Specman::Model::Field->new( %args );

Creates and returns a new, empty field. C<%args> is accepted for subclasses
but ignored by the base class.

=cut

sub new($class, %args) {
	return $class->SUPER::new(%args);
}

=head2 get

	$field->get;

Returns the value contained in Field.  Not implemented by default: dies with
C<NotImplemented>.

=cut

sub get($self) {
	die 'NotImplemented';
}

=head2 set

	$field->set( 'value' );

Sets the value contained in Field.  Not implemented by default: dies with
C<NotImplemented>.

=cut

sub set($self, $value) {
	die 'NotImplemented';
}

=head2 is_empty

	$field->is_empty;

Returns whether the field has no value, that is, whether C<get> returns
C<undef>.

=cut

sub is_empty($self) {
	return !defined $self->get;
}

sub _store($self, $value) {
	my $old = $self->{value};
	return if defined $old ? defined $value && $old eq $value : !defined $value;
	$self->{value} = $value;
	$self->_changed;
	return;
}

1;

=head1 SEE ALSO

L<Specman>, L<Specman::Model::Node>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.

=cut
