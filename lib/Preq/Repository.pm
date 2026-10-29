package Preq::Repository 0.001;

use v5.36;

use Carp qw(croak);
use Encode qw(decode encode);
use Scalar::Util qw(refaddr);
use YAML::PP;
use parent 'Preq::Model::Node';

use Preq::Model::Error;

use Preq::Model::Field::Relation;
use Preq::Model::Record::Requirement;

=head1 NAME

Preq::Repository - A project's requirements, as files in a directory

=head1 SYNOPSIS

	use Preq::Repository;

	my $repo = Preq::Repository->new(dir => 'requirements')->load;

	unless ($repo->is_valid) {
		say for $repo->errors;
	}

	my $req = $repo->record('REQ-002');
	$req->field('status')->set('implemented');
	$repo->save($req);

=head1 DESCRIPTION

Reads and writes requirement files in the format described in
L<Preq::Manual::Format>, and checks the requirements against each other.

A repository is a L<Preq::Model::Node>: its errors are those of every file
and requirement it holds, and a change to any requirement is a change to the
repository. Errors are L<Preq::Model::Error> objects; errors about a
requirement give its file and identifier as part of their location, so they
read as C<REQ-002.md: status: is required>, or as
C<REQ-009: status: is required> for a requirement not yet saved.

Besides the errors of each requirement, a repository reports:

=over

=item *

files that cannot be read as requirements: invalid UTF-8, CRLF line endings, a
missing header, a header that is not valid YAML or not a mapping, or a header
containing C<body>;

=item *

files whose name does not match the identifier inside them;

=item *

identifiers used by more than one requirement;

=item *

relations to requirements that do not exist;

=item *

cycles in acyclic relation types, as in
C<refines: cycle REQ-001 -E<gt> REQ-002 -E<gt> REQ-001>.

=back

=head1 METHODS

=head2 new

	my $repo = Preq::Repository->new( dir => $path );

Creates and returns a new, empty repository for the given directory. Nothing
is read until L</load> is called.

=cut

sub new($class, %args) {
	my $dir = $args{dir} // croak 'dir is required';

	my $self = $class->SUPER::new(%args);
	$self->{dir} = $dir;
	$self->{yaml} = YAML::PP->new(schema => ['Core']);
	$self->{records} = [];
	$self->{file} = {};
	$self->{file_errors} = {};
	return $self;
}

=head2 dir

	my $path = $repo->dir;

Returns the repository's directory.

=cut

sub dir($self) {
	return $self->{dir};
}

=head2 load

	$repo->load;

Reads every F<.md> file in the directory, replacing any requirements already
held, and returns the repository. Files that cannot be read as requirements
are reported as errors. Dies if the directory cannot be read.

=cut

sub load($self) {
	opendir my $dh, $self->{dir} or croak "cannot read $self->{dir}: $!";
	my @names = sort grep { /\.md\z/ && -f "$self->{dir}/$_" } readdir $dh;
	closedir $dh;

	$self->_batch(sub {
		$self->_release($_) for $self->{records}->@*;
		$self->{records} = [];
		$self->{file} = {};
		$self->{file_errors} = {};

		for my $name (@names) {
			my ($values, @errors) = $self->_read("$self->{dir}/$name");
			if (@errors) {
				$self->{file_errors}{$name} = \@errors;
				next;
			}

			my $record = Preq::Model::Record::Requirement->new;
			$record->set_values($values);
			push $self->{records}->@*, $self->_adopt($record);
			$self->{file}{refaddr $record} = $name;
		}
	});

	return $self;
}

=head2 records

	my @reqs = $repo->records;

Returns all requirements, as L<Preq::Model::Record::Requirement> records,
in the order of their file names, followed by unsaved ones in the order they
were added.

=cut

sub records($self) {
	return $self->{records}->@*;
}

=head2 record

	my $req = $repo->record($id);

Returns the requirement with the given identifier, or C<undef> if there is
none.

=cut

sub record($self, $id) {
	for my $record ($self->{records}->@*) {
		my $rid = $record->id;
		return $record if defined $rid && $rid eq $id;
	}
	return;
}

=head2 file

	my $name = $repo->file($req);

Returns the name of the file a requirement was read from or last saved to,
or C<undef> if it has not been saved.

=cut

sub file($self, $record) {
	return $self->{file}{refaddr $record};
}

=head2 incoming

	my @reqs = $repo->incoming($id);
	my @reqs = $repo->incoming($id, $type);

Returns the requirements with a relation to the given identifier, optionally
only of the given relation type. For example, C<incoming('REQ-001', 'refines')>
returns the requirements refining C<REQ-001>.

=cut

