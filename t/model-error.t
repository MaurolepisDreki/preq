use v5.36;
use Test2::V0;
use Preq::Model::Error;

my $class = 'Preq::Model::Error';

like(dies { $class->new }, qr/^message is required/, 'message is required');
like(dies { $class->new(message => 'x', severity => 'fatal') }, qr/^unknown severity 'fatal'/, 'severity is checked');
like(dies { $class->new(message => 'x', colour => 'red') }, qr/^unknown argument 'colour'/, 'arguments are checked');

subtest 'defaults' => sub {
	my $error = $class->new(message => 'is empty');
	is($error->message, 'is empty', 'message');
	is($error->severity, 'error', 'severity defaults to error');
	ok($error->is_error, 'is_error');
	is($error->location, {}, 'no location');
	is("$error", 'is empty', 'as a string: just the message');
};

subtest 'location' => sub {
	my $error = $class->new(message => 'is empty', item => 2);
	my $outer = $error->within(field => 'tags')->within(file => 'REQ-002.md', id => 'REQ-002');

	is($error->location, { item => 2 }, 'within returns a copy');
	is($outer->location, { file => 'REQ-002.md', id => 'REQ-002', field => 'tags', item => 2 }, 'location parts are added');
	is([$outer->file, $outer->id, $outer->field, $outer->item], ['REQ-002.md', 'REQ-002', 'tags', 2], 'accessors');
	is("$outer", 'REQ-002.md: tags: item 2: is empty', 'as a string: the file is shown rather than the id');
	is("" . $error->within(id => 'REQ-009', field => 'tags'), 'REQ-009: tags: item 2: is empty', 'the id is shown without a file');

	is($outer->within(field => 'other')->field, 'tags', 'existing parts are kept');
	is($error->within(file => undef)->location, { item => 2 }, 'undef parts are ignored');
	like(dies { $error->within(colour => 'red') }, qr/^unknown location part 'colour'/, 'only location parts');
};

subtest 'warnings' => sub {
	my $warning = $class->new(message => 'has no priority', severity => 'warning');
	ok(!$warning->is_error, 'a warning is not an error');
	is($warning->within(field => 'priority')->severity, 'warning', 'severity is kept by within');
};

subtest 'equality' => sub {
	my $error = $class->new(message => 'is empty', field => 'title');
	ok($error->equals($class->new(message => 'is empty', field => 'title')), 'same content');
	ok(!$error->equals($class->new(message => 'is empty', field => 'author')), 'different location');
	ok(!$error->equals($class->new(message => 'is empty')), 'missing location part');
	ok(!$error->equals($class->new(message => 'is empty', field => 'title', severity => 'warning')), 'different severity');
};

is($class->new(message => 'is empty', field => 'title')->TO_JSON,
	{ field => 'title', message => 'is empty', severity => 'error', text => 'title: is empty' },
	'TO_JSON');

done_testing;
