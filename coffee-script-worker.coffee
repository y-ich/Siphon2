@onmessage = (event) ->
    result =
        js: null
        error: null
    try
        result.js = CoffeeScript.compile event.data.source, event.data.options
    catch error
        result.error = error
    finally
        postMessage result
