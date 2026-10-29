use v5.36;
use Test2::V0;
use File::Copy qw(copy);
use File::Temp qw(tempdir);
use Preq::Repository;

sub write_file($path, $content) {
	open my $fh, '>:raw', $path or die "$path: $!";
	print $fh $content;
	close $fh;
}

sub read_file($path) {
	open my $fh, '<:raw', $path or die "$path: $!";
	local $/;
	return <$fh>;
}

# A directory holding the given files, named => content.
sub repo_with(%files) {
	my $dir = tempdir(CLEANUP => 1);
	write_file("$dir/$_", $files{$_}) for keys %files;
	return Preq::Repository->new(dir => $dir)->load;
}

sub req($id, %values) {
	%values = (id => $id, title => "Title of $id", status => 'draft', created => '2026-10-27', %values);
	return join('', '---', map({ "\n$_: $values{$_}" } sort keys %values), "\n---\n");
}

sub errors_of($repo) {
	$repo->is_valid;
	return [map { "$_" } $repo->errors];
}

like(dies { Preq::Repository->new }, qr/^dir is required/, 'dir is required');
like(dies { Preq::Repository->new(dir => '/nonexistent')->load }, qr/^cannot read/, 'load dies without a directory');

subtest 'project requirements' => sub {
	my $repo = Preq::Repository->new(dir => 'requirements')->load;
	ok(scalar(my @r = $repo->records) > 0, 'requirements found');
	is(errors_of($repo), [], 'the project requirements are valid');

	my $dir = tempdir(CLEANUP => 1);
	copy("requirements/$_", "$dir/$_") for map { "$_.md" } map { $_->id } $repo->records;
	my $copy = Preq::Repository->new(dir => $dir)->load;
	for my $record ($copy->records) {
		my $name = $record->id . '.md';
		$copy->save($record);
		is(read_file("$dir/$name"), read_file("requirements/$name"), "$name is saved unchanged");
	}
};

subtest 'lookup' => sub {
	my $repo = repo_with(
		'REQ-001.md' => req('REQ-001'),
		'REQ-002.md' => req('REQ-002', refines => '[REQ-001]'),
		'REQ-010.md' => req('REQ-010', depends_on => '[REQ-001]'),
	);
	is([map { $_->id } $repo->records], [qw(REQ-001 REQ-002 REQ-010)], 'records in file order');
	is($repo->record('REQ-002')->id, 'REQ-002', 'record by id');
	is($repo->record('REQ-999'), undef, 'no such record');
	is([map { $_->id } $repo->incoming('REQ-001')], [qw(REQ-002 REQ-010)], 'incoming');
	is([map { $_->id } $repo->incoming('REQ-001', 'refines')], ['REQ-002'], 'incoming by type');
	is($repo->next_id, 'REQ-011', 'next_id');
	is(Preq::Repository->new(dir => '.')->next_id, 'REQ-001', 'next_id when empty');
};

subtest 'file errors' => sub {
	my $repo = repo_with(
		'a.md' => "No header here.\n",
		'b.md' => "---\ntitle: [unclosed\n---\n",
		'c.md' => "---\n- a list\n---\n",
		'd.md' => "---\r\nid: REQ-001\r\n---\r\n",
		'e.md' => "---\nid: REQ-001\n---\n\xff\n",
		'f.md' => "---\nid: REQ-001\nbody: x\n---\n",
		'notes.txt' => 'ignored',
	);
	is([$repo->records], [], 'no records loaded');
	is(errors_of($repo), [
		'a.md: has no header (a block between two --- lines)',
		match(qr/^b\.md: header is not valid YAML: /),
		'c.md: header is not a mapping',
		'd.md: must use LF line endings, not CRLF',
		'e.md: is not valid UTF-8',
		'f.md: header must not contain body',
	], 'files that are not requirements');
};

