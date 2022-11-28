#!/bin/bash

if [[ $# -lt 1 ]]
then
	echo "Usage: $0 [-t name] <commit|range>" 1>&2
	exit 1
fi

get_main_worktree() {
	# Example output:

	# worktree /home/user/src/git-test
	# HEAD e42d298cff233471c47b50f0f44bb05867109a24
	# branch refs/heads/main
	#
	# worktree /home/user/src/worktree.test.git-test
	# HEAD 1c0c32641de4a00fa6f5fbd4ddcb478bf5a6ca3f
	# detached

	# Main worktree is always listed first.
	git worktree list --porcelain | sed -n '1s/^worktree //p'
}

wait_for_next_run() {
	if type -P inotifywait >/dev/null
	then
		gitdir=$(git rev-parse --git-dir)
		case $gitdir
		in
			*.git/worktrees*)
				# Inside a linked worktree so use .git dir for main worktree for monitoring.
				gitdir=$(cd $(get_main_worktree); git rev-parse --path-format=absolute --git-dir)
				;;
			*)
				;;
		esac
		# We need delete_self to pick up changes to HEAD (since it gets renamed
		# over), and "move" to pick up changes in the refs directories.
		inotifywait -qq -e delete_self -e move -r "$gitdir/HEAD" "$gitdir/refs"
	else
		n=0
		while [[ $n -lt ${GIT_TEST_CONTINOUS_INTERVAL:-30} ]]
		do
			n=$(( n + 1 ))
			echo -n .
			sleep 1
		done
		echo
	fi
}

while true
do
	git test run "$@"

	wait_for_next_run
done
