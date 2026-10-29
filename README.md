# preq

preq manages a project's requirements.

Each requirement is a short descriptive document with attached metadata,
stored as one Markdown file with a YAML header. Requirements can be related
to each other: a requirement can refine, depend on, or conflict with others.
Because requirements are plain text files, they are kept in git alongside the
project they describe, and reviewed like any other change.

preq checks that requirement files are well formed and consistent with
each other, and presents them through:

- a desktop GUI, for creating and editing requirements (planned);
- a command-line interface, for scripting and integration with other tools;
- a read-only web view, for browsing and searching (planned).

## Documentation

| Document | Contents |
|---|---|
| [INSTALL.md](INSTALL.md) | Requirements, building, testing and installing |
| [doc/format.md](doc/format.md) | The requirement file format |
| [doc/commands.md](doc/commands.md) | The `preq` command and its options |
| [REVIEW.md](REVIEW.md) | Provisional behaviours to revisit |
| [requirements/](requirements/) | preq's own requirements |

The documents in `doc/` are generated from the POD in the source, which is also
installed as manual pages; edit the POD, not the Markdown. See
[INSTALL.md](INSTALL.md#documentation).

The Perl modules are documented in POD; read them with `perldoc`, for example
`perldoc lib/Preq/Repository.pm`.

## Project layout

| Path | Contents |
|---|---|
| `bin/preq` | The command-line program |
| `lib/Preq/Model/` | Fields, records and validation |
| `lib/Preq/Repository.pm` | Reading, writing and checking requirement files |
| `lib/Preq/CLI.pm` | The command-line interface |
| `doc/` | User documentation, generated from POD |
| `requirements/` | preq's own requirements, in preq's format |
| `t/` | Tests |
| `tools/` | Development tools, not installed |
| `Makefile.PL` | Build, test and install |

## Contributing

Bug reports and suggestions are welcome. Code contributions are accepted only
with copyright assigned to the author; see [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

Copyright (C) 2026 Maurolepis Dreki.

preq is free software, licensed under the Artistic License 2.0. See
[LICENSE](LICENSE).
