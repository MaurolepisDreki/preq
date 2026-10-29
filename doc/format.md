<!-- Generated from lib/Preq/Manual/Format.pod by tools/pod2doc: edit the source and run `make docs`. -->

# NAME

Preq::Manual::Format - The preq requirement file format

# DESCRIPTION

preq stores each requirement as one text file. The files live in a
directory named `requirements/` at the root of the project they describe,
and are kept under version control with git.

A requirement file consists of a metadata header written in YAML, followed by
a body written in Markdown:

	---
	id: REQ-002
	title: Store requirements as text files
	status: approved
	priority: high
	author: Maurolepis Dreki
	created: 2026-10-27
	tags: [storage]
	refines: [REQ-001]
	---
	Each requirement shall be stored as one text file, kept under
	version control with git.

# FILES

- Files are named after the requirement's `id` with the extension `.md`, for
example `requirements/REQ-002.md`. The file name must match the `id` in the
header.
- Files are encoded in UTF-8 and use LF line endings.

# HEADER

The file must begin with a line containing exactly `---`. The header ends at
the next line containing exactly `---`. Everything between the two lines is a
YAML mapping, read with the YAML 1.2 core schema; in particular, dates and
words such as `yes` or `no` are read as plain strings.

Values containing a colon followed by a space, or beginning with a YAML
special character, must be quoted:

	title: "Search: by tag and by text"

The set of keys is fixed. A header containing any key not listed below is
invalid.

## Fields

- `id` (required)

	The requirement's identifier: `REQ-` followed by three or more digits, for
	example `REQ-001`. Identifiers are unique within a project and never reused.

- `title` (required)

	A short, single-line summary.

- `status` (required)

	One of:

	- `draft`

		Proposed, not yet agreed.

	- `approved`

		Agreed, not yet implemented.

	- `implemented`

		Implemented.

	- `obsolete`

		No longer applies. Obsolete requirements are kept, not deleted, so their
		identifiers are never reused.

- `priority` (optional)

	One of `low`, `medium` or `high`.

- `author` (optional)

	The name of the requirement's author.

- `created` (required)

	The date the requirement was created, in the form `YYYY-MM-DD`.

- `tags` (optional)

	A list of short, lowercase words used for grouping and searching.

## Relations

Relations are lists of requirement identifiers. Each relation is recorded only
in the requirement it starts from; the reverse direction (for example, which
requirements refine `REQ-001`) is derived by preq. Every identifier listed
must name an existing requirement.

- `refines` (optional)

	The requirements this one is a more detailed part of. This forms the
	requirement hierarchy and must not contain cycles.

- `depends_on` (optional)

	The requirements that must be satisfied before this one can be.

- `conflicts_with` (optional)

	The requirements this one contradicts. The relation is symmetric: it needs to
	be recorded in only one of the two requirements.

## Writing order

When preq writes a header, it writes the keys in the order listed above
(`id`, `title`, `status`, `priority`, `author`, `created`, `tags`,
`refines`, `depends_on`, `conflicts_with`), leaves out optional keys that
have no value, and quotes values only where YAML requires it, so that changes
produce small, readable diffs.

# BODY

Everything after the closing `---` line is the requirement's description,
written in CommonMark Markdown. The body may be empty while a requirement is a
draft; a requirement with any other status must have a body. The title is not
repeated as a heading in the body.

# SEE ALSO

[Preq](../lib/Preq.pm), [Preq::Model::Field](../lib/Preq/Model/Field.pm)

# AUTHOR

Maurolepis Dreki <inventerna@gmail.com>

# COPYRIGHT

Copyright (C) 2026 Maurolepis Dreki.
