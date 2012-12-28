###
# csWorker.coffee - webworker interface for coffee-script.js
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
# how to build
# 1. compile csWorker.coffee
# 2. concatenate csWorker.js with coffee-script.js, say coffee-script-worker.js
# how to use on client side
compileCS = (source, options, callback) ->
    compileCS.worker.onmessage = ((id) ->
            (event) -> callback event.data if event.data.id is id
        )(compileCS.id)
    compileCS.worker.postMessage
        id: compileCS.id
        source: source
        options: options
    compileCS.id += 1    
compileCS.worker = new Worker 'coffee-script-worker.js'
compileCS.id = 0
# NOTE: When invoked compileCS before previous compile is done, the compile keep going but its result would be discarded.
###

self.onmessage = (event) ->
    try
        event.data.js = CoffeeScript.compile event.data.source, event.data.options
    catch error
        # You need to copy properties in order to pass the property "message". 
        event.data.error =
            line: error.line
            message: error.message
            sourceURL: error.sourceURL
            stack: error.stack
    finally
        postMessage event.data
