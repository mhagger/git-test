# Exposed environment variables

`git test` exports the following environment variables which can for instance
be used if test are run through scripts.

* `GIT_TEST_VERBOSITY` - Numeric value modified by `--verbose` (+1) and
  `--quiet` (-1), e.g. `--verbose --verbose --verbose --quiet` gives value 2.

* `GIT_TEST_NAME` - Corresponds to the name of the current running test.

* `GIT_TEST_PREVIOUS_CHECKED_OUT_COMMIT` - When `git-test` runs tests on
several commits, this variable contains the commit that was checked out for
the previous test. Will be blank for the first commit checked out in a test
run.

# Example usage

Q: Wow, the following seems really complicated, do I really have to do all that
just to run a test?

A: Not at all. The following is more meant to be an example exploring
everything than can be done with environment variables more than a template
to be copied for everyone.

Example of using environment variables in a build script named `run-lint.sh`:

```shell
#!/bin/sh

if [ ${GIT_TEST_VERBOSITY:-0} -ge 1 ]
then
    if [ -f tslint.json ]
    then
        echo "Using tslint"
    else
        echo "Using eslint"
    fi
fi

PARENT=`git log --pretty=%P -n 1 HEAD`
# If current commit is not a merge commit ...
if [ `echo $PARENT | wc -w` -eq 1 ]
then
    if [ "$GIT_TEST_PREVIOUS_CHECKED_OUT_COMMIT" = "$PARENT" ]
    then
        # ... and package.json has not changed then skip running npm install.
        git diff --quiet "$PARENT" -- package.json || npm install
    else
        npm install
    fi
else
    npm install
fi

git tag -f current-git-test-"$GIT_TEST_NAME"
npm run lint
```

then when running

```shell
git test add --name=lint ./run-lint.sh
git test run --verbose --name=lint main..mybranch
```

the script will output which lint tool that will be used for each commit it
tests.

---

The tag `current-git-test-lint` will here be moved along as git-test checks out
new commits. This means for instance that you can follow the progress by just
refreshing your gitk window instead of having to check the output in a specific
terminal window.

If a test fails, the tag will be left on the last failing checked out commit,
so you can easily fix it in the development worktree by running
`rebase --interactive --rebase-merges current-git-test-lint^` for then to
`edit` the commit and fix the issue.

There is no "garbage collection" of such current test tags, so they will be
left decaying if not actively cleaned up. So if this is a worthwile thing to do
is completely up to you. But this is one example of what the `GIT_TEST_NAME`
environment variable can be used for.

---

Running `npm install` can be quite expensive, but should really be run for
every single test in order to ensure a proper environment. However by checking
if the current test's parent just has been tested and if there is no changes in
the package.json file, then we can skip running `npm install` because the
parent would already have had the proper setup.

The same principle can be used for git submodules where you run
`git submodule update --init --recursive` on the first test and then repeat
only if `.gitmodules` changes later.
