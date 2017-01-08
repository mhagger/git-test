#! /bin/sh

test_description="Test adding and changing test definitions"

. ./sharness.sh

PATH="$(pwd)/../test-helpers:$(pwd)/../bin:$PATH"
export PATH

SQ="'"
DQ='"'

test_expect_success 'Set up test repository' '
	git init .
'

test_expect_success 'Configure a default test' '
	git test add "echo foo" &&
	echo "echo foo" >expected &&
	git config --get test.default.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Change the default test' '
	git test add "echo bar" &&
	echo "echo bar" >expected &&
	git config --get test.default.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Configure a different test' '
	git test add --test=baz "echo baz" &&
	echo "echo baz" >expected &&
	git config --get test.baz.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Change a different test' '
	git test add --test=baz "echo xyzzy" &&
	echo "echo xyzzy" >expected &&
	git config --get test.baz.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Configure a test that includes single quotes' '
	git test add --test=sq "echo ${SQ}foo${SQ}" &&
	echo "echo ${SQ}foo${SQ}" >expected &&
	git config --get test.sq.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Configure a test that includes double quotes' '
	git test add --test=dq "echo ${DQ}foo${DQ}" &&
	echo "echo ${DQ}foo${DQ}" >expected &&
	git config --get test.dq.command >actual &&
	test_cmp expected actual
'

test_expect_success 'Configure a test that includes newlines' '
	git test add --test=nl "echo foo${LF}echo bar" &&
	echo "echo foo${LF}echo bar" >expected &&
	git config --get test.nl.command >actual &&
	test_cmp expected actual
'

test_done
