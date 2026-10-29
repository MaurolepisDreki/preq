# Contributing to preq

Thank you for your interest in preq.

## Bug reports and suggestions

Bug reports, questions and suggestions are welcome as GitHub issues. They need
no agreement.

## Code and documentation contributions

preq is owned by Maurolepis Dreki (the "Owner"), who keeps the copyright in
the whole project so that it can be maintained, and relicensed if needed, by
one person. Code, documentation and other material are therefore accepted only
under the copyright assignment below.

A "Contribution" is any work you submit to the Owner for inclusion in preq,
by pull request, patch, or any other means. Work you keep in your own fork or
derivative of preq, and do not submit, is not a Contribution: you keep your
rights in it, subject to the [licence](LICENSE).

### Copyright assignment

By submitting a Contribution with the sign-off described below, you agree that:

1. You assign to the Owner all copyright and other intellectual property
	rights in the Contribution, worldwide, and the Contribution becomes part
	of preq.
2. To the extent that this assignment is not effective under applicable law,
	you grant the Owner an exclusive, perpetual, irrevocable, worldwide,
	royalty-free licence, with the right to sublicense, to use, copy, modify,
	relicense and distribute the Contribution in any way, and you waive, or
	agree not to assert, any moral rights in it.
3. The Contribution is your own original work, or you otherwise have the
	right to make this assignment, and it does not knowingly infringe anyone
	else's rights.
4. If your employer or anyone else has rights in work you create, you have
	their permission to make the Contribution and this assignment.
5. After the assignment you may still use, copy and modify your
	Contribution as part of preq, under preq's licence, like anyone else.
6. The Owner is not obliged to accept or use any Contribution.

### Sign-off

Each commit in a Contribution must end with a line confirming your agreement:

	Assigned-to: Maurolepis Dreki
	Signed-off-by: Your Name <your.email@example.com>

`git commit -s` adds the `Signed-off-by` line for you. Contributions without
both lines will not be merged.

## Style

Follow the style of the surrounding code; in particular, indent with tabs.
Run the tests with `prove -l t` before submitting, and regenerate the
documentation with `make docs` if you changed any POD.
