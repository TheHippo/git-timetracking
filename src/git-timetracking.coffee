program = require "commander"
fs = require "fs"
childProcess = require "child_process"
spawn = childProcess.spawn
cliTable = require "cli-table"

outputPossibilities = ["csv", "ascii"]

defaultOutputFormat = outputPossibilities[0]
defaultPauseTime = 20
defaultInitTime = 10


parseOutputFormat = (val) ->
	if val?
		val = val.toLowerCase()
		for option in outputPossibilities
			if option is val
				return val
	outputPossibilities[0]

parsePauseTime = (val) ->
	if val?
		parseInt val
	else
		defaultPauseTime

parseInitTime = (val) ->
	if val?
		parseInt val
	else
		defaultPauseTime

program
	.version('0.2.2')
	.option("-d, --directory [dir]", "directory to analyse", ".")
	.option("-g, --group [regexp]", "group commit times by regexp", null)
	.option("-u, --user <email>", "user email adress to filter")
	#.option("-t, --time [time]", "git log since compatible time")
	.option("-p, --pause [pause]", "max pause time in minutes (default: #{defaultPauseTime})", parsePauseTime)
	.option("-i, --init [init]", "init time in minutes (default: #{defaultInitTime})", parseInitTime)
	.option("-o, --output [format]", "output formats (default: #{defaultOutputFormat}) (options: " + outputPossibilities.join(", ") + ")" , parseOutputFormat)

zeroPadding = (str) ->
	str = str.toString()
	if str.length is 1
		"0" + str
	else
		str

formatTime = (sum) ->
	[zeroPadding(Math.floor( sum / 60 / 60)),zeroPadding(Math.floor(Math.floor(sum / 60) % 60)),zeroPadding(sum % 60)]

formatTimeToString = (sum) ->
	[h,m,s] = formatTime sum
	return "#{h}:#{m}:#{s}"
	

outputSummary = (data) ->
	table = new cliTable
		head: ['Issue', 'Time spent', 'Commit count']
		colWidth: [100,100,100]
	
	if program.group?
		try
			reg = new RegExp program.group , 'i'
			grouped = {}
		catch error
			console.log "Could not compile regular expression", error
			process.exit
	else
		reg = null
		grouped = null
		console.log "no grouping"
	
	total = 0

	for commit in data
		total += commit.effort
		if reg?
			grouper = null
			match = commit.subject.match reg
			grouper = match[1] if match?
			if grouper
				if not grouped[grouper]?
					grouped[grouper] =
						count: 1
						effort: commit.effort
				else
					grouped[grouper].count++
					grouped[grouper].effort += commit.effort
			else
				if not grouped["other"]?
					grouped["other"] =
						count: 1
						effort: commit.effort
				else
					grouped["other"].count++
					grouped["other"].effort += commit.effort
	
	if grouped
		for k,v of grouped
			table.push [k, formatTimeToString(v.effort), v.count]
	
	table.push ["TOTAL:",formatTimeToString(total),data.length]
	console.log table.toString()
	process.exit()

calcTime = (data) ->
	pause = program.pause * 60
	init = program.init * 60
	
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
		
	outputSummary data
	
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
			console.log "Git log exit with", code


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
		if not program.output?
			program.output = defaultOutputFormat
		if not program.user?
			console.log "Need user email address"
			process.exit()
		else
			start program.user, path


