program = require "commander"
fs = require "fs"
childProcess = require "child_process"
spawn = childProcess.spawn

defaultPauseTime = 20
defaultInitTime = 10

parsePauseTime = (val) ->
	console.log "parse"
	if val?
		parseInt val
	else
		defaultPauseTime

parseInitTime = (val) ->
	console.log "parse"
	if val?
		parseInt val
	else
		defaultPauseTime

program
	.version('0.1.0')
	.option("-d, --directory [dir]", "directory to analyse", ".")
	.option("-u, --user <email>", "user email adress to filter")
	#.option("-t, --time [time]", "git log since compatible time")
	.option("-p, --pause <pause>", "max pause time in minutes (default: #{defaultPauseTime})", parsePauseTime)
	.option("-i, --init <init>", "init time in minutes (default: #{defaultInitTime})", parseInitTime)


formatTime = (sum) ->
	[Math.floor( sum / 60 / 60), Math.floor(Math.floor(sum / 60) % 60), sum % 60]

calcTime = (data) ->
	pause = program.pause * 60
	init = program.init * 60
	
	sum = 0
	for i in [0...data.length]
		commit = data[i]
		if not data[i+1]?
			commit.effort = init
		else
			prev = data[i+1]
			if prev.time + pause < commit.time
				commit.effort = init
			else
				commit.effort = commit.time - prev.time
		sum+=commit.effort	
		#console.log commit.hash, commit.time, commit.effort / 1000 / 60
		
	[h,m,s] = formatTime sum
	console.log "#{h}:#{m}:#{s}"
		
	process.exit()
	
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
		if not program.pause?
			program.pause = defaultPauseTime
		if not program.init?
			program.init = defaultInitTime
		if not program.user?
			program.prompt 'Email: ', (email) ->
				start email, path
		else
			start program.user, path


