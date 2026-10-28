# specman

specman manages a project's requirements.

Each requirement is a short descriptive document with attached metadata,
stored as one Markdown file with a YAML header. Requirements can be related
to each other: a requirement can refine, depend on, or conflict with others.
Because requirements are plain text files, they are kept in git alongside the
project they describe, and reviewed like any other change.

specman checks that requirement files are well formed and consistent with
each other, and presents them through:

- a desktop GUI, for creating and editing requirements (planned);
- a command-line interface, for scripting and integration with other tools;
- a read-only web view, for browsing and searching (planned).

## Documentation

| Document | Contents |
|---|---|
| [INSTALL.md](INSTALL.md) | Requirements, building, testing and installing |
| [doc/format.md](doc/format.md) | The requirement file format |
| [doc/commands.md](doc/commands.md) | The `specman` command and its options |
| [REVIEW.md](REVIEW.md) | Provisional behaviours to revisit |
| [requirements/](requirements/) | specman's own requirements |

The documents in `doc/` are generated from the POD in the source, which is also
installed as manual pages; edit the POD, not the Markdown. See
[INSTALL.md](INSTALL.md#documentation).

The Perl modules are documented in POD; read them with `perldoc`, for example
`perldoc lib/Specman/Repository.pm`.

## Project layout

| Path | Contents |
|---|---|
| `bin/specman` | The command-line program |
| `lib/Specman/Model/` | Fields, records and validation |
| `lib/Specman/Repository.pm` | Reading, writing and checking requirement files |
| `lib/Specman/CLI.pm` | The command-line interface |
| `doc/` | User documentation, generated from POD |
| `requirements/` | specman's own requirements, in specman's format |
| `t/` | Tests |
| `tools/` | Development tools, not installed |
| `Makefile.PL` | Build, test and install |
