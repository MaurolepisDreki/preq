use v5.36;
use Test2::V0;
use Specman::Model::Field::Relation;

my $class = 'Specman::Model::Field::Relation';

is([$class->types], [qw(conflicts_with depends_on refines)], 'types lists the relation types');
like(dies { $class->new }, qr/^unknown relation type ''/, 'type is required');
like(dies { $class->new(type => 'blocks') }, qr/^unknown relation type 'blocks'/, 'unknown types die');

my $refines = $class->new(type => 'refines');
is($refines->type, 'refines', 'type returns the type');
ok($refines->is_acyclic, 'refines is acyclic');
ok(!$refines->is_symmetric, 'refines is not symmetric');

my $conflicts = $class->new(type => 'conflicts_with');
ok($conflicts->is_symmetric, 'conflicts_with is symmetric');
ok(!$conflicts->is_acyclic, 'conflicts_with is not acyclic');

$refines->is_valid;
is([$refines->errors], ['has no target'], 'a relation without a target is invalid');

$refines->set('REQ-001');
ok($refines->is_valid, 'a relation to a well-formed ID is valid');
is($refines->get, 'REQ-001', 'get returns the target');

$refines->set('REQ-1');
$refines->is_valid;
like([$refines->errors], [qr/is not a requirement ID/], 'the target must be a well-formed ID');

done_testing;
