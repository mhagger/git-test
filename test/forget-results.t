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
	echo "All test results for test default were forgotten." >expected &&
	git-test forget-results --all >actual &&
	test_must_fail grep -q WARNING actual
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
	echo "All test results for test t1 were forgotten." >expected &&
	git-test forget-results --all --test t1 >actual &&
	test_must_fail grep -q WARNING actual
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

# sed command: On line 1 remove from the first space and the rest, and delete
# lines 2 and till the last line, e.g. only keep first word on first line.
test_expect_success 'Missing --all argument produces warning' '
	echo "WARNING:" >expected
	git-test forget-results 2>actual &&
	sed -i "1s/ .*//; 2,\$d" actual &&
	test_cmp expected actual
'


test_expect_success 'Should not give output on non-existent test' '
	rm -f expected &&
	touch expected &&
	git-test forget-results --all -t this-test-does-not-exist >actual &&
	test_cmp expected actual &&
	true
'

test_done
