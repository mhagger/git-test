#! /bin/sh

test_description="Test the test-number helper script"

. ./sharness.sh

PATH="$(pwd)/../test-helpers:$(pwd)/../bin:$PATH"
export PATH

test_expect_success 'Test good' '
	echo "4" >number &&
	test-number 4 &&
	test-number 1 2 4 &&
	test-number 4 5 6 &&
	test-number --bad 1 2 5 7 --good 4 &&
	test-number --bad 1 2 5 7 --good "*" &&
	test-number --bad 1 2 5 7 --good "*" --bad 4 &&
	test-number --good 4 --bad 4 &&
	test-number --good 4 --bad "*" &&
	test-number --ret=42 1 2 5 7 --good 4 &&
	test-number --ret=42 1 2 5 7 --good "*"
'

test_expect_success 'Test bad' '
	echo "4" >number &&
	test_expect_code 1 test-number --bad 4 &&
	test_expect_code 1 test-number --bad 1 2 4 &&
	test_expect_code 1 test-number --bad 4 5 6 &&
	test_expect_code 1 test-number 1 2 5 7 --bad 4 &&
	test_expect_code 1 test-number 1 2 5 7 --bad 4 --good "*" &&
	test_expect_code 1 test-number 1 2 5 7 --bad "*" &&
	test_expect_code 1 test-number 1 2 5 7 --bad "*" --good 4 &&
	test_expect_code 1 test-number --bad 4 --good 4 &&
	test_expect_code 1 test-number --bad 4 --good "*"
'

test_expect_success 'Test alternative retcode' '
	echo "4" >number &&
	test_expect_code 42 test-number --ret=42 4 &&
	test_expect_code 42 test-number --ret=42 1 2 4 &&
	test_expect_code 42 test-number --ret=42 4 5 6 &&
	test_expect_code 42 test-number 1 2 5 7 --ret=42 4 &&
	test_expect_code 42 test-number 1 2 5 7 --ret=42 4 --good "*" &&
	test_expect_code 42 test-number 1 2 5 7 --ret=42 "*" &&
	test_expect_code 42 test-number 1 2 5 7 --ret=42 "*" --good 4 &&
	test_expect_code 42 test-number --ret=42 4 --good 4 &&
	test_expect_code 42 test-number --ret=42 4 --good "*"
'

test_expect_success 'Test unmatched' '
	echo "4" >number &&
	test_expect_code 2 test-number --bad 1 2 5 7 &&
	test_expect_code 2 test-number --good 3 --bad 5 --ret=42 7
'

test_expect_success 'Test logging' '
	rm -f number.log &&
	echo "3" >number &&
	test_must_fail test-number --log=number.log --bad 3 --good 4 --ret=42 5 &&
	echo "4" >number &&
	test-number --log=number.log --bad 3 --good 4 --ret=42 5 &&
	echo "5" >number &&
	test_expect_code 42 test-number --log=number.log --bad 3 --good 4 --ret=42 5 &&
	printf "default %s${LF}" 3 4 5 >expected &&
	test_cmp expected number.log
'

test_expect_success 'Test logging with a name' '
	rm -f number-foo.log &&
	echo "3" >number &&
	test_must_fail test-number --test=foo --log=number-foo.log --bad 3 --good 4 --ret=42 5 &&
	echo "4" >number &&
	test-number --test=foo --log=number-foo.log --bad 3 --good 4 --ret=42 5 &&
	echo "5" >number &&
	test_expect_code 42 test-number --test=foo --log=number-foo.log --bad 3 --good 4 --ret=42 5 &&
	printf "foo %s${LF}" 3 4 5 >expected &&
	test_cmp expected number-foo.log
'

test_done
