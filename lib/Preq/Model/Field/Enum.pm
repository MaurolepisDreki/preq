package Preq::Model::Field::Enum 0.001;

use v5.36;

use Carp qw(croak);
use parent 'Preq::Model::Field::Text';

=head1 NAME

Preq::Model::Field::Enum - Field limited to a fixed set of words

=head1 SYNOPSIS

	use Preq::Model::Field::Enum;

	my $status = Preq::Model::Field::Enum->new(
		allowed => [qw(draft approved implemented obsolete)],
	);
	$status->set('draft');

=head1 DESCRIPTION

A field whose value must be one of a fixed list of words, such as a
requirement's C<status> or C<priority>.

It is a L<Preq::Model::Field::Text>, so the same rules for text apply
first.

=head1 METHODS

=head2 new

	my $field = Preq::Model::Field::Enum->new( allowed => \@words );

Creates and returns a new, empty field. C<allowed> is required and lists the
permitted values, in the order they are presented to users.

=cut

sub new($class, %args) {
	my $allowed = $args{allowed};
	croak 'allowed must be a non-empty array reference'
		unless ref $allowed eq 'ARRAY' && @$allowed;

	my $self = $class->SUPER::new(%args);
	$self->{allowed} = [@$allowed];
	return $self;
}

=head2 allowed

	my @words = $field->allowed;

Returns the permitted values.

=cut

sub allowed($self) {
	return $self->{allowed}->@*;
}

sub _validate($self) {
	my @errors = $self->SUPER::_validate;
	return @errors if @errors;

	my $value = $self->{value};
	return () if !defined $value || grep { $_ eq $value } $self->{allowed}->@*;
	return ("'$value' is not one of " . join(', ', $self->{allowed}->@*));
}

1;

=head1 SEE ALSO

L<Preq::Model::Field::Text>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.

=cut
