use v5.36;
use Test2::V0;
use Encode qw(decode);
use File::Temp qw(tempdir);
use JSON::PP;
use Preq;
use Preq::CLI;

my $dir = tempdir(CLEANUP => 1);
my %files = (
	'REQ-001.md' => "---\nid: REQ-001\ntitle: Parent\nstatus: approved\npriority: high\ncreated: 2026-10-27\ntags: [core]\n---\nThe parent.\n",
	'REQ-002.md' => "---\nid: REQ-002\ntitle: Child \xc3\xa9\nstatus: draft\ncreated: 2026-10-27\ntags: [core, gui]\nrefines: [REQ-001]\n---\n",
);
for my $name (keys %files) {
	open my $fh, '>:raw', "$dir/$name" or die $!;
	print $fh $files{$name};
	close $fh;
}

# Runs the CLI and returns its exit status, output and messages, decoded.
sub run_cli(@args) {
	open my $out, '>', \my $out_bytes or die;
	open my $err, '>', \my $err_bytes or die;
	my $status = Preq::CLI->new(out => $out, err => $err, pod => 'bin/preq')->run(@args);
	close $out;
	close $err;
	return ($status, decode('UTF-8', $out_bytes // ''), decode('UTF-8', $err_bytes // ''));
}

subtest 'list' => sub {
	my ($status, $out) = run_cli('--dir', $dir, 'list');
	is($status, 0, 'exit status 0');
	is($out, join('',
		"ID       STATUS    PRIORITY  TITLE\n",
		"REQ-001  approved  high      Parent\n",
		"REQ-002  draft               Child \x{e9}\n",
	), 'a table of requirements');

	(undef, $out) = run_cli('--dir', $dir, 'list', '--status', 'draft');
	like($out, qr/REQ-002/, '--status keeps matching requirements');
	unlike($out, qr/REQ-001/, '--status drops others');

	(undef, $out) = run_cli('--dir', $dir, 'list', '--tag', 'gui');
	unlike($out, qr/REQ-001/, '--tag filters');

	(undef, $out) = run_cli('--dir', $dir, 'list', '--json');
	my $list = decode_json(Encode::encode('UTF-8', $out));
	is([map { $_->{id} } @$list], [qw(REQ-001 REQ-002)], '--json lists requirements');
	is($list->[1]{file}, 'REQ-002.md', 'with their file');
	ok(!exists $list->[0]{body}, 'without their body');
};

subtest 'show' => sub {
	my ($status, $out) = run_cli('--dir', $dir, 'show', 'REQ-001');
	is($status, 0, 'exit status 0');
	is($out, join('',
		"id:          REQ-001\n",
		"title:       Parent\n",
		"status:      approved\n",
		"priority:    high\n",
		"created:     2026-10-27\n",
		"tags:        core\n",
		"refined by:  REQ-002\n",
		"\n",
		"The parent.\n",
	), 'fields, incoming relations and body');

	(undef, $out) = run_cli('--dir', $dir, 'show', 'REQ-002');
	like($out, qr/^refines:  REQ-001 \(Parent\)$/m, 'relations show their target title');

	(undef, $out) = run_cli('--dir', $dir, 'show', 'REQ-001', '--json');
	my $req = decode_json(Encode::encode('UTF-8', $out));
	is($req->{body}, "The parent.\n", '--json includes the body');
	is($req->{incoming}{refines}, ['REQ-002'], 'and incoming relations');

	my $err;
	($status, $out, $err) = run_cli('--dir', $dir, 'show', 'REQ-999');
	is($status, 1, 'unknown requirement: exit status 1');
	is($err, "preq: no requirement 'REQ-999'\n", 'with a message');
};

subtest 'validate' => sub {
	my ($status, $out, $err) = run_cli('--dir', $dir, 'validate');
	is($status, 0, 'valid: exit status 0');
	is($out, '', 'no errors printed');
	is($err, "preq: 2 requirements, 0 errors\n", 'summary on standard error');

	my $bad = tempdir(CLEANUP => 1);
	open my $fh, '>', "$bad/REQ-001.md" or die;
	print $fh "---\nid: REQ-001\ntitle: Bad\nstatus: done\ncreated: 2026-10-27\n---\n";
	close $fh;

	($status, $out, $err) = run_cli('--dir', $bad, 'validate');
	is($status, 1, 'invalid: exit status 1');
	like($out, qr/^REQ-001\.md: status: 'done' is not one of/, 'errors printed');
	is($err, "preq: 1 requirement, 1 error\n", 'summary uses singular forms');

	($status, $out) = run_cli('--dir', $bad, 'validate', '--json');
	my $result = decode_json($out);
	ok(!$result->{valid}, '--json reports validity');
	is($result->{errors}, [{
		file     => 'REQ-001.md',
		id       => 'REQ-001',
		field    => 'status',
		severity => 'error',
		message  => "'done' is not one of draft, approved, implemented, obsolete",
		text     => "REQ-001.md: status: 'done' is not one of draft, approved, implemented, obsolete",
	}], 'and the errors, with their location');

	{
		no warnings 'redefine';
		local *Preq::Repository::_check_cycles = sub ($self) {
			return Preq::Model::Error->new(id => 'REQ-001', message => 'looks odd', severity => 'warning');
		};
		($status, $out, $err) = run_cli('--dir', $dir, 'validate');
	}
	is($status, 0, 'warnings only: exit status 0');
	is($out, "warning: REQ-001: looks odd\n", 'warnings are marked');
	is($err, "preq: 2 requirements, 0 errors, 1 warning\n", 'and counted');
};

subtest 'usage' => sub {
	my ($status, $out, $err) = run_cli('--version');
	is([$status, $out], [0, "preq $Preq::VERSION\n"], '--version');

	($status, $out) = run_cli('--help');
	is($status, 0, '--help: exit status 0');
	like($out, qr/Commands:.*Options:/s, '--help prints the commands and options');

	($status, $out, $err) = run_cli();
	is($status, 2, 'no command: exit status 2');
	like($err, qr/^Usage:/, 'usage printed');

	($status, $out, $err) = run_cli('--dir', $dir, 'bogus');
	is([$status, $err], [2, "preq: unknown command 'bogus'\n"], 'unknown command');

	($status, $out, $err) = run_cli('--bogus');
	is($status, 2, 'unknown option: exit status 2');
	like($err, qr/^preq: unknown option: bogus\n/, 'reported on the error handle');

	($status, $out, $err) = run_cli('--dir', "$dir/nope", 'list');
	is([$status, $err], [2, "preq: no requirements directory '$dir/nope'\n"], 'missing directory');

	($status) = run_cli('--dir', $dir, 'show');
	is($status, 2, 'show without an id');
};

subtest 'script' => sub {
	my $out = `$^X -Ilib bin/preq --version`;
	is([$? >> 8, $out], [0, "preq $Preq::VERSION\n"], 'bin/preq runs');
};

done_testing;
