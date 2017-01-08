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
	done
'

test_expect_success 'default (passing): test range' '
	git test add "test-number --log=numbers.log --good \*" &&
	rm -f numbers.log &&
	git test range c2..c6 &&
	printf "default %s${LF}" 3 4 5 6 >expected &&
	test_cmp expected numbers.log
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
	test_must_fail test -f numbers.log
'

test_expect_success 'default (passing): retest forgotten commits' '
	rm -f numbers.log &&
	git test range c3..c8 &&
	printf "default %s${LF}" 5 6 7 >expected &&
	test_cmp expected numbers.log
'

test_done
