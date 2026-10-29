# Open review items

Behaviours decided provisionally during development, flagged for later review.

## `Preq::Model::Record::set_values`

- **Replaces, never merges.** Fields not named in the given values are emptied.
	This suits loading a record from a file. Partial updates must currently go
	through the individual fields (`$record->field('status')->set(...)`).
	Revisit whether a merging update is wanted, e.g. for the GUI or CLI.
- **Unknown keys persist.** Keys with no matching field are remembered and
	reported as `NAME: is not a known field` until `set_values` is called again.
	Changing fields individually does not clear them.
- **One change.** All fields are set inside `Node::_batch`, so subscribers are
	notified once, after every field has been set.

## Validation criteria for strings

`Preq::Model::Field::Text` and its subclasses (`Id`, `Enum`, `Date`,
`Relation`):

- **An empty string is present but invalid.** `''` gives `is empty`; only `undef`
	counts as missing. So `title: ''` in a record reports `title: is empty`, not
	`title: is required`.
- **Whitespace is not checked.** Whitespace-only values (`'   '`) and leading or
	trailing whitespace are valid.
- **Line breaks are invalid; other control characters are not.** `\r` and `\n`
	give `contains a line break`; tabs and other control characters are accepted.
- **No length limits.**
- **Only references are rejected as non-text.** Numbers are accepted as text.
- **`Id` is strict.** The prefix `REQ-` is case-sensitive and only ASCII digits are
	accepted.

`Preq::Model::Field::Markdown`:

- **Any string is valid**, including empty and whitespace-only ones. Requiring a
	body is left to `Record::Requirement` (required unless the status is `draft`).

Values read from YAML headers:

- **YAML scalars become Perl values before validation.** Under the YAML 1.2 core
	schema, `true`, `false` and numbers in a header are read as Perl values, and
	therefore accepted as text (for example `title: true` becomes the title `1`).

## `Preq::Repository::save`

- **Requirements with errors can be saved**, so unfinished work is not lost. Only
	a missing or malformed `id`, a value that is not text, a list field holding a
	non-list, or a name clash with another file prevent saving.
- **Changing a requirement's id renames its file**: the new file is written, then
	the old one is removed. Git sees this as a delete plus an add until both are
	staged.
- **`null` is written for an empty list element** (for example a `tags` entry
	with no value), rather than refusing to save.
