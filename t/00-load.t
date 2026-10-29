use v5.36;
use Test::More;

use_ok('Preq');
use_ok('Preq::Model::Error');
use_ok('Preq::Model::Node');
use_ok('Preq::Model::Field');
use_ok('Preq::Model::Field::Text');
use_ok('Preq::Model::Field::Id');
use_ok('Preq::Model::Field::Enum');
use_ok('Preq::Model::Field::Date');
use_ok('Preq::Model::Field::Markdown');
use_ok('Preq::Model::Field::Relation');
use_ok('Preq::Model::Field::List');
use_ok('Preq::Model::Record');
use_ok('Preq::Model::Record::Requirement');
use_ok('Preq::Repository');
use_ok('Preq::CLI');

done_testing;
