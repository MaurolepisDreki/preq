use v5.36;
use Test2::V0;
use Specman::Model::Field::List;

my $class = 'Specman::Model::Field::List';

like(dies { $class->new }, qr/^of must name a field class/, 'of is required');
like(dies { $class->new(of => 'Specman::Model::Node') }, qr/is not a Specman::Model::Field/, 'of must be a field class');

subtest 'values' => sub {
	my $tags = $class->new(of => 'Specman::Model::Field::Text');
	is($tags->get, [], 'a new list is empty');
	ok($tags->is_valid, 'an empty list is valid');

	$tags->set([qw(storage model)]);
	is($tags->get, [qw(storage model)], 'set and get');
	is(scalar(my @e = $tags->elements), 2, 'one element per value');

	$tags->set('storage');
	ok(!$tags->is_valid, 'a value that is not a list is invalid');
	is([$tags->errors], ['is not a list'], 'and is reported');
	ok(!$tags->is_empty, 'and is not empty');
	is($tags->get, [], 'get returns no values');

	$tags->set(undef);
	ok($tags->is_valid && $tags->is_empty, 'undef empties the list');

	$tags->set([qw(storage model)]);

	my $element = $tags->add('gui');
	isa_ok($element, 'Specman::Model::Field::Text');
	is($tags->get, [qw(storage model gui)], 'add appends');

	is($tags->remove(0)->get, 'storage', 'remove returns the element');
	is($tags->get, [qw(model gui)], 'remove removes');
	is($tags->remove(5), undef, 'removing past the end returns nothing');
};

subtest 'validation' => sub {
	my $tags = $class->new(of => 'Specman::Model::Field::Text');
	$tags->set(['storage', '', 'storage', 'storage']);
	$tags->is_valid;
	is([$tags->errors], ['item 2: is empty', "'storage' is listed more than once"], 'element errors and duplicates');
};

subtest 'relations' => sub {
	my $refines = $class->new(of => 'Specman::Model::Field::Relation', args => { type => 'refines' });
	my $link = $refines->add('REQ-001');
	is($link->type, 'refines', 'args are passed to the elements');
	ok($refines->is_valid, 'valid');

	$link->set('REQ-1');
	ok(!$refines->is_valid, 'a change to an element is a change to the list');
	like([$refines->errors], [qr/^item 1: 'REQ-1' is not a requirement ID/], 'element errors are reported');
};

subtest 'released elements' => sub {
	my $tags = $class->new(of => 'Specman::Model::Field::Text');
	$tags->set(['storage']);
	my ($old) = $tags->elements;
	$tags->set(['model']);
	ok($tags->is_valid, 'valid');

	my $changes = 0;
	$tags->on_errors_updated(sub { $changes++ });
	$old->set('');
	is($changes, 0, 'a replaced element no longer affects the list');
};

done_testing;
