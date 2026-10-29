use v5.36;
use Test2::V0;
use Preq::Model::Field::Markdown;

my $field = Preq::Model::Field::Markdown->new;
ok($field->is_valid, 'no value is valid');

$field->set("# Heading\n\nTwo\nlines.\n");
ok($field->is_valid, 'multi-line text is valid');
is($field->get, "# Heading\n\nTwo\nlines.\n", 'get returns the value');

$field->set('');
ok($field->is_valid, 'empty text is valid');

$field->set({});
$field->is_valid;
is([$field->errors], ['is not text'], 'a reference is invalid');

done_testing;
