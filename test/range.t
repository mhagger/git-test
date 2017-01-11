#! /bin/sh

test_description="Test basic features"

. ./sharness.sh

PATH="$(pwd)/../test-helpers:$(pwd)/../bin:$PATH"
export PATH

SQ="'"

test_expect_success '"test range" emits a help message' '
	test_expect_code 2 git-test range --force c2..c6 2>actual &&
	grep -q "the ${SQ}range${SQ} subcommand has been renamed" actual
'

test_done
