use v5.36;
use Test2::V0;
use Specman::Model::Field::Date;

sub errors_for($value) {
	my $field = Specman::Model::Field::Date->new;
	$field->set($value);
	$field->is_valid;
	return [$field->errors];
}

is(errors_for(undef), [], 'no value is valid');
is(errors_for('2026-10-27'), [], 'a date is valid');
is(errors_for('2024-02-29'), [], 'leap day in a leap year is valid');
is(errors_for('2000-02-29'), [], 'leap day in a 400-year is valid');
is(errors_for('2026-02-29'), ["'2026-02-29' is not a valid date"], 'leap day in a common year is invalid');
is(errors_for('1900-02-29'), ["'1900-02-29' is not a valid date"], 'leap day in a 100-year is invalid');
is(errors_for('2026-13-01'), ["'2026-13-01' is not a valid date"], 'month 13 is invalid');
is(errors_for('2026-04-31'), ["'2026-04-31' is not a valid date"], 'day 31 of April is invalid');
is(errors_for('2026-10-00'), ["'2026-10-00' is not a valid date"], 'day 0 is invalid');
is(errors_for('27/10/2026'), ["'27/10/2026' is not a date (YYYY-MM-DD)"], 'other formats are invalid');

done_testing;
