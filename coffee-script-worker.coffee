@onmessage = (event) ->
    result =
        js: null
        error: null
    try
        result.js = CoffeeScript.compile event.data.source, event.data.options
    catch error
        # You need to copy properties in order to pass the property "message". 
        result.error =
            line: error.line
            message: error.message
            sourceURL: error.sourceURL
            stack: error.stack
    finally
        postMessage result
