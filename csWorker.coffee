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
