#! /bin/sh

test_description="Test forgetting test results"

. ./sharness.sh

test_expect_success 'Set up test repository' '
	git init . &&
	git config user.name "Test User" &&
	git config user.email "user@example.com" &&
	for i in $(seq 0 3)
	do
		echo $i >number &&
		git add number &&
		git commit -m "Number $i"
	done &&
	true
'

test_expect_success 'Add tests' '
	git-test add true &&
	git-test add -t t1 true &&
	git-test add -t t2 true &&
	git-test add -t t3 true &&
	true
'

test_expect_success 'Add some simulated test results' '
	git notes --ref=tests/default add -m "good" HEAD~0^{tree} &&
	git notes --ref=tests/default add -m "good" HEAD~1^{tree} &&
	git notes --ref=tests/default add -m "good" HEAD~2^{tree} &&
	git notes --ref=tests/default add -m "good" HEAD~3^{tree} &&
	true &&
	git notes --ref=tests/t1 add -m "good" HEAD~0^{tree} &&
	git notes --ref=tests/t1 add -m "good" HEAD~1^{tree} &&
	git notes --ref=tests/t1 add -m "good" HEAD~2^{tree} &&
	git notes --ref=tests/t1 add -m "bad" HEAD~3^{tree} &&
	true &&
	git notes --ref=tests/t2 add -m "good" HEAD~1^{tree} &&
	git notes --ref=tests/t2 add -m "bad" HEAD~2^{tree} &&
	true
'

test_expect_success 'Verify number of notes' '
	echo 4 > expected &&
	git notes --ref=tests/default list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 4 > expected &&
	git notes --ref=tests/t1 list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 2 > expected &&
	git notes --ref=tests/t2 list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 0 > expected &&
	git notes --ref=tests/t3 list | wc -l >actual &&
	test_cmp expected actual &&
	true
'

test_expect_success 'Forgetting default and not affecting other tests' '
	rm -f expected &&
	touch expected &&
	git-test forget-results >actual &&
	test_cmp expected actual &&
	echo 0 > expected &&
	git notes --ref=tests/default list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 4 > expected &&
	git notes --ref=tests/t1 list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 2 > expected &&
	git notes --ref=tests/t2 list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 0 > expected &&
	git notes --ref=tests/t3 list | wc -l >actual &&
	test_cmp expected actual &&
	true
'


test_expect_success 'Add default test results again' '
	git notes --ref=tests/default add -m "good" HEAD~0^{tree} &&
	git notes --ref=tests/default add -m "good" HEAD~1^{tree} &&
	git notes --ref=tests/default add -m "good" HEAD~2^{tree} &&
	git notes --ref=tests/default add -m "good" HEAD~3^{tree} &&
	true
'


test_expect_success 'Forgetting t1 and not affecting other tests' '
	rm -f expected &&
	touch expected &&
	git-test forget-results --test t1 >actual &&
	test_cmp expected actual &&
	echo 4 > expected &&
	git notes --ref=tests/default list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 0 > expected &&
	git notes --ref=tests/t1 list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 2 > expected &&
	git notes --ref=tests/t2 list | wc -l >actual &&
	test_cmp expected actual &&
	true &&
	echo 0 > expected &&
	git notes --ref=tests/t3 list | wc -l >actual &&
	test_cmp expected actual &&
	true
'

test_done
