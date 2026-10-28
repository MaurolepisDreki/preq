use v5.36;
use Test2::V0;

# The Markdown documentation in doc/ is generated from POD by tools/pod2doc;
# check that it has been regenerated since the POD last changed.

skip_all 'Pod::Markdown is needed to check the generated documentation'
	unless eval { require Pod::Markdown; 1 };

my $output = `$^X tools/pod2doc --check`;
is($? >> 8, 0, 'doc/ is up to date with its POD source') or diag $output;

done_testing;
