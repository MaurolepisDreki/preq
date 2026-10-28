use v5.36;
use Test::More;

use_ok('Specman');
use_ok('Specman::Model::Error');
use_ok('Specman::Model::Node');
use_ok('Specman::Model::Field');
use_ok('Specman::Model::Field::Text');
use_ok('Specman::Model::Field::Id');
use_ok('Specman::Model::Field::Enum');
use_ok('Specman::Model::Field::Date');
use_ok('Specman::Model::Field::Markdown');
use_ok('Specman::Model::Field::Relation');
use_ok('Specman::Model::Field::List');
use_ok('Specman::Model::Record');
use_ok('Specman::Model::Record::Requirement');
use_ok('Specman::Repository');
use_ok('Specman::CLI');

done_testing;
