use v5.36;
use Test2::V0;
use Specman::Model::Field::Enum;

like(dies { Specman::Model::Field::Enum->new }, qr/^allowed must be/, 'allowed is required');
like(dies { Specman::Model::Field::Enum->new(allowed => []) }, qr/^allowed must be/, 'allowed must not be empty');

my $field = Specman::Model::Field::Enum->new(allowed => [qw(low medium high)]);
is([$field->allowed], [qw(low medium high)], 'allowed returns the values in order');

$field->set('medium');
ok($field->is_valid, 'an allowed value is valid');

$field->set('urgent');
$field->is_valid;
is([$field->errors], ["'urgent' is not one of low, medium, high"], 'other values are invalid');

$field->set('');
$field->is_valid;
is([$field->errors], ['is empty'], 'text rules are checked first');

done_testing;