subtest 'collection errors' => sub {
	my $repo = repo_with(
		'REQ-001.md' => req('REQ-001', refines => '[REQ-003]'),
		'REQ-002.md' => req('REQ-002', refines => '[REQ-001, REQ-999]'),
		'REQ-003.md' => req('REQ-003', refines => '[REQ-002]', depends_on => '[REQ-003]'),
		'REQ-004.md' => req('REQ-002', status => 'done'),
		'REQ-005.md' => req('REQ-005', conflicts_with => '[REQ-006]'),
		'REQ-006.md' => req('REQ-006', conflicts_with => '[REQ-005]'),
	);
	is(errors_of($repo), [
		"REQ-003.md: depends_on: item 1: 'REQ-003' refers to itself",
		"REQ-004.md: status: 'done' is not one of draft, approved, implemented, obsolete",
		"REQ-004.md: file name does not match id 'REQ-002'",
		'REQ-002: is used by more than one requirement (REQ-002.md, REQ-004.md)',
		"REQ-002.md: refines: item 2: 'REQ-999' does not exist",
		'refines: cycle REQ-001 -> REQ-003 -> REQ-002 -> REQ-001',
	], 'errors across requirements; symmetric links in both directions are not cycles');
};

subtest 'changes' => sub {
	my $repo = repo_with('REQ-001.md' => req('REQ-001'), 'REQ-002.md' => req('REQ-002'));
	my @seen;
	$repo->on_errors_updated(sub ($r, @errors) { push @seen, [@errors] });

	$repo->record('REQ-002')->field('refines')->set(['REQ-002']);
	is($seen[-1], ["REQ-002.md: refines: item 1: 'REQ-002' refers to itself"], 'a change to a requirement reaches the repository');

	my $new = Preq::Model::Record::Requirement->new;
	$new->set_values({ id => 'REQ-003', title => 'New', status => 'draft', created => '2026-10-27', refines => ['REQ-404'] });
	$repo->add($new);
	is($seen[-1][-1], "REQ-003: refines: item 1: 'REQ-404' does not exist", 'unsaved requirements are located by id');
};

subtest 'save' => sub {
	my $repo = repo_with('REQ-001.md' => req('REQ-001'), 'REQ-002.md' => req('REQ-002'));
	my $dir = $repo->dir;

	my $new = Preq::Model::Record::Requirement->new;
	$new->set_values({
		id      => $repo->next_id,
		title   => 'Search: by tag, then by text',
		status  => 'draft',
		author  => 'true',
		created => '2026-10-27',
		tags    => ['search', 'a, b', 'café'],
		body    => "Line one.\n",
	});
	$repo->add($new);
	is($repo->save($new), 'REQ-003.md', 'save returns the file name');
	is(read_file("$dir/REQ-003.md"), join('',
		"---\n",
		"id: REQ-003\n",
		"title: \"Search: by tag, then by text\"\n",
		"status: draft\n",
		"author: \"true\"\n",
		"created: 2026-10-27\n",
		"tags: [search, \"a, b\", caf\xc3\xa9]\n",
		"---\n",
		"Line one.\n",
	), 'written in order, quoted only where needed, as UTF-8');

	my $reloaded = Preq::Repository->new(dir => $dir)->load->record('REQ-003');
	is($reloaded->get_values, $new->get_values, 'reads back the same values');

	$new->field('id')->set('REQ-004');
	$repo->save($new);
	ok(!-e "$dir/REQ-003.md" && -e "$dir/REQ-004.md", 'changing the id renames the file');

	$new->field('id')->set('REQ-001');
	like(dies { $repo->save($new) }, qr/^cannot save: REQ-001\.md already exists/, 'another file is never overwritten');

	$new->field('id')->set('REQ-1');
	like(dies { $repo->save($new) }, qr/^cannot save: the requirement has no valid id/, 'an invalid id cannot be saved');

	$new->field('id')->set('REQ-004');
	$new->field('tags')->set('search');
	like(dies { $repo->save($new) }, qr/^cannot save: tags: is not a list/, 'a non-list cannot be saved');

	$new->field('tags')->set([]);
	$new->field('title')->set({});
	like(dies { $repo->save($new) }, qr/^cannot save: title: is not text/, 'a non-text value cannot be saved');

	like(dies { $repo->save(Preq::Model::Record::Requirement->new) }, qr/^not a requirement in this repository/, 'only its own requirements');
};

done_testing;
