<!-- Generated from bin/preq by tools/pod2doc: edit the source and run `make docs`. -->

# NAME

preq - Manage project requirements

# SYNOPSIS

	preq [--dir DIR] list [--status STATUS] [--tag TAG] [--json]
	preq [--dir DIR] show ID [--json]
	preq [--dir DIR] validate [--json]
	preq --help | --version

# DESCRIPTION

**preq** works with a project's requirements, stored as one file per
requirement in a directory, in the format described in
[Preq::Manual::Format](format.md).

Text output is meant for people. For use by other tools, every command
accepts **--json**, which prints a single line of JSON instead.

# COMMANDS

## list

Lists the requirements, one per line, with their identifier, status, priority
and title:

	ID       STATUS    PRIORITY  TITLE
	REQ-001  approved  high      Manage project requirements
	REQ-002  approved  high      Store requirements as text files

With **--json**, prints an array of objects, one per requirement, holding
every field except `body`, and `file`, the requirement's file name.

## show _ID_

Shows one requirement: its fields, the requirements related to it (as
_refined by_, _needed by_ and _conflicts with_), and its body:

	id:          REQ-002
	title:       Store requirements as text files
	status:      approved
	priority:    high
	author:      Maurolepis Dreki
	created:     2026-10-27
	tags:        storage
	refines:     REQ-001 (Manage project requirements)
	refined by:  REQ-003, REQ-004

	Each requirement shall be stored as one text file, kept under version control
	with git.

With **--json**, prints an object holding every field, `file`, and
`incoming`: for each relation type, the identifiers of the requirements with
that relation to this one.

## validate

Checks every requirement and the relations between them, and prints each
problem found, one per line, as in `REQ-002.md: tags: item 2: is empty`.
Warnings are prefixed with `warning:`; they are worth attention, but do not
make the requirements invalid. A summary is printed to standard error:

	preq: 8 requirements, 0 errors

The checks cover:

- each file: valid UTF-8, LF line endings, a header that is a valid YAML
mapping, and a file name matching the requirement's `id`;
- each requirement: required fields present, no unknown fields, and every value
in the right form; no relation to itself; a body unless it is a draft;
- all requirements together: unique identifiers, relations to requirements that
exist, and no cycles in `refines` or `depends_on`.

With **--json**, prints an object holding `valid`, true or false, and
`errors`, an array of objects, one per problem:

	{"errors":[{"field":"status","file":"REQ-001.md","id":"REQ-001","message":"'done' is not one of draft, approved, implemented, obsolete","severity":"error","text":"REQ-001.md: status: 'done' is not one of draft, approved, implemented, obsolete"}],"valid":false}

Each object holds:

- `message`

	The problem, without its location.

- `severity`

	`error` or `warning`.

- `text`

	The problem as printed without **--json**.

- `file`, `id`, `field`, `item`

	Where the problem is; only the parts that apply are present. `item` counts
	from 1.

# OPTIONS

- **-d**, **--dir** _DIR_

	The directory holding the requirement files. Defaults to `requirements` in
	the current directory.

- **--status** _STATUS_

	With **list**, lists only requirements with the given status.

- **--tag** _TAG_

	With **list**, lists only requirements with the given tag.

- **--json**

	Prints JSON instead of text.

- **-h**, **--help**

	Prints this help and exits.

- **-V**, **--version**

	Prints the version and exits.

# EXIT STATUS

- **0**

	Success. For **validate**: no errors were found.

- **1**

	For **validate**: errors were found; warnings alone do not count. For **show**: no requirement has the
	given identifier.

- **2**

	The command line or the requirements directory is invalid.

# SEE ALSO

[Preq](../lib/Preq.pm), [Preq::Manual::Format](format.md)

# AUTHOR

Maurolepis Dreki <inventerna@gmail.com>

# COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.
