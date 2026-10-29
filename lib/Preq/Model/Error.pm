package Preq::Model::Error 0.001;

use v5.36;

use Carp qw(croak);
use overload '""' => sub ($self, @) { $self->as_string }, fallback => 1;

=head1 NAME

Preq::Model::Error - A problem found while validating a preq model

=head1 SYNOPSIS

	use Preq::Model::Error;

	my $error = Preq::Model::Error->new(
		field   => 'status',
		message => "'done' is not one of draft, approved, implemented, obsolete",
	);

	my $located = $error->within(file => 'REQ-002.md', id => 'REQ-002');

	say $located;               # REQ-002.md: status: 'done' is not one of ...
	say $located->field;        # status
	say $located->severity;     # error

=head1 DESCRIPTION

An error is a message describing one problem, its severity, and where the
problem is. Errors are immutable.

Errors are found from the inside out: a field reports a problem with its
value, and each container around it adds where it is, using L</within>. A
list adds the item, a record the field, a repository the file and the
requirement's identifier.

=head2 Location

The location of a problem is given by up to four parts, all optional:

=over

=item C<file>

The name of the file holding the requirement.

=item C<id>

The identifier of the requirement.

=item C<field>

The name of the field within the requirement.

=item C<item>

The position of the element within a list field, counting from 1.

=back

=head2 Severity

C<error> marks something that makes a model invalid. C<warning> marks
something worth attention that does not: a node with only warnings is still
valid.

=head2 As a string

An error used as a string gives its location and message, separated by
colons. The file is shown rather than the identifier when both are known:

	REQ-002.md: tags: item 2: is empty

=cut

my @LOCATION = qw(file id field item);
my %SEVERITY = map { $_ => 1 } qw(error warning);

=head1 METHODS

=head2 new

	my $error = Preq::Model::Error->new(
		message  => $text,
		severity => 'error',
		file     => $name,
		id       => $id,
		field    => $name,
		item     => $position,
	);

Creates and returns a new error. C<message> is required. C<severity> is
C<error> or C<warning>, by default C<error>. The location parts are optional.
Dies if given anything else.

=cut

sub new($class, %args) {
	croak 'message is required' unless defined $args{message};

	my $severity = $args{severity} // 'error';
	croak "unknown severity '$severity'" unless $SEVERITY{$severity};

	my %known = map { $_ => 1 } qw(message severity), @LOCATION;
	my ($unknown) = sort grep { !$known{$_} } keys %args;
	croak "unknown argument '$unknown'" if defined $unknown;

	return bless {
		message  => $args{message},
		severity => $severity,
		map { $_ => $args{$_} } grep { defined $args{$_} } @LOCATION,
	}, $class;
}

=head2 message

Returns the message, without the location.

=head2 severity

Returns the severity: C<error> or C<warning>.

=head2 file

Returns the file part of the location, or C<undef> if it is not known.

=head2 id

Returns the identifier part of the location, or C<undef> if it is not known.

=head2 field

Returns the field part of the location, or C<undef> if it is not known.

=head2 item

Returns the item part of the location, or C<undef> if it is not known.

=cut

sub message($self)  { return $self->{message} }
sub severity($self) { return $self->{severity} }
sub file($self)     { return $self->{file} }
sub id($self)       { return $self->{id} }
sub field($self)    { return $self->{field} }
sub item($self)     { return $self->{item} }

=head2 is_error

Returns whether the severity is C<error>.

=cut

sub is_error($self) {
	return $self->{severity} eq 'error';
}

=head2 location

	my $location = $error->location;

Returns a reference to a hash of the known parts of the location.

=cut

sub location($self) {
	return { map { $_ => $self->{$_} } grep { defined $self->{$_} } @LOCATION };
}

=head2 within

	my $outer = $error->within(file => $name, id => $id);

Returns a copy of the error with the given location parts added. Parts the
error already has are kept; C<undef> values are ignored. Dies if given
anything other than location parts.

=cut

sub within($self, %location) {
	my %args = %$self;
	for my $part (sort keys %location) {
		croak "unknown location part '$part'" unless grep { $_ eq $part } @LOCATION;
		$args{$part} //= $location{$part};
	}
	return (ref $self)->new(%args);
}

=head2 as_string

	my $text = $error->as_string;

Returns the error as a string, as described in L</As a string>.

=cut

sub as_string($self) {
	my @parts = (
		$self->{file} // $self->{id},
		$self->{field},
		defined $self->{item} ? "item $self->{item}" : undef,
	);
	return join ': ', (grep { defined } @parts), $self->{message};
}

=head2 equals

	$error->equals($other);

Returns whether two errors have the same message, severity and location.

=cut

sub equals($self, $other) {
	for my $key (qw(message severity), @LOCATION) {
		my ($mine, $theirs) = ($self->{$key}, $other->{$key});
		return 0 if defined $mine != defined $theirs || (defined $mine && $mine ne $theirs);
	}
	return 1;
}

=head2 TO_JSON

Returns a reference to a hash of the error's message, severity, location
parts, and C<text>, the error as a string. Used by JSON encoders.

=cut

sub TO_JSON($self) {
	return { %{ $self->location }, message => $self->{message}, severity => $self->{severity}, text => $self->as_string };
}

1;

=head1 SEE ALSO

L<Preq::Model::Node>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.

=cut
