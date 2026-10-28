use v5.36;
use Test2::V0;
use Specman::Model::Record;

package Test::Record {
	use parent -norequire, 'Specman::Model::Record';

	sub _fields($class) {
		return (
			id    => { class => 'Specman::Model::Field::Id', required => 1 },
			title => { class => 'Specman::Model::Field::Text' },
			tags  => { class => 'Specman::Model::Field::List', args => { of => 'Specman::Model::Field::Text' }, required => 1 },
		);
	}
}

like(dies { Specman::Model::Record->new }, qr/^NotImplemented/, 'abstract record dies with NotImplemented');

subtest 'fields' => sub {
	my $record = Test::Record->new;
	is([$record->field_names], [qw(id title tags)], 'field_names in order');
	isa_ok($record->field('id'), 'Specman::Model::Field::Id');
	like(dies { $record->field('colour') }, qr/^no field named 'colour'/, 'unknown field dies');
	ok($record->is_required('id'), 'id is required');
	ok(!$record->is_required('title'), 'title is optional');
};

subtest 'required fields' => sub {
	my $record = Test::Record->new;
	ok(!$record->is_valid, 'a new record is invalid');
	is([$record->errors], ['id: is required', 'tags: is required'], 'required fields are reported');
};

subtest 'values' => sub {
	my $record = Test::Record->new;
	$record->set_values({ id => 'REQ-001', title => 'A title', tags => ['a'] });
	ok($record->is_valid, 'valid');
	is($record->get_values, { id => 'REQ-001', title => 'A title', tags => ['a'] }, 'get_values');

	$record->set_values({ id => 'REQ-002' });
	is($record->get_values, { id => 'REQ-002', title => undef, tags => [] }, 'unnamed fields are emptied');

	like(dies { $record->set_values([]) }, qr/^set_values expects a hash reference/, 'set_values needs a hash reference');
};

subtest 'field errors' => sub {
	my $record = Test::Record->new;
	$record->set_values({ id => 'REQ-1', title => '', tags => 'storage', colour => 'red' });
	$record->is_valid;
	is([map { "$_" } $record->errors], [
		match(qr/^id: 'REQ-1' is not a requirement ID/),
		'title: is empty',
		'tags: is not a list',
		'colour: is not a known field',
	], 'field errors are prefixed with the field name');

	$record->set_values({ id => 'REQ-001', tags => ['a'] });
	ok($record->is_valid, 'setting the values again clears unknown fields');
};

subtest 'changes' => sub {
	my $record = Test::Record->new;
	my @seen;
	$record->on_errors_updated(sub ($r, @errors) { push @seen, [@errors] });

	$record->set_values({ id => 'REQ-001', title => 'A title', tags => ['a'] });
	is(scalar @seen, 1, 'set_values notifies once');

	$record->field('title')->set('');
	is($seen[-1], ['title: is empty'], 'a change to a field is a change to the record');

	my ($tag) = $record->field('tags')->elements;
	$tag->set('');
	is($seen[-1], ['title: is empty', 'tags: item 1: is empty'], 'changes to list elements reach the record');
};

done_testing;
