#!/usr/bin/env coffee

fs = require "fs"

jsonName = process.argv[2]
timeShift = parseInt process.argv[3], 10

fs.readFile jsonName, (err, data) =>
	kr = JSON.parse data
	for track of kr
		for recordI in [0...kr[track].length]
			if kr[track][recordI].time
				kr[track][recordI].time = parseInt(kr[track][recordI].time) + timeShift
	console.log JSON.stringify kr, null, 2