program = require "commander"
fs = require "fs"
childProcess = require "child_process"
spawn = childProcess.spawn

program
	.version('0.1.0')
	.option('-d, --directory [dir]', 'directory to analyse', '.')
	.option('-u, --user <email>', 'user email adress to filter')
	.option('-t, --time [time]', 'git log since compatible time')
	
calcTime = (data) ->
	
	
parseLog = (log, user) ->
	lines = log.split "\n"
	console.log "User\t\t'#{user}'"
	data = []
	for line in lines
		[hash, email, subject, time] = line.split ';#;'
		if email is user
			data.push
				hash: hash,
				subject: subject
				time: Date.parse(time) / 1000	
	console.log "Found\t\t", data.length, "commits"
	calcTime data

start = (email, directory) ->
	console.log "Scanning \t'#{directory}'"
	log = spawn "git", ['log', '--pretty=format:%h;#;%ae;#;%s;#;%ad','--no-merges','--date=rfc'],
		cwd: directory
	logData = ""
	log.stdout.on "data", (data) ->
		logData+= data.toString 'utf8'
	log.stdout.on "end", () ->
		parseLog logData, email
	log.stderr.on "error", (data) ->
		console.log "error: ", data
	log.on "exit", (code) ->
		if code isnt 0
			console.log "exit with", code


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


