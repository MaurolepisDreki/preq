package Preq::Model::Record 0.001;

use v5.36;

use Carp qw(croak);
use parent 'Preq::Model::Node';

use Preq::Model::Error;

=head1 NAME

Preq::Model::Record - Abstract base class for preq records

=head1 SYNOPSIS

	package Preq::Model::Record::Example;
	use parent 'Preq::Model::Record';

	sub _fields($class) {
		return (
			id    => { class => 'Preq::Model::Field::Id', required => 1 },
			title => { class => 'Preq::Model::Field::Text' },
		);
	}

	package main;

	my $record = Preq::Model::Record::Example->new;
	$record->set_values({ id => 'REQ-001', title => 'Example' });
	$record->field('title')->set('Another example');

	unless ($record->is_valid) {
		say for $record->errors;    # "id: is required", ...
	}

=head1 DESCRIPTION

Abstract base class for a record: a named, ordered set of fields, such as a
requirement.

Validation and change notification are inherited from
L<Preq::Model::Node>. A record's errors are those of its fields, prefixed
with the field's name, plus:

=over

=item *

C<NAME: is required> for each required field that is empty;

=item *

C<NAME: is not a known field> for each value given to L</set_values> that
has no field.

=back

A change to any field is a change to the record.

=head2 Subclassing

Subclasses must implement the class method C<_fields>, which returns a list of
field names and specifications, in order:

	name => { class => $field_class, args => \%args, required => $bool }

C<class> is loaded if needed and C<args> is passed to its C<new>. C<args> and
C<required> are optional.

Subclasses can add record-level rules by overriding C<_validate>, including
the errors of C<< $self->SUPER::_validate >> in the result.

=head1 METHODS

=head2 new

	my $record = Preq::Model::Record::Example->new( %args );

Creates and returns a new record with all its fields empty. C<%args> is
accepted for subclasses but ignored by the base class.

=cut

sub new($class, %args) {
	my $self = $class->SUPER::new(%args);
	$self->{order} = [];
	$self->{fields} = {};
	$self->{required} = {};
	$self->{unknown} = [];

	my @fields = $class->_fields;
	while (my ($name, $spec) = splice @fields, 0, 2) {
		(my $file = "$spec->{class}.pm") =~ s{::}{/}g;
		require $file;

		push $self->{order}->@*, $name;
		$self->{fields}{$name} = $self->_adopt($spec->{class}->new(($spec->{args} // {})->%*));
		$self->{required}{$name} = 1 if $spec->{required};
	}

	return $self;
}

=head2 field_names

	my @names = $record->field_names;

Returns the names of the record's fields, in order.

=cut

sub field_names($self) {
	return $self->{order}->@*;
}

=head2 field

	my $field = $record->field($name);

Returns the field with the given name. Dies if the record has no such field.

=cut

sub field($self, $name) {
	return $self->{fields}{$name} // croak "no field named '$name'";
}

=head2 is_required

	$record->is_required($name);

Returns whether the field with the given name must have a value.

=cut

sub is_required($self, $name) {
	$self->field($name);
	return !!$self->{required}{$name};
}

=head2 get_values

	my $values = $record->get_values;

Returns a reference to a hash of every field's name and value.

=cut

sub get_values($self) {
	return { map { $_ => $self->{fields}{$_}->get } $self->{order}->@* };
}

=head2 set_values

	$record->set_values(\%values);

Replaces the values of all fields with the given ones, counting as a single
change. Fields not named in C<%values> are emptied. Names with no field are
remembered, and reported as errors until the values are set again.

=cut

sub set_values($self, $values) {
	croak 'set_values expects a hash reference' unless ref $values eq 'HASH';

	$self->_batch(sub {
		$self->{unknown} = [ sort grep { !$self->{fields}{$_} } keys %$values ];
		$self->{fields}{$_}->set($values->{$_}) for $self->{order}->@*;
	});
	return;
}

sub _fields($class) {
	die 'NotImplemented';
}

sub _validate($self) {
	my @errors;

	for my $name ($self->{order}->@*) {
		my $field = $self->{fields}{$name};
		if ($field->is_empty) {
			push @errors, Preq::Model::Error->new(field => $name, message => 'is required')
				if $self->{required}{$name};
			next;
		}
		$field->is_valid;
		push @errors, map { $_->within(field => $name) } $field->errors;
	}

	push @errors, map {
		Preq::Model::Error->new(field => $_, message => 'is not a known field')
	} $self->{unknown}->@*;
	return @errors;
}

1;

=head1 SEE ALSO

L<Preq::Model::Node>, L<Preq::Model::Field>,
L<Preq::Model::Record::Requirement>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Maurolepis Dreki.

This is free software, licensed under the Artistic License 2.0. See the
F<LICENSE> file in the distribution, or
L<https://opensource.org/license/artistic-2-0>.

=cut
