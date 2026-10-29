package Preq::Model::Field::Relation 0.001;

use v5.36;

use Carp qw(croak);
use parent 'Preq::Model::Field::Id';

=head1 NAME

Preq::Model::Field::Relation - A single typed link to another requirement

=head1 SYNOPSIS

	use Preq::Model::Field::Relation;

	my $link = Preq::Model::Field::Relation->new(type => 'refines');
	$link->set('REQ-001');

	$link->type;            # 'refines'
	$link->is_acyclic;      # true

=head1 DESCRIPTION

A field holding one link from a requirement to another: the relation's type
and the identifier of its target. A requirement with several links of the same
type holds them in a L<Preq::Model::Field::List> of relations.

It is a L<Preq::Model::Field::Id>; its value is the target's identifier,
and the same rules for identifiers apply. A relation without a target is
invalid.

Whether the target exists, and whether links form a cycle, depend on other
requirements and are checked by the collection holding them.

=head2 Relation types

The relation types are fixed:

=over

=item C<refines>

The target is the requirement this one is a more detailed part of. Acyclic.

=item C<depends_on>

The target must be satisfied before this requirement can be. Acyclic.

=item C<conflicts_with>

The target contradicts this requirement. Symmetric.

=back

=cut

my %TYPES = (
	refines        => { acyclic => 1 },
	depends_on     => { acyclic => 1 },
	conflicts_with => { symmetric => 1 },
);

=head1 METHODS

=head2 new

	my $link = Preq::Model::Field::Relation->new( type => $type );

Creates and returns a new relation of the given type, without a target. Dies
if C<type> is not one of the L</Relation types>.

=cut

sub new($class, %args) {
	my $type = $args{type} // '';
	croak "unknown relation type '$type'" unless $TYPES{$type};

	my $self = $class->SUPER::new(%args);
	$self->{type} = $type;
	return $self;
}

=head2 types

	my @types = Preq::Model::Field::Relation->types;

Returns the names of all relation types.

=cut

sub types($class) {
	return sort keys %TYPES;
}

=head2 type

	my $type = $link->type;

Returns the relation's type.

=cut

sub type($self) {
	return $self->{type};
}

=head2 is_acyclic

	$link->is_acyclic;

Returns whether links of this type must not form a cycle.

=cut

sub is_acyclic($self) {
	return !!$TYPES{$self->{type}}{acyclic};
}

=head2 is_symmetric

	$link->is_symmetric;

Returns whether a link of this type also holds in the reverse direction.

=cut

sub is_symmetric($self) {
	return !!$TYPES{$self->{type}}{symmetric};
}

sub _validate($self) {
	return ('has no target') unless defined $self->{value};
	return $self->SUPER::_validate;
}

1;

=head1 SEE ALSO

L<Preq::Model::Field::Id>, L<Preq::Model::Field::List>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.

=cut
