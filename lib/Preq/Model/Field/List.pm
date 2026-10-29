package Preq::Model::Field::List 0.001;

use v5.36;

use Carp qw(croak);
use parent 'Preq::Model::Field';

=head1 NAME

Preq::Model::Field::List - Field holding a list of other fields

=head1 SYNOPSIS

	use Preq::Model::Field::List;

	my $tags = Preq::Model::Field::List->new(
		of => 'Preq::Model::Field::Text',
	);
	$tags->set([qw(storage model)]);

	my $refines = Preq::Model::Field::List->new(
		of   => 'Preq::Model::Field::Relation',
		args => { type => 'refines' },
	);
	$refines->add('REQ-001');

=head1 DESCRIPTION

A field holding an ordered list of fields of one class, such as a
requirement's C<tags>, or its links of one relation type.

Each element is validated by its own class; its errors are reported prefixed
with its position, as in C<item 2: is empty>. A value appearing more than once
is also an error.

Changes to an element are changes to the list.

=head1 METHODS

=head2 new

	my $list = Preq::Model::Field::List->new(
		of   => $class,
		args => \%args,
	);

Creates and returns a new, empty list. C<of> is required and names the
L<Preq::Model::Field> subclass of the elements; it is loaded if needed.
C<args> is optional and is passed to the elements' C<new>.

=cut

sub new($class, %args) {
	my $of = $args{of} or croak 'of must name a field class';
	(my $file = "$of.pm") =~ s{::}{/}g;
	require $file;
	croak "$of is not a Preq::Model::Field" unless $of->isa('Preq::Model::Field');

	my $self = $class->SUPER::new(%args);
	$self->{of} = $of;
	$self->{args} = { ($args{args} // {})->%* };
	$self->{elements} = [];
	return $self;
}

=head2 get

	my $values = $list->get;

Returns a reference to an array of the elements' values.

=cut

sub get($self) {
	return [ map { $_->get } $self->{elements}->@* ];
}

=head2 set

	$list->set(\@values);

Replaces the elements with new ones holding the given values. C<undef>
empties the list. Any other value that is not an array reference also empties
the list, and makes it invalid until it is set again.

=cut

sub set($self, $values) {
	$self->_release($_) for $self->{elements}->@*;
	$self->{not_a_list} = defined $values && ref $values ne 'ARRAY';
	$self->{elements} = $self->{not_a_list} || !defined $values
		? []
		: [ map { $self->_element($_) } @$values ];
	$self->_changed;
	return;
}

=head2 is_empty

	$list->is_empty;

Returns whether the list has no elements and is not invalid.

=cut

sub is_empty($self) {
	return !$self->{elements}->@* && !$self->{not_a_list};
}

=head2 add

	my $element = $list->add($value);

Appends a new element holding the given value, and returns it.

=cut

sub add($self, $value) {
	my $element = $self->_element($value);
	push $self->{elements}->@*, $element;
	$self->_changed;
	return $element;
}

=head2 remove

	my $element = $list->remove($index);

Removes the element at the given position, counting from 0, and returns it.

=cut

sub remove($self, $index) {
	return unless $index >= 0 && $index < $self->{elements}->@*;
	my ($element) = splice $self->{elements}->@*, $index, 1;

	$self->_release($element);
	$self->_changed;
	return $element;
}

=head2 elements

	my @fields = $list->elements;

Returns the element fields.

=cut

sub elements($self) {
	return $self->{elements}->@*;
}

sub _element($self, $value) {
	my $element = $self->{of}->new($self->{args}->%*);
	$element->set($value);
	return $self->_adopt($element);
}

sub _validate($self) {
	return ('is not a list') if $self->{not_a_list};

	my @elements = $self->{elements}->@*;
	my @errors;

	for my $i (0 .. $#elements) {
		$elements[$i]->is_valid;
		push @errors, map { $_->within(item => $i + 1) } $elements[$i]->errors;
	}

	my %seen;
	for my $value (grep { defined && !ref } map { $_->get } @elements) {
		push @errors, "'$value' is listed more than once" if $seen{$value}++ == 1;
	}

	return @errors;
}

1;

=head1 SEE ALSO

L<Preq::Model::Field>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.

=cut
