use v5.36;
use Test2::V0;
use Preq::Model::Node;

# A minimal concrete node: its errors are whatever was last set.
package Test::Node {
	use parent -norequire, 'Preq::Model::Node';

	sub set($self, @errors) {
		$self->{value} = \@errors;
		$self->_changed;
	}

	sub _validate($self) {
		$self->{calls}++;
		return ($self->{value} // [])->@*;
	}
}

# A parent whose errors are its own plus its child's.
package Test::Parent {
	use parent -norequire, 'Preq::Model::Node';

	sub _validate($self) {
		my $child = $self->{child};
		$child->is_valid;
		return map { "child: $_" } $child->errors;
	}
}

like(dies { Preq::Model::Node->new->is_valid }, qr/^NotImplemented/, 'abstract node dies with NotImplemented');

subtest 'before validation' => sub {
	my $node = Test::Node->new;
	is([$node->errors], [], 'errors is empty');
	is($node->errors_updated_at, 0, 'errors_updated_at is 0');
	is($node->{calls}, undef, 'nothing validated yet');
};

subtest 'first validation' => sub {
	my $node = Test::Node->new;
	ok($node->is_valid, 'valid with no errors');
	ok($node->errors_updated_at > 0, 'errors_updated_at is set even with no errors');
	is([$node->errors], [], 'errors is empty');
};

subtest 'caching' => sub {
	my $node = Test::Node->new;
	$node->set('bad');
	ok(!$node->is_valid, 'invalid');
	is([$node->errors], ['bad'], 'errors are reported');
	$node->is_valid;
	$node->errors;
	is($node->{calls}, 1, 'validated only once');
};

subtest 'errors does not revalidate' => sub {
	my $node = Test::Node->new;
	$node->set('old');
	$node->is_valid;
	$node->set('new');
	is([$node->errors], ['old'], 'errors returns the previous list after a change');
	$node->is_valid;
	is([$node->errors], ['new'], 'is_valid rebuilds the list');
};

subtest 'errors_updated_at' => sub {
	my $node = Test::Node->new;
	$node->set('bad');
	$node->is_valid;
	my $first = $node->errors_updated_at;

	$node->set('bad');
	$node->is_valid;
	is($node->errors_updated_at, $first, 'unchanged when the list is unchanged');

	{
		no warnings 'redefine';
		local *Time::HiRes::time = sub { 1 };
		$node->set('worse');
		$node->is_valid;
	}
	ok($node->errors_updated_at > $first, 'increases even if the clock goes back');
};

subtest 'subscribers' => sub {
	my $node = Test::Node->new;
	my @seen;
	my $id = $node->on_errors_updated(sub ($n, @errors) { push @seen, [@errors] });

	$node->set('bad');
	is(\@seen, [['bad']], 'notified immediately on change');

	$node->set('bad');
	is(scalar @seen, 1, 'not notified when the list is unchanged');

	$node->off_errors_updated($id);
	$node->set();
	is(scalar @seen, 1, 'not notified after unsubscribing');
	is([$node->errors], ['bad'], 'without subscribers, revalidation waits for is_valid');
};

subtest 'error objects' => sub {
	my $node = Test::Node->new;
	$node->set('plain');
	$node->is_valid;
	my ($error) = $node->errors;
	isa_ok($error, 'Preq::Model::Error');
	is($error->message, 'plain', 'plain strings become errors');

	my $warning = Preq::Model::Error->new(message => 'look', severity => 'warning');
	$node->set($warning);
	ok($node->is_valid, 'warnings alone do not make a node invalid');
	is([$node->errors], [$warning], 'but are reported');

	my $stamp = $node->errors_updated_at;
	$node->set(Preq::Model::Error->new(message => 'look'));
	ok(!$node->is_valid, 'the same message as an error makes it invalid');
	ok($node->errors_updated_at != $stamp, 'a change of severity is a change of the list');
};

subtest 'batches' => sub {
	my $parent = Test::Parent->new;
	my $child = $parent->{child} = $parent->_adopt(Test::Node->new);
	my @seen;
	$parent->on_errors_updated(sub ($n, @errors) { push @seen, [@errors] });

	$parent->_batch(sub {
		$child->set('one');
		$child->set('two');
		is(\@seen, [], 'no notification inside a batch');
	});
	is(\@seen, [['child: two']], 'one notification after the batch');

	like(dies { $parent->_batch(sub { $child->set('three'); die "oops\n" }) }, qr/^oops/, 'errors in a batch are rethrown');
	is($seen[-1], ['child: three'], 'changes are still notified');
};

subtest 'parents' => sub {
	my $parent = Test::Parent->new;
	my $child = $parent->{child} = $parent->_adopt(Test::Node->new);
	ok($parent->is_valid, 'parent valid');

	my @seen;
	$parent->on_errors_updated(sub ($n, @errors) { push @seen, [@errors] });
	$child->set('bad');
	is(\@seen, [['child: bad']], 'child change notifies parent subscribers');

	undef $parent;
	is($child->{_parent}, undef, 'child does not keep its parent alive');
};

done_testing;
