###
# AutoComplete for CodeMirror in CoffeeScript
# requirement: coffee-script-worker.js
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
###

#
# constants
#

# JavaScript/CoffeeScript common keywords
COMMON_KEYWORDS = ['break', 'catch', 'continue', 'debugger', 'delete', 'do', 'else', 'false', 'finally', 'for', 'if', 'in', 'instanceof', 'new',
    'null', 'return', 'switch', 'this', 'throw', 'true', 'try', 'typeof', 'while']
# JavaScript-only keywords
JS_ONLY_KEYWORDS = ['case', 'default', 'function', 'var', 'void', 'with']
# CoffeeScript-only keywords.
CS_ONLY_KEYWORDS = ['by', 'class', 'extends', 'loop', 'no', 'of', 'off', 'on', 'super', 'then', 'undefined', 'unless', 'until', 'when', 'yes']

GLOBAL_PROPERTIES = (e for e of window)

GLOBAL_PROPERTIES_PLUS_JS_KEYWORDS = GLOBAL_PROPERTIES.concat(COMMON_KEYWORDS).concat(JS_ONLY_KEYWORDS).sort()
GLOBAL_PROPERTIES_PLUS_CS_KEYWORDS = GLOBAL_PROPERTIES.concat(COMMON_KEYWORDS).concat(CS_ONLY_KEYWORDS).sort()

# statement completion for keywords
CS_KEYWORDS_ASSIST =
    class: ['extends']
    for: ['in', 'in when', 'of', 'of when']
    if: ['else', 'then else']
    switch: ['when else', 'when', 'when then else', 'when then']
    try: ['catch finally', 'catch']

JS_KEYWORDS_ASSIST =
    do: ['while ( )']
    for: ['( ; ; ) { }', '( in ) { }']
    if: ['( ) { }', '( ) { } else { }']
    switch: ['( ) { case : break; default: }']
    try: ['catch finally', 'catch']
    while: ['( )']

#
# functions
#

# compile CoffeeScript by WebWorker (coffee-script-worker.js)
# source: string
# options: options for coffeescript compiler
# callback: callback that is invoked when finish to compile
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

getDeclaredVariables = (js) ->
    IDENTIFIER = '[_A-Za-z$][_A-Za-z$0-9]*'
    IDENTIFIER_MAY_WITH_ASSIGN = IDENTIFIER + '\\s*(?:=\\s*\\S+)?'
    result = []
    regexp = new RegExp "(?:^|;)\\s*(?:for\\s*\\(\\s*)?var\\s+((?:#{IDENTIFIER_MAY_WITH_ASSIGN}\\s*,\\s*)*#{IDENTIFIER_MAY_WITH_ASSIGN})\\s*(?:;|$)", 'gm'
    while match = regexp.exec js
        result = result.concat match[1].split(/\s*,\s*/).map (e) -> e.replace /\s*=.*$/, ''
    result

csErrorLine = (error) ->
    if parse = error.message.match /Parse error on line (\d+): (.*)$/
        parseInt parse[1]
    else
        null

class AutoComplete
    constructor: (@cm) ->
        switch @cm.getOption 'mode' 
            when 'javascript'
                @globalPropertiesPlusKeywords = GLOBAL_PROPERTIES_PLUS_JS_KEYWORDS
                @keywordsAssist = JS_KEYWORDS_ASSIST
            when 'coffeescript'
                @globalPropertiesPlusKeywords = GLOBAL_PROPERTIES_PLUS_CS_KEYWORDS
                @keywordsAssist = CS_KEYWORDS_ASSIST
        
        @variables = if @cm.siphon? and @cm.siphon.variables? then @cm.siphon.variables else null # variables list that editor prepared
        @start = @cm.getCursor()
        @setCandidatesAndShowFirst_()

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

    setCandidatesAndShowFirst_: ->
        propertyChain = @getPropertyChain_()

        if propertyChain.length == 2 and /^\s+$/.test propertyChain[1].string # keyword assist
            if @keywordsAssist.hasOwnProperty propertyChain[0].string
                @candidates = @keywordsAssist[propertyChain[0].string]
        else if propertyChain.length > 1 and /^\s+$/.test(propertyChain[propertyChain.length - 1].string) and propertyChain[propertyChain.length - 2].className is 'property'
            @candicates = null
            return
        else if propertyChain.length != 0
            target = if /^(\s*|\.)$/.test propertyChain[propertyChain.length - 1].string then '' else propertyChain[propertyChain.length - 1].string
            if propertyChain.length == 1
                unless /^\s*$/.test propertyChain[0].string 
                    candidates = if @variables? then @globalPropertiesPlusKeywords.concat(@variables).sort() else @globalPropertiesPlusKeywords.sort()
            else
                try
                    value = eval "(#{propertyChain.map((e) -> e.string).join('').replace /\..*?$/, ''})" # you need () for object literal.
                    candidates = switch typeof value
                        when 'string' then Object.getOwnPropertyNames value.__proto__ # I don't need index propertes.
                        when 'undefined' then []
                        else
                            object = new Object value # wrap value for primitive type.
                            if object instanceof Array
                                Object.getOwnPropertyNames(Object.getPrototypeOf object)
                            else
                                Object.getOwnPropertyNames(Object.getPrototypeOf object).concat Object.getOwnPropertyNames(object)
                catch error
                    console.log error
                    @candidates = null
                    return
            @candidates = candidates.sort().filter((e) -> new RegExp('^' + target).test e).map (e) -> e[target.length..]
                    
        @showFirstCandidate_()

    getPropertyChain_: ->
        propertyChain = []
        pos = {}
        pos[key] = value for key, value of @start
        bracketStack = []
        breakFlag = false
        loop
            token = @cm.getTokenAt pos
            if token.className is 'property'
                propertyChain.push token
            else if token.className is 'variable' and bracketStack.length == 0
                propertyChain.push token
                breakFlag = true
            else if token.className isnt 'comment'
                switch token.string
                    when ')', '}', ']'
                        propertyChain.push token
                        bracketStack.push token.string
                    when '('
                        if bracketStack.pop() is ')'
                            propertyChain.push token
                        else
                            breakFlag = true
                    when '{'
                        if bracketStack.pop() is '}'
                            propertyChain.push token
                        else
                            breakFlag = true
                    when '['
                        if bracketStack.pop() is ']'
                            propertyChain.push token
                        else
                            breakFlag = true
                    else
                        propertyChain.push token
            if token.start > 0
                pos.ch = token.start
            else
                if pos.line > 0
                    pos.line -= 1
                    pos.ch = @cm.getLine(pos.line).length
                else
                    breakFlag = true
            break if breakFlag
        propertyChain.reverse()

    showFirstCandidate_: ->
        console.log @candidates
        if @candidates.length > 0
            @index = 0
            @cm.replaceRange @candidates[@index], @start
            @end = @cm.getCursor()
            @cm.setSelection @start, @end

# exports
window.AutoComplete = AutoComplete
window.compileCS = compileCS
window.getDeclaredVariables = getDeclaredVariables
