###
# AutoComplete for CodeMirror in CoffeeScript
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
###

class AutoComplete
    constructor: (@cm, text) -> @char = text.charAt text.length - 1

    complete: ->
        return if @candidates?
        @candidates = []
        cursor = @cm.getCursor()

        switch @cm.getOption 'mode'
            when 'coffeescript'
                if /[a-zA-Z_$\.]/.test @char
                    propertyChain = []
                    pos = cursor
                    while (token = @cm.getTokenAt pos).string.charAt(0) is '.'
                        propertyChain.push token
                        pos = { line: cursor.line, ch: token.start - 1 }
                    propertyChain.push token
                    propertyChain.reverse()
                        
                    if propertyChain.length == 1
                        candidates = globalPropertiesPlusKeywords
                    else
                        try
                            object = eval propertyChain.map((e) -> e.string)[0..-2].join()
                            candidates = (key for key of object)
                        catch err
                            console.log err
                            candidates = []
                    target = propertyChain[propertyChain.length - 1].string.replace(/^\./, '')
                    @candidates = candidates.filter((e) -> new RegExp('^' + target).test e)
                                            .map (e) -> e[target.length..]
                else if @char is ' '
                    token = @cm.getTokenAt { line: cursor.line, ch: cursor.ch - 1 }
                    if KEYWORDS_COMPLETE.hasOwnProperty token.string
                        @candidates = KEYWORDS_COMPLETE[token.string]

        if @candidates.length > 0
            @index = 0
            @cm.replaceRange @candidates[@index], cursor
            @start = cursor
            @end = @cm.getCursor()
            @cm.setSelection @start, @end

    previous: -> @next_ -1

    next: -> @next_ 1

    next_: (increment) ->
        if @candidates.length > 1
            cursor = @cm.getCursor()
            @index += increment
            if @index < 0       
                @index = @candidates.length - 1 
            else if @index >= @candidates.length
                @index = 0 
            @cm.replaceRange @candidates[@index], @start, @end
            @end = @cm.getCursor()
            @cm.setSelection @start, @end