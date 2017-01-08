#! /bin/sh

test_description="Test basic features"

. ./sharness.sh

PATH="$(pwd)/../test-helpers:$(pwd)/../bin:$PATH"
export PATH

# The test repository consists of a linear chain of numbered commits.
# Each commit contains a file "number" containing the number of the
# commit. Each commit is pointed at by a branch "c<number>".

test_expect_success 'Set up test repository' '
	git init . &&
	git config user.name "Test User" &&
	git config user.email "user@example.com" &&
	for i in $(seq 0 10)
	do
		echo $i >number &&
		git add number &&
		git commit -m "Number $i" &&
		eval "c$i=$(git rev-parse HEAD)" &&
		git branch "c$i"
	done &&
	echo "good" >good-note &&
	echo "bad" >bad-note
'

test_expect_success 'default (passing): test range' '
	git test add "test-number --log=numbers.log --good \*" &&
	rm -f numbers.log &&
	git test range c2..c6 &&
	printf "default %s${LF}" 3 4 5 6 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c2^{tree} &&
	git notes --ref=tests/default show $c3^{tree} >actual-c3 &&
	test_cmp good-note actual-c3 &&
	git notes --ref=tests/default show $c6^{tree} >actual-c6 &&
	test_cmp good-note actual-c6 &&
	test_must_fail git notes --ref=tests/default show $c7^{tree}
'

test_expect_success 'default (passing): do not re-test known-good commits' '
	rm -f numbers.log &&
	git test range c3..c5 &&
	test_must_fail test -f numbers.log
'

test_expect_success 'default (passing): do not re-test known-good subrange' '
	rm -f numbers.log &&
	git test range c1..c7 &&
	printf "default %s${LF}" 2 7 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): do not retest known-good even with --retest' '
	rm -f numbers.log &&
	git test range --retest c0..c8 &&
	printf "default %s${LF}" 1 8 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): retest with --force' '
	rm -f numbers.log &&
	git test range --force c5..c9 &&
	printf "default %s${LF}" 6 7 8 9 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (passing): forget some results' '
	rm -f numbers.log &&
	git test range --forget c4..c7 &&
	test_must_fail test -f numbers.log &&
	test_must_fail git notes --ref=tests/default show $c5^{tree} &&
	test_must_fail git notes --ref=tests/default show $c7^{tree}
'

test_expect_success 'default (passing): retest forgotten commits' '
	rm -f numbers.log &&
	git test range c3..c8 &&
	printf "default %s${LF}" 5 6 7 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (failing-4-7-8): test range' '
	git update-ref -d refs/notes/tests/default &&
	git test add "test-number --log=numbers.log --bad 4 7 8 --good \*" &&
	rm -f numbers.log &&
	test_expect_code 1 git test range c2..c5 &&
	printf "default %s${LF}" 3 4 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c2^{tree} &&
	git notes --ref=tests/default show $c3^{tree} >actual-c3 &&
	test_cmp good-note actual-c3 &&
	git notes --ref=tests/default show $c4^{tree} >actual-c4 &&
	test_cmp bad-note actual-c4 &&
	test_must_fail git notes --ref=tests/default show $c5^{tree}
'

test_expect_success 'default (failing-4-7-8): do not re-test known commits' '
	rm -f numbers.log &&
	test_expect_code 1 git test range c2..c5 &&
	test_must_fail test -f numbers.log
'

test_expect_success 'default (failing-4-7-8): do not re-test known subrange' '
	rm -f numbers.log &&
	test_expect_code 1 git test range c1..c6 &&
	printf "default %s${LF}" 2 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (failing-4-7-8): retest known-bad with --retest' '
	rm -f numbers.log &&
	test_expect_code 1 git test range --retest c1..c6 &&
	printf "default %s${LF}" 4 >expected &&
	test_cmp expected numbers.log
'

test_expect_success 'default (failing-4-7-8): retest with --force' '
	# Test a good commit past the failing one:
	git test range c5..c6 &&
	rm -f numbers.log &&
	test_expect_code 1 git test range --force c2..c6 &&
	printf "default %s${LF}" 3 4 >expected &&
	test_cmp expected numbers.log &&
	test_must_fail git notes --ref=tests/default show $c5^{tree} &&
	# The notes for c6 must also have been forgotten:
	test_must_fail git notes --ref=tests/default show $c6^{tree}
'

test_done
