use v5.36;
use Test2::V0;
use Preq::Model::Field::Id;

sub errors_for($value) {
	my $field = Preq::Model::Field::Id->new;
	$field->set($value);
	$field->is_valid;
	return [$field->errors];
}

is(errors_for(undef), [], 'no value is valid');
is(errors_for('REQ-001'), [], 'REQ-001 is valid');
is(errors_for('REQ-1234'), [], 'more than three digits is valid');
like(errors_for('REQ-01'), [qr/^'REQ-01' is not a requirement ID/], 'fewer than three digits is invalid');
like(errors_for('req-001'), [qr/is not a requirement ID/], 'lowercase prefix is invalid');
like(errors_for("REQ-\x{661}\x{662}\x{663}"), [qr/is not a requirement ID/], 'non-ASCII digits are invalid');
is(errors_for(''), ['is empty'], 'text rules are checked first');

done_testing;
