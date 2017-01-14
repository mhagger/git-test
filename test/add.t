#! /bin/sh

test_description="Test adding and changing test definitions"

. ./sharness.sh

test_expect_success 'Set up test repository' '
	git init . &&
	git config user.name "Test User" &&
	git config user.email "user@example.com" &&
	git commit --allow-empty -m 'Initial' &&
	echo 4b825dc642cb6eb9a060e54bf8d69288fbee4904 >empty_tree
'

test_expect_success 'Configure a default test' '
	git-test add "echo foo" 2>warning &&
	test_must_fail grep -q "there are already results" warning &&
	echo "echo foo" >expected &&
	git config --get test.default.command >actual &&
	test_cmp expected actual &&
	git rev-parse --verify --quiet refs/notes/tests/default^{tree} >tree &&
	test_cmp empty_tree tree
'

test_expect_success 'Change the default test' '
	git-test add "echo bar" 2>warning &&
	test_must_fail grep -q "there are already results" warning &&
	echo "echo bar" >expected &&
	git config --get test.default.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Warn about old results but keep them' '
	# Add some simulated test results:
	git notes --ref=tests/default add -m 'good' HEAD^{tree} &&
	git-test add "echo foobar" 2>warning &&
	grep -q "there are already results" warning &&
	echo "echo foobar" >expected &&
	git config --get test.default.command >actual &&
	test_cmp expected actual &&
	git notes --ref=tests/default show HEAD^{tree}
'

test_expect_success 'With --keep, silently keep old results' '
	git-test add --keep "echo keep" 2>warning &&
	test_must_fail grep -q "there are already results" warning &&
	echo "echo keep" >expected &&
	git config --get test.default.command >actual &&
	test_cmp expected actual &&
	git notes --ref=tests/default show HEAD^{tree}
'

test_expect_success 'With --forget, forget old results' '
	git-test add --forget "echo forget" 2>warning &&
	test_must_fail grep -q "there are already results" warning &&
	echo "echo forget" >expected &&
	git config --get test.default.command >actual &&
	test_cmp expected actual &&
	git rev-parse --verify --quiet refs/notes/tests/default^{tree} >tree &&
	test_cmp empty_tree tree
'

test_expect_success 'forget-results' '
	# Add some simulated test results:
	git notes --ref=tests/default add -m 'good' HEAD^{tree} &&
	git-test forget-results &&
	echo "echo forget" >expected &&
	git config --get test.default.command >actual &&
	test_cmp expected actual &&
	git rev-parse --verify --quiet refs/notes/tests/default^{tree} >tree &&
	test_cmp empty_tree tree
'

test_expect_success 'Remove the default test' '
	git-test remove &&
	test_must_fail git config --get test.default.command &&
	test_must_fail git rev-parse --verify --quiet refs/notes/tests/default
'

test_expect_success 'forget-results for an undefined test' '
	# Add some simulated test results:
	git notes --ref=tests/imnotatest add -m 'good' HEAD^{tree} &&
	git-test forget-results --test=imnotatest &&
	test_must_fail git rev-parse --verify --quiet refs/notes/tests/imnotatest
'

test_expect_success 'Configure a different test' '
	git-test add --test=baz "echo baz" &&
	echo "echo baz" >expected &&
	git config --get test.baz.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Change a different test' '
	git-test add --test=baz "echo xyzzy" &&
	echo "echo xyzzy" >expected &&
	git config --get test.baz.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Configure a test that includes single quotes' '
	git-test add --test=sq "echo ${SQ}foo${SQ}" &&
	echo "echo ${SQ}foo${SQ}" >expected &&
	git config --get test.sq.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Configure a test that includes double quotes' '
	git-test add --test=dq "echo ${DQ}foo${DQ}" &&
	echo "echo ${DQ}foo${DQ}" >expected &&
	git config --get test.dq.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Configure a test that includes newlines' '
	git-test add --test=nl "echo foo${LF}echo bar" &&
	echo "echo foo${LF}echo bar" >expected &&
	git config --get test.nl.command >actual &&
	test_cmp expected actual
'

test_done
