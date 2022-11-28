# `git test`

`git-test` is a command-line script for running automated tests against commits in a Git repository. It is especially targeted at developers who like their tests to pass on *every* commit in a branch, not just the branch tip.

The best way to use `git test` is to keep a window open in a second linked
[worktree](#best-practice-use-git-test-in-a-linked-worktree) of your repository,
and as often as you like run

    git test run master..mybranch

`git test` will test the commits in the specified range, reporting any failures. The pass/fail results of running tests are also recorded permanently in your repository as Git "notes" (see `git-notes(1)`).

If a commit in the range has already been tested, then by default `git test` reports the old results rather than testing it again. This means that you can run the above command over and over as you work, and `git test` won't repeat tests whose results it already knows. (Of course there are options to allow you to request explicitly that commits be retested.)

The test results are recorded by the *tree* that was tested, not the commit, so old test results remain valid even across some kinds of commit rewriting:

* If commits are rewritten to change their log messages, authorship, dates, etc., the test results remain valid.
* If consecutive commits are squashed, the results remain valid.
* If a commit is split into two, only the first (partial) commit needs to be tested.
* If some commits deep in a branch are reordered, the test results for commits built on top of the reordered commits often remain valid.

Of course this means that your tests should not depend on things besides the files in the tree. For example, whether your test passes/fails should *not* depend on the current branch name or commit message.

## Usage

### Defining tests

First define the test that you would like to run; for example,

    git test add "make -j8 && make test"

The string that you specify can be an arbitrary command; it is run with `sh -c`. Its exit code should be 0 if the test passes, or nonzero if it fails. The test definition is stored in your Git config.

### Test one or more commits

By default, `git test run` tests `HEAD`:

    git test run

(If the working copy is dirty, the test is run anyway but the results are not recorded.)

You can test a range of Git commits with a single command:

    git test run commit1..commit2

The test is run against each commit in the range, in order from old to new. If a commit fails the test, `git test` reports the error and stops with the broken commit checked out. You can also specify individual commits to test:

    git test run commit1 commit2 commit3

or test an arbitrary set of commits supplied via standard input:

    git rev-list feature1 feature2 ^master | git test run --stdin

You can adjust the verbosity of the output using the `--verbosity`/`-v` or `--quiet`/`-q` options. Either of these options can be specified multiple times.

### Define multiple tests

You can define multiple tests in a single repository (e.g., cheap vs. expensive tests). Their results are kept separate. By default, the test called `default` is run, but you can specify a different test to add/run using the `--test=<name>`/`-t <name>` option:

    git test add "make test"
    git test run commit1..commit2
    git test add --test=build "make"
    git test run --test=build commit1..commit2

### Retrying tests and/or forgetting old test results

If you have flaky tests that occasionally fail for bogus reasons, you might want to re-run the test against a commit even though `git test` has already recorded a result for that commit. To do so, run `git test run` with the `--force`/`-f` or `--retest` options.

If you want to forget particular old test results without retesting, run `git test run` with the `--forget` option.

If you want to permanently forget *all* stored results for a particular test (e.g., if something in your environment has changed), run

    git test forget-results [--test=<name>]

### Continue on test failures

Normally, `git test run` stops at the first broken commit that it finds. If you'd prefer for it to continue even after a failure, use the `--keep-going`/`-k` option.

### Removing tests

To permanently remove a test definition and all of its stored results, run

    git test remove [--test=<name>]

### For help

General help about `git test` can be obtained by running

    git test help

Help about a particular subcommand can be obtained via either

    git test help run

or

    git test run --help

## Exposed environment variables

`git test` exports some environment variables which can be used by test
commands. See [this file](./env.md) for details.

## Best practice: use `git test` in a linked worktree

`git test` works really well together with `git worktree`. Keep a second worktree and use it for testing your current branch continuously as you work:

    git worktree add --detach ../test HEAD
    cd ../test
    git test run master..mybranch

The last command can be re-run any time; it only does significant work when something changes on your branch. Plus, with this setup you can continue to work in your main working tree while the tests run.

Because linked worktrees share branches and the git configuration with the main repository, test definitions and test results are visible across all worktrees. So you could even run multiple tests at the same time in multiple linked worktrees.

## Installation

Requirements:

* A recent Git command-line client
* A Python interpreter. `git test` has been tested with Python versions 2.7 and 3.4. It will probably work with any Python3 version starting with 3.2 (it requires `argparse`).

Just put `bin/git-test` somewhere in your `$PATH`, adjusting its first line if necessary to invoke the desired Python interpreter properly in your environment.

## Ideas for future enhancements

Some other features that would be nice:

* Be more consistent about restoring `HEAD`. `git test run` currently checks out the branch that you started on when it is finished, but only if all of the tests passed. We need some kind of `git test reset` command analogous to `git bisect reset`.

* `git test bisect`: run `git bisect run` against a range of commits, using a configured test as the command that `bisect` uses to decide whether a commit is good/bad.

* `git test prune`: delete notes for obsolete trees.

* Continuous testing mode, where `git test` watches the repository for changes and re-runs itself automatically whenever the commits it is watching change.

* Dependencies between tests; for example:

  * Provide a way to say "if my `full` test passes, that implies that the `build` test would also pass".

  * Provide a way to run the `build` test (and record the `build` test's results) as the first step of the `full` test.

* Allow trees to be marked `skip`, if they shouldn't be tested (e.g., due to a known breakage). Perhaps allow the test script to emit a special return code to ask that the commit be marked `skip` (probably following the convention of `git bisect run`).

* Remember return codes and give them back out if the old result is reused.

* Add a `git test fix <range>`, which starts an interactive rebase, changing the command for the first broken commit from "pick" to "edit".

* Support tests that depend on the *commit*, not the *tree*, that they are run against.

## License

`git test` is released under the GPLv2+ license. Pull requests are welcome at the project's GitHub page, <https://github.com/mhagger/git-test>.

## Caveats and disclaimers

`git test` has pretty good automated tests, but it undoubtedly still has bugs and rough edges. Use it at your own risk.

### Detached head

Please note that when you tell `git test run` to test specified commits, it checks those commits out in your working directory. If the tests fail, it leaves the failing commit checked out *in a detached HEAD state*. This is intentional, so that you can examine the cause of the failure. But it means that if you had changes on your original HEAD that weren't part of any branch, they will now be unreachable.

If you don't know what a detached HEAD state is, please read up on it. Additionally, **it is recommended that you run `git test` in a separate worktree**, which is more convenient anyway (see above for instructions). Note that the `git worktree` command was added in Git release 2.5, so make sure you are using that version of Git or (preferably) newer.

The above considerations don't apply to running `git test` against HEAD or your current working tree. In other words,

    git test run

and

    git test run HEAD

don't change the commit that is checked out, and they won't change your working copy to a detached HEAD state.

### Test result "noise" when viewing history with `--all`

Notice that as a side effect of `git test` saving test results in git notes,
these notes will become visible "noise" when viewing history with `git log` or
`gitk` and using the version specifier `--all`. The solution is to tell git
to ignore those notes with `--exclude` (NB, must be specified *before* `--all`
in order to have effect).

Writing the full exclude phrase every time will probably be too cumbersome, so
you most likely want to write wrapper scripts like the following

    #!/bin/sh
    exec gitk --exclude=refs/notes/* --all "$@" &

or include `--exclude` in your git aliases.
