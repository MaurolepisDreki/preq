package Preq::Model::Record::Requirement 0.001;

use v5.36;

use parent 'Preq::Model::Record';

use Preq::Model::Error;
use Preq::Model::Field::Relation;

=head1 NAME

Preq::Model::Record::Requirement - A requirement

=head1 SYNOPSIS

	use Preq::Model::Record::Requirement;

	my $req = Preq::Model::Record::Requirement->new;
	$req->set_values({
		id      => 'REQ-002',
		title   => 'Store requirements as text files',
		status  => 'approved',
		created => '2026-10-27',
		refines => ['REQ-001'],
		body    => "Each requirement shall be stored as one text file.\n",
	});

	say $req->id;
	say $_->type, ' ', $_->get for $req->relations;

=head1 DESCRIPTION

A requirement record, with the fixed set of fields described in
L<Preq::Manual::Format>. In order:

	id              Field::Id        required
	title           Field::Text      required
	status          Field::Enum      required  draft, approved, implemented, obsolete
	priority        Field::Enum                low, medium, high
	author          Field::Text
	created         Field::Date      required
	tags            Field::List of Field::Text
	refines         Field::List of Field::Relation (refines)
	depends_on      Field::List of Field::Relation (depends_on)
	conflicts_with  Field::List of Field::Relation (conflicts_with)
	body            Field::Markdown

Besides the errors of its fields, a requirement is invalid if:

=over

=item *

it relates to itself, as in C<refines: item 1: 'REQ-002' refers to itself>;

=item *

its body is empty, or only whitespace, while its status is a valid status
other than C<draft>.

=back

Whether related requirements exist, and whether relations form cycles, are
checked by the collection holding the requirements.

=cut

sub _fields($class) {
	my $base = 'Preq::Model::Field';
	return (
		id       => { class => "${base}::Id", required => 1 },
		title    => { class => "${base}::Text", required => 1 },
		status   => {
			class    => "${base}::Enum",
			args     => { allowed => [qw(draft approved implemented obsolete)] },
			required => 1,
		},
		priority => { class => "${base}::Enum", args => { allowed => [qw(low medium high)] } },
		author   => { class => "${base}::Text" },
		created  => { class => "${base}::Date", required => 1 },
		tags     => { class => "${base}::List", args => { of => "${base}::Text" } },
		(map {
			$_ => {
				class => "${base}::List",
				args  => { of => "${base}::Relation", args => { type => $_ } },
			}
		} qw(refines depends_on conflicts_with)),
		body     => { class => "${base}::Markdown" },
	);
}

=head1 METHODS

=head2 id

	my $id = $req->id;

Returns the requirement's identifier, or C<undef> if it has none.

=cut

sub id($self) {
	return $self->field('id')->get;
}

=head2 relations

	my @links = $req->relations;

Returns all the requirement's relations, as L<Preq::Model::Field::Relation>
fields, grouped by type in the order of L</DESCRIPTION>.

=cut

sub relations($self) {
	return map { $self->field($_)->elements } qw(refines depends_on conflicts_with);
}

sub _validate($self) {
	my @errors = $self->SUPER::_validate;

	my $id = $self->id;
	if (defined $id) {
		for my $type (qw(refines depends_on conflicts_with)) {
			my @links = $self->field($type)->elements;
			for my $i (0 .. $#links) {
				my $target = $links[$i]->get;
				push @errors, Preq::Model::Error->new(
					field   => $type,
					item    => $i + 1,
					message => "'$id' refers to itself",
				) if defined $target && $target eq $id;
			}
		}
	}

	my $status_field = $self->field('status');
	my $status = $status_field->get;
	my $body = $self->field('body')->get;
	push @errors, Preq::Model::Error->new(field => 'body', message => 'is required unless status is draft')
		if defined $status && $status ne 'draft' && $status_field->is_valid
			&& (!defined $body || (!ref $body && $body !~ /\S/));

	return @errors;
}

1;

=head1 SEE ALSO

L<Preq::Model::Record>, L<Preq::Manual::Format>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Maurolepis Dreki.

This is free software, licensed under the Artistic License 2.0. See the
F<LICENSE> file in the distribution, or
L<https://opensource.org/license/artistic-2-0>.

=cut
