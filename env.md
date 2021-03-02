# Exposed environment variables

`git test` exports the following environment variables which can for instance
be used if test are run through scripts.

* `GIT_TEST_VERBOSITY` - Numeric value modified by `--verbose` (+1) and
  `--quiet` (-1), e.g. `--verbose --verbose --verbose --quiet` gives value 2.

* `GIT_TEST_NAME` - Corresponds to the name of the current running test.

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
