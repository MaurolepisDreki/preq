package Specman::Model::Node 0.001;

use v5.36;

use Scalar::Util qw(weaken);
use Time::HiRes ();

use Specman::Model::Error;

=head1 NAME

Specman::Model::Node - Validation and change notification for Specman models

=head1 SYNOPSIS

	package Specman::Model::Example;
	use parent 'Specman::Model::Node';

	sub _validate($self) {
		return defined $self->{value} ? () : ('value: missing');
	}

	package main;

	my $node = Specman::Model::Example->new;

	my $id = $node->on_errors_updated(sub ($node, @errors) { ... });

	unless ($node->is_valid) {
		say for $node->errors;
	}

=head1 DESCRIPTION

Abstract base class for everything in a Specman model that can be validated,
such as fields and records.

A node validates itself when L</is_valid> is called and caches the resulting
list of errors. The cache is rebuilt only after the node has changed.

Nodes can be nested: a parent adopts its children with C<_adopt>. When a
child changes, its parent is marked as changed too, all the way up.

Changes can be observed in two ways:

=over

=item *

Immediately, by subscribing with L</on_errors_updated>. A node with
subscribers revalidates as soon as it changes.

=item *

At leisure, by polling L</errors_updated_at>. A node without subscribers
revalidates only when L</is_valid> is next called.

=back

=head2 Subclassing

Subclasses must implement C<_validate>, which returns the list of problems
found in the node, or an empty list if there are none. Each problem is a
L<Specman::Model::Error>, or a plain string, which is turned into an error
with that message and no location.

A parent's C<_validate> should include the errors of its children, by calling
their C<is_valid> and C<errors>, adding where each child is with
L<Specman::Model::Error/within>.

Every method that changes a node must call C<_changed> afterwards.

A parent adds a child with C<_adopt($child)> and removes one with
C<_release($child)>. Neither counts as a change by itself, so a parent that
adds or removes several children calls C<_changed> once, afterwards.

To make several changes count as one, run them inside C<_batch>:

	$self->_batch(sub {
		$self->{first}->set(1);
		$self->{second}->set(2);
	});

Changes made inside the subroutine, including changes to children, only mark
the node as changed; subscribers and parents are notified once, when the
subroutine returns or dies.

=head1 METHODS

=head2 new

	my $node = Specman::Model::Node->new( %args );

Creates and returns a new node that has not yet been validated. C<%args> is
accepted for subclasses but ignored by the base class.

=cut

sub new($class, %args) {
	return bless {
		_dirty             => 1,
		_errors            => [],
		_errors_updated_at => 0,
		_subscribers       => {},
		_next_id           => 1,
		_parent            => undef,
	}, $class;
}

=head2 is_valid

	my $ok = $node->is_valid;

Returns whether the node is valid: whether none of its errors has the
severity C<error>. Warnings do not make a node invalid.

If the node has changed since it was last validated, or has never been
validated, it is validated now. If the resulting list of errors differs from
the cached one, or this is the first validation, the cache is replaced,
L</errors_updated_at> is updated and subscribers are notified.

Dies with C<NotImplemented> if the subclass does not implement C<_validate>.

=cut

sub is_valid($self) {
	if ($self->{_dirty}) {
		my @errors = map {
			ref $_ ? $_ : Specman::Model::Error->new(message => $_)
		} $self->_validate;
		$self->{_dirty} = 0;

		if (!$self->{_errors_updated_at} || !_same_list($self->{_errors}, \@errors)) {
			$self->{_errors} = \@errors;
			$self->{_errors_updated_at} = _next_stamp($self->{_errors_updated_at});
			for my $id (sort { $a <=> $b } keys $self->{_subscribers}->%*) {
				$self->{_subscribers}{$id}->($self, @errors);
			}
		}
	}

	return !grep { $_->is_error } $self->{_errors}->@*;
}

=head2 errors

	my @errors = $node->errors;

Returns the list of errors and warnings found by the most recent call to
L</is_valid>, as L<Specman::Model::Error> objects. Returns an empty list if
L</is_valid> has not been called yet. Never
validates the node itself.

=cut

sub errors($self) {
	return $self->{_errors}->@*;
}

=head2 errors_updated_at

	my $time = $node->errors_updated_at;

Returns the time at which the list of errors last changed, in seconds since
the epoch with microsecond precision, or C<0> if L</is_valid> has not been
called yet.

Successive values for the same node always increase, even if the system
clock is set back. Compare them for equality to detect a change.

=cut

sub errors_updated_at($self) {
	return $self->{_errors_updated_at};
}

=head2 on_errors_updated

	my $id = $node->on_errors_updated(sub ($node, @errors) { ... });

Calls the given subroutine with the node and its new list of errors each
time the list changes, and returns an identifier for the subscription. While
a node has subscribers, it revalidates as soon as it changes.

=cut

sub on_errors_updated($self, $callback) {
	my $id = $self->{_next_id}++;
	$self->{_subscribers}{$id} = $callback;
	return $id;
}

=head2 off_errors_updated

	$node->off_errors_updated($id);

Removes the subscription with the given identifier.

=cut

sub off_errors_updated($self, $id) {
	delete $self->{_subscribers}{$id};
	return;
}

sub _validate($self) {
	die 'NotImplemented';
}

sub _changed($self) {
	$self->{_dirty} = 1;
	return if $self->{_batching};
	$self->is_valid if $self->{_subscribers}->%*;
	$self->{_parent}->_changed if $self->{_parent};
	return;
}

sub _batch($self, $code) {
	$self->{_batching}++;
	my $ok = eval { $code->(); 1 };
	my $error = $@;
	$self->{_batching}--;
	$self->_changed;
	die $error unless $ok;
	return;
}

sub _adopt($self, $child) {
	$child->{_parent} = $self;
	weaken $child->{_parent};
	return $child;
}

sub _release($self, $child) {
	$child->{_parent} = undef;
	return $child;
}

sub _same_list($old, $new) {
	return 0 unless @$old == @$new;
	for my $i (0 .. $#$old) {
		return 0 unless $old->[$i]->equals($new->[$i]);
	}
	return 1;
}

sub _next_stamp($previous) {
	my $now = Time::HiRes::time();
	return $now > $previous ? $now : $previous + 1e-6;
}

1;

=head1 SEE ALSO

L<Specman::Model::Field>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.

=cut
