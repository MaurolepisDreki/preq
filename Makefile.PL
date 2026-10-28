use v5.36;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Specman',
	AUTHOR           => 'Maurolepis Dreki <inventerna@gmail.com>',
	VERSION_FROM     => 'lib/Specman.pm',
	ABSTRACT_FROM    => 'lib/Specman.pm',
	LICENSE          => 'unknown',
	MIN_PERL_VERSION => '5.036',
	EXE_FILES        => ['bin/specman'],
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '7.12',
	},
	TEST_REQUIRES => {
		'Test::More' => '0.98',
		'Test2::V0'  => '0',
	},
	PREREQ_PM => {
		'YAML::PP' => '0',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		prereqs     => {
			develop => {
				requires => {
					'Pod::Markdown' => '3.400',
				},
			},
		},
	},
	test => { TESTS => 't/*.t' },
);

package MY;

# `make docs` regenerates the Markdown documentation in doc/ from its POD
# source; see tools/pod2doc.
sub postamble {
	return <<'END';
.PHONY : docs

docs :
	$(PERL) tools/pod2doc
END
}
