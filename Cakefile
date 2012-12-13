{spawn, exec} = require 'child_process'

src = ['autoComplete.coffee', 'siphon2.coffee']

task 'watch', 'continually build with --watch', ->
    p1 = spawn 'coffee', ['-wcj', 'siphon2.js'].concat src
    p1.stdout.on 'data', (data) -> console.log data.toString().trim()

    p2 = spawn 'coffee', ['-wcbo', 'test'].concat src
    p2.stdout.on 'data', (data) -> console.log data.toString().trim()

    p3 = spawn 'coffee', ['-wc','spec']
    p3.stdout.on 'data', (data) -> console.log data.toString().trim()