sub incoming($self, $id, $type = undef) {
	return grep {
		grep {
			(!defined $type || $_->type eq $type) && ($_->get // '') eq $id
		} $_->relations
	} $self->{records}->@*;
}

=head2 next_id

	my $id = $repo->next_id;

Returns the identifier following the highest one in use, as in C<REQ-009>.

=cut

sub next_id($self) {
	my ($max) = sort { $b <=> $a } map { /\AREQ-([0-9]+)\z/ ? $1 : () }
		grep { defined } map { $_->id } $self->{records}->@*;
	return sprintf 'REQ-%03d', ($max // 0) + 1;
}

=head2 add

	$repo->add($req);

Adds a new requirement to the repository, without saving it, and returns it.

=cut

sub add($self, $record) {
	croak 'not a Preq::Model::Record::Requirement'
		unless ref $record && $record->isa('Preq::Model::Record::Requirement');

	push $self->{records}->@*, $self->_adopt($record);
	$self->_changed;
	return $record;
}

=head2 save

	my $name = $repo->save($req);

Writes a requirement of this repository to the file named after its
identifier, and returns the file name. If the requirement was read from a
file with a different name, that file is removed.

The header is written in the order of L<Preq::Manual::Format>, leaving out
empty optional fields; values are quoted only where YAML requires it.

Requirements with errors can be saved, so that unfinished work is not lost,
except that saving dies if:

=over

=item *

the requirement has no valid identifier;

=item *

another file already has the name, so it would be overwritten;

=item *

a value cannot be written, because it is not text, or a list field holds
something other than a list.

=back

=cut

sub save($self, $record) {
	croak 'not a requirement in this repository'
		unless grep { $_ == $record } $self->{records}->@*;

	my $id_field = $record->field('id');
	$id_field->is_valid;
	croak 'cannot save: the requirement has no valid id'
		if $id_field->is_empty || $id_field->errors;

	my $name = $record->id . '.md';
	my $old = $self->{file}{refaddr $record};
	croak "cannot save: $name already exists"
		if -e "$self->{dir}/$name" && (!defined $old || $old ne $name);

	my $text = $self->_format($record);
	my $path = "$self->{dir}/$name";
	my $tmp = "$self->{dir}/.$name.tmp";
	open my $fh, '>:raw', $tmp or croak "cannot write $tmp: $!";
	print $fh encode('UTF-8', $text) or croak "cannot write $tmp: $!";
	close $fh or croak "cannot write $tmp: $!";
	rename $tmp, $path or croak "cannot rename $tmp to $path: $!";

	unlink "$self->{dir}/$old" if defined $old && $old ne $name;
	$self->{file}{refaddr $record} = $name;
	$self->_changed;
	return $name;
}

sub _read($self, $path) {
	open my $fh, '<:raw', $path or return (undef, "cannot be read: $!");
	my $raw = do { local $/; <$fh> };
	close $fh;

	my $text = eval { decode('UTF-8', $raw, Encode::FB_CROAK) };
	return (undef, 'is not valid UTF-8') unless defined $text;
	return (undef, 'must use LF line endings, not CRLF') if $text =~ /\r/;

	my ($header, $body) = $text =~ /\A---\n(.*?)^---(?:\n|\z)(.*)\z/ms
		or return (undef, 'has no header (a block between two --- lines)');

	my $values = eval { $self->{yaml}->load_string($header) };
	if (!defined $values && $@) {
		my ($reason) = split /\n/, $@;
		$reason =~ s/ at \S+ line \d+\.?\z//;
		return (undef, "header is not valid YAML: $reason");
	}
	return (undef, 'header is not a mapping') unless ref $values eq 'HASH';
	return (undef, 'header must not contain body') if exists $values->{body};

	$values->{body} = $body;
	return ($values);
}

sub _format($self, $record) {
	my @lines = ('---');

	for my $name ($record->field_names) {
		next if $name eq 'body';
		my $field = $record->field($name);
		next if $field->is_empty;

		if ($field->isa('Preq::Model::Field::List')) {
			croak "cannot save: $name: is not a list" unless $field->elements;
			my @items = map { $self->_scalar($name, $_, 1) } $field->get->@*;
			push @lines, "$name: [" . join(', ', @items) . ']';
		}
		else {
			push @lines, "$name: " . $self->_scalar($name, $field->get, 0);
		}
	}
	push @lines, '---';

	my $body = $record->field('body')->get // '';
	croak 'cannot save: body: is not text' if ref $body;
	return join("\n", @lines) . "\n" . $body;
}

# Writes a value plainly if reading it back gives the same string, and
# double-quoted otherwise.
sub _scalar($self, $name, $value, $in_list) {
	return 'null' unless defined $value;
	croak "cannot save: $name: is not text" if ref $value;

	if ($value ne '' && $value !~ /\A\s|\s\z/) {
		my $yaml = $in_list ? "k: [$value]\n" : "k: $value\n";
		my $read = eval { $self->{yaml}->load_string($yaml) };
		my $back = !$read ? undef
			: $in_list ? (ref $read->{k} eq 'ARRAY' && $read->{k}->@* == 1 ? $read->{k}[0] : undef)
			: $read->{k};
		return $value if defined $back && !ref $back && $back eq $value;
	}

	my %escape = ("\\" => '\\\\', '"' => '\\"', "\n" => '\\n', "\r" => '\\r', "\t" => '\\t');
	(my $quoted = $value) =~ s/([\\"\n\r\t])/$escape{$1}/g;
	$quoted =~ s/([\x00-\x1f\x7f])/sprintf '\\x%02x', ord $1/ge;
	return qq{"$quoted"};
}

sub _name($self, $record) {
	my $file = $self->{file}{refaddr $record};
	return $file if defined $file;
	my $id = $record->id;
	return defined $id ? "$id.md (unsaved)" : '(unsaved, no id)';
}

sub _validate($self) {
	return map { $self->$_ } qw(
		_check_files
		_check_records
		_check_file_names
		_check_unique_ids
		_check_targets
		_check_cycles
	);
}

# Each check returns the errors it finds.

sub _check_files($self) {
	my $errors = $self->{file_errors};
	return map {
		my $file = $_;
		map { Preq::Model::Error->new(file => $file, message => $_) } $errors->{$file}->@*
	} sort keys %$errors;
}

sub _check_records($self) {
	return map {
		my $record = $_;
		$record->is_valid;
		map { $_->within($self->_location($record)) } $record->errors;
	} $self->{records}->@*;
}

sub _check_file_names($self) {
	return map {
		my $file = $self->{file}{refaddr $_};
		my $id = $_->id;
		defined $file && defined $id && $file ne "$id.md"
			? Preq::Model::Error->new(file => $file, id => $id, message => "file name does not match id '$id'")
			: ();
	} $self->{records}->@*;
}

sub _check_unique_ids($self) {
	my %names;
	for my $record ($self->{records}->@*) {
		my $id = $record->id // next;
		push $names{$id}->@*, $self->_name($record);
	}
	return map {
		my @names = $names{$_}->@*;
		@names > 1
			? Preq::Model::Error->new(id => $_, message => "is used by more than one requirement (" . join(', ', @names) . ')')
			: ();
	} sort keys %names;
}

sub _check_targets($self) {
	my %exists = map { $_ => 1 } $self->_ids;
	my @errors;
	for my $record ($self->{records}->@*) {
		for my $type (Preq::Model::Field::Relation->types) {
			my @links = $record->field($type)->elements;
			for my $i (0 .. $#links) {
				my $target = $links[$i]->get;
				push @errors, Preq::Model::Error->new(
					$self->_location($record),
					field   => $type,
					item    => $i + 1,
					message => "'$target' does not exist",
				) if defined $target && !$exists{$target};
			}
		}
	}
	return @errors;
}

sub _check_cycles($self) {
	my %exists = map { $_ => 1 } $self->_ids;
	my @errors;
	for my $type (Preq::Model::Field::Relation->types) {
		next unless Preq::Model::Field::Relation->new(type => $type)->is_acyclic;

		my %graph;
		for my $record ($self->{records}->@*) {
			my $id = $record->id // next;
			push $graph{$id}->@*, grep {
				defined && $_ ne $id && $exists{$_}
			} map { $_->get } $record->field($type)->elements;
		}
		push @errors, map {
			Preq::Model::Error->new(field => $type, message => 'cycle ' . join(' -> ', @$_, $_->[0]))
		} _cycles(\%graph);
	}
	return @errors;
}

# The identifiers in use.
sub _ids($self) {
	return grep { defined } map { $_->id } $self->{records}->@*;
}

# Where a requirement is, for errors about it.
sub _location($self, $record) {
	return (file => $self->{file}{refaddr $record}, id => $record->id);
}

# Returns each distinct cycle in a graph of id => [ids], as a list of ids
# starting from the smallest.
sub _cycles($graph) {
	my (%state, @stack, @cycles, %seen);

	my $visit = sub ($id) {
		$state{$id} = 1;
		push @stack, $id;
		for my $target (sort { $a cmp $b } ($graph->{$id} // [])->@*) {
			my $state = $state{$target} // 0;
			if ($state == 1) {
				my ($start) = grep { $stack[$_] eq $target } 0 .. $#stack;
				my @cycle = @stack[$start .. $#stack];
				my ($min) = sort { $cycle[$a] cmp $cycle[$b] } 0 .. $#cycle;
				@cycle = (@cycle[$min .. $#cycle], @cycle[0 .. $min - 1]);
				push @cycles, \@cycle unless $seen{"@cycle"}++;
			}
			elsif ($state == 0) {
				__SUB__->($target);
			}
		}
		pop @stack;
		$state{$id} = 2;
	};

	$visit->($_) for grep { !$state{$_} } sort keys %$graph;
	return @cycles;
}

1;

=head1 SEE ALSO

L<Preq::Manual::Format>, L<Preq::Model::Record::Requirement>

=head1 AUTHOR

Maurolepis Dreki E<lt>inventerna@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Maurolepis Dreki.

This is free software, licensed under the Artistic License 2.0. See the
F<LICENSE> file in the distribution, or
L<https://opensource.org/license/artistic-2-0>.

=cut
