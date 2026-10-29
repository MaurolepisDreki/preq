package Preq::CLI 0.001;

use v5.36;

use Getopt::Long qw(GetOptionsFromArray);
use JSON::PP;
use Pod::Usage qw(pod2usage);

use Preq;
use Preq::Model::Field::Relation;
use Preq::Repository;

=head1 NAME

Preq::CLI - The preq command-line interface

=head1 SYNOPSIS

	use Preq::CLI;

	exit Preq::CLI->new(pod => __FILE__)->run(@ARGV);

=head1 DESCRIPTION

Implements the commands of L<preq>. The user documentation, including the
commands, options and exit codes, is in L<preq>.

=head1 METHODS

=head2 new

	my $cli = Preq::CLI->new(
		out => $fh,
		err => $fh,
		pod => $path,
	);

Creates and returns a new command-line interface. C<out> and C<err> are the
handles for output and messages, by default C<STDOUT> and C<STDERR>; text
written to them is encoded as UTF-8. C<pod> is the path of the file whose POD
provides the usage and help text.

=cut

sub new($class, %args) {
	my $self = bless {
		out => $args{out} // \*STDOUT,
		err => $args{err} // \*STDERR,
		pod => $args{pod},
	}, $class;
	binmode $self->{$_}, ':raw:encoding(UTF-8)' for qw(out err);
	return $self;
}

=head2 run

	my $status = $cli->run(@args);

Runs the command given by the command-line arguments, and returns the exit
status.

=cut

my %COMMANDS = (
	list     => \&_list,
	show     => \&_show,
	validate => \&_validate_command,
);

sub run($self, @args) {
	my %opt = (dir => 'requirements');
	my $config = Getopt::Long::Configure(qw(no_ignore_case));
	my $parsed = do {
		local $SIG{__WARN__} = sub ($warning) { chomp $warning; $self->_message(lcfirst $warning) };
		GetOptionsFromArray(\@args, \%opt,
			'dir|d=s', 'json', 'status=s', 'tag=s', 'help|h', 'version|V');
	};
	Getopt::Long::Configure($config);

	return $self->_usage(2) unless $parsed;
	return $self->_usage(0, 99) if $opt{help};
	if ($opt{version}) {
		$self->_say("preq $Preq::VERSION");
		return 0;
	}

	my $name = shift @args // return $self->_usage(2);
	my $command = $COMMANDS{$name} // return $self->_error(2, "unknown command '$name'");

	return $self->_error(2, "no requirements directory '$opt{dir}'") unless -d $opt{dir};
	my $repo = Preq::Repository->new(dir => $opt{dir})->load;

	return $self->$command($repo, \%opt, @args);
}

