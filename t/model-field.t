use v5.36;
use Test2::V0;
use Specman::Model::Field;

isa_ok(Specman::Model::Field->new, 'Specman::Model::Field');

like(dies { Specman::Model::Field->new->is_valid }, qr/^NotImplemented/, 'is_valid dies with NotImplemented');
like(dies { Specman::Model::Field->new->get }, qr/^NotImplemented/, 'get dies with NotImplemented');
like(dies { Specman::Model::Field->new->set(0) }, qr/^NotImplemented/, 'set dies with NotImplemented');

done_testing;
