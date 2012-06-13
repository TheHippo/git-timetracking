# git-timetracking

git-timetracking analyses your git log and makes and estimation
on how much time you spend working on the repository


## Options

	$ ./git-timetracking --help

	  Usage: git-timetracking [options]

	  Options:

		-h, --help             output usage information
		-V, --version          output the version number
		-d, --directory [dir]  directory to analyse
		-g, --group [regexp]   group commit times by regexp
		-u, --user <email>     user email adress to filter
		-p, --pause <pause>    max pause time in minutes (default: 20)
		-i, --init <init>      init time in minutes (default: 10)