sub _list($self, $repo, $opt, @args) {
	return $self->_usage(2) if @args;

	my @records = $repo->records;
	@records = grep { ($_->field('status')->get // '') eq $opt->{status} } @records
		if defined $opt->{status};
	@records = grep { my $r = $_; grep { $_ eq $opt->{tag} } grep { defined } $r->field('tags')->get->@* } @records
		if defined $opt->{tag};

	if ($opt->{json}) {
		$self->_json([ map { $self->_values($repo, $_, 0) } @records ]);
		return 0;
	}

	my @rows = (
		[qw(ID STATUS PRIORITY TITLE)],
		map {
			my $record = $_;
			[ map { $_ // '' } $record->id, map { $record->field($_)->get } qw(status priority title) ]
		} @records,
	);
	$self->_table(@rows);
	return 0;
}

sub _show($self, $repo, $opt, @args) {
	return $self->_usage(2) unless @args == 1;

	my ($id) = @args;
	my $record = $repo->record($id) // return $self->_error(1, "no requirement '$id'");

	if ($opt->{json}) {
		$self->_json($self->_values($repo, $record, 1));
		return 0;
	}

	my $values = $record->get_values;
	my @rows;
	for my $name (grep { $_ ne 'body' } $record->field_names) {
		my $value = $values->{$name};
		next if !defined $value || (ref $value eq 'ARRAY' && !@$value);
		push @rows, [ "$name:", ref $value eq 'ARRAY' ? $self->_list_value($repo, $name, $value) : $value ];
	}
	for my $type (Preq::Model::Field::Relation->types) {
		my @from = map { $_->id } $repo->incoming($id, $type);
		push @rows, [ _reverse_label($type) . ':', join(', ', @from) ] if @from;
	}

	$self->_table(@rows);
	my $body = $values->{body} // '';
	if ($body =~ /\S/) {
		$self->_say('');
		$self->_print($body =~ /\n\z/ ? $body : "$body\n");
	}
	return 0;
}

sub _validate_command($self, $repo, $opt, @args) {
	return $self->_usage(2) if @args;

	my $valid = $repo->is_valid;
	my @problems = $repo->errors;

	if ($opt->{json}) {
		$self->_json({ valid => $valid ? JSON::PP::true : JSON::PP::false, errors => \@problems });
	}
	else {
		$self->_say($_->is_error ? "$_" : "warning: $_") for @problems;

		my $records = () = $repo->records;
		my $errors = grep { $_->is_error } @problems;
		my $warnings = @problems - $errors;
		$self->_message(join ', ',
			_count($records, 'requirement'),
			_count($errors, 'error'),
			$warnings ? _count($warnings, 'warning') : ());
	}
	return $valid ? 0 : 1;
}

# A requirement's values for JSON output, with or without its body and
# incoming relations.
sub _values($self, $repo, $record, $full) {
	my $values = $record->get_values;
	$values->{file} = $repo->file($record);
	delete $values->{body} unless $full;
	if ($full) {
		my $id = $record->id;
		$values->{incoming} = {
			map { $_ => [ map { $_->id } $repo->incoming($id, $_) ] }
				Preq::Model::Field::Relation->types
		};
	}
	return $values;
}

# A list field's values for text output; relations show their target's title.
sub _list_value($self, $repo, $name, $values) {
	my %relation = map { $_ => 1 } Preq::Model::Field::Relation->types;
	return join ', ', map { $_ // '' } @$values unless $relation{$name};

	return join ', ', map {
		my $target = defined $_ ? $repo->record($_) : undef;
		my $title = $target ? $target->field('title')->get : undef;
		defined $title ? "$_ ($title)" : $_ // '';
	} @$values;
}

sub _reverse_label($type) {
	return {
		refines        => 'refined by',
		depends_on     => 'needed by',
		conflicts_with => 'conflicts with',
	}->{$type};
}

sub _table($self, @rows) {
	my @width;
	for my $row (@rows) {
		for my $i (0 .. $#$row - 1) {
			my $length = length $row->[$i];
			$width[$i] = $length if $length > ($width[$i] // 0);
		}
	}
	for my $row (@rows) {
		my @cells = map { sprintf '%-*s', $width[$_], $row->[$_] } 0 .. $#$row - 1;
		(my $line = join '  ', @cells, $row->[-1]) =~ s/\s+\z//;
		$self->_say($line);
	}
	return;
}

sub _json($self, $data) {
	$self->_say(JSON::PP->new->canonical->convert_blessed->encode($data));
	return;
}

sub _count($number, $noun) {
	return "$number $noun" . ($number == 1 ? '' : 's');
}

sub _usage($self, $status, $verbose = 0) {
	my $fh = $status ? $self->{err} : $self->{out};
	if (defined $self->{pod}) {
		pod2usage(
			-input    => $self->{pod},
			-output   => $fh,
			-verbose  => $verbose,
			-sections => [qw(SYNOPSIS COMMANDS OPTIONS)],
			-exitval  => 'NOEXIT',
		);
	}
	else {
		print $fh "Usage: preq [options] list|show ID|validate\n";
	}
	return $status;
}

sub _error($self, $status, $message) {
	$self->_message($message);
	return $status;
}

sub _message($self, $message) {
	print { $self->{err} } "preq: $message\n";
	return;
}

sub _say($self, $line) {
	$self->_print("$line\n");
	return;
}

sub _print($self, $text) {
	print { $self->{out} } $text;
	return;
}

1;

=head1 SEE ALSO

L<preq>, L<Preq::Repository>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Maurolepis Dreki.

This is free software, licensed under the Artistic License 2.0. See the
F<LICENSE> file in the distribution, or
L<https://opensource.org/license/artistic-2-0>.

=cut
