#! /bin/sh

test_description="Verify that tests don't run 'git-test' via git"

. ./sharness.sh

SP=' '

test_expect_success 'forget-results' '
	test_must_fail grep "git${SP}test" "$TEST_DIR"/*.t
'

test_done
