use v5.36;
use Test2::V0;
use Preq::Model::Field;

isa_ok(Preq::Model::Field->new, 'Preq::Model::Field');

like(dies { Preq::Model::Field->new->is_valid }, qr/^NotImplemented/, 'is_valid dies with NotImplemented');
like(dies { Preq::Model::Field->new->get }, qr/^NotImplemented/, 'get dies with NotImplemented');
like(dies { Preq::Model::Field->new->set(0) }, qr/^NotImplemented/, 'set dies with NotImplemented');

done_testing;
