# Exposed environment variables

`git test` exports the following environment variables which can for instance
be used if test are run through scripts.

* `GIT_TEST_VERBOSITY` - Numeric value modified by `--verbose` (+1) and
  `--quiet` (-1), e.g. `--verbose --verbose --verbose --quiet` gives value 2.

# Example usage

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

npm run lint
```

then when running

```shell
git test add --name=lint ./run-lint.sh
git test run --verbose --name=lint main..mybranch
```

the script will output which lint tool that will be used for each commit it
tests.
