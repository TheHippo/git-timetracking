program = require "commander"
fs = require "fs"

program
	.version('0.1.0')
	.option('-d, --directory [dir]', 'directory to analyse', '.')
	.option('-u, --user <email>', 'user email adress to filter')
	.option('-t, --time [time]', 'git log since compatible time')

start = (email, directory) ->
	console.log "Scanning", directory, "for commits of user", email
	process.exit()


program.parse process.argv

fs.realpath program.directory, (err, path) ->
	if err?
		console.log "not a real path"
		process.exit()
	else	
		if not program.user
			program.prompt 'Email: ', (email) ->
				start email, path
		else
			start program.user, path


