use v5.36;
use Test2::V0;
use Preq::Model::Field::Text;

sub errors_for($value) {
	my $field = Preq::Model::Field::Text->new;
	$field->set($value);
	$field->is_valid;
	return [$field->errors];
}

is(errors_for(undef), [], 'no value is valid');
is(errors_for('A title'), [], 'a line of text is valid');
is(errors_for(''), ['is empty'], 'empty text is invalid');
is(errors_for("two\nlines"), ['contains a line break'], 'a line break is invalid');
is(errors_for([]), ['is not text'], 'a reference is invalid');

my $field = Preq::Model::Field::Text->new;
$field->set('A title');
is($field->get, 'A title', 'get returns the value');

my $changes = 0;
$field->on_errors_updated(sub { $changes++ });
$field->set('');
$field->set('');
is($changes, 1, 'setting the same value again is not a change');

done_testing;
