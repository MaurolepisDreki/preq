use v5.36;
use Test2::V0;
use Preq::Model::Record::Requirement;

sub requirement(%values) {
	my $req = Preq::Model::Record::Requirement->new;
	$req->set_values({
		id      => 'REQ-002',
		title   => 'Store requirements as text files',
		status  => 'approved',
		created => '2026-10-27',
		body    => "Each requirement shall be stored as one text file.\n",
		%values,
	});
	return $req;
}

sub errors_for(%values) {
	my $req = requirement(%values);
	$req->is_valid;
	return [$req->errors];
}

is([Preq::Model::Record::Requirement->new->field_names],
	[qw(id title status priority author created tags refines depends_on conflicts_with body)],
	'fields in the order of Preq::Manual::Format');

is(errors_for(), [], 'a complete requirement is valid');

my $req = requirement(refines => ['REQ-001'], depends_on => ['REQ-003', 'REQ-004']);
is($req->id, 'REQ-002', 'id');
is([map { [$_->type, $_->get] } $req->relations],
	[[refines => 'REQ-001'], [depends_on => 'REQ-003'], [depends_on => 'REQ-004']],
	'relations');

is(errors_for(status => 'done'), ["status: 'done' is not one of draft, approved, implemented, obsolete"], 'status values');
is(errors_for(priority => 'urgent'), ["priority: 'urgent' is not one of low, medium, high"], 'priority values');
is(errors_for(created => '2026-02-30'), ["created: '2026-02-30' is not a valid date"], 'created is a date');
like(errors_for(refines => ['REQ-1']), [qr/^refines: item 1: 'REQ-1' is not a requirement ID/], 'relation targets are IDs');
is(errors_for(tags => ['a', 'a']), ["tags: 'a' is listed more than once"], 'tags are unique');
is(errors_for(conflicts_with => ['REQ-002']), ["conflicts_with: item 1: 'REQ-002' refers to itself"], 'no relation to itself');
is(errors_for(title => undef), ['title: is required'], 'title is required');
is(errors_for(colour => 'red'), ['colour: is not a known field'], 'unknown fields');

is(errors_for(body => undef), ['body: is required unless status is draft'], 'body is required');
is(errors_for(body => " \n"), ['body: is required unless status is draft'], 'whitespace is not a body');
is(errors_for(body => undef, status => 'draft'), [], 'a draft may have no body');
is(errors_for(body => undef, status => undef), ['status: is required'], 'no body rule without a status');
is(errors_for(body => undef, status => 'done'), ["status: 'done' is not one of draft, approved, implemented, obsolete"], 'no body rule with an invalid status');

done_testing;
