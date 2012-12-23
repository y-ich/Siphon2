###
# AutoComplete for CodeMirror in CoffeeScript
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
###

# JavaScript/CoffeeScript constants
COMMON_KEYWORDS = [
    'break', 'catch', 'continue', 'debugger', 'delete', 'do', 'else', 'false', 'finally', 'for',
    'if', 'in', 'instanceof', 'new', 'null', 'return', 'switch', 'this', 'throw', 'true',
    'try', 'typeof', 'while'
]
JS_KEYWORDS = ['case', 'default', 'function', 'var', 'void', 'with']

# CoffeeScript-only keywords.
COFFEE_KEYWORDS = ['by', 'class', 'extends', 'loop', 'no', 'of', 'off', 'on', 'super', 'then', 'undefined', 'unless', 'until', 'when', 'yes']

OPERATORS_WITH_EQUAL = ['-', '+', '*', '/', '%', '<<', '>>', '>>>', '<','>','&','|','^','!', '=']
OPERATORS = ['&&', '||',  '~',]
JS_OPERATORS = ['++', '--', '===', '!==']
CS_OPERATORS = ['->', '=>', 'and', 'or', 'is', 'isnt', 'not', '?', '?=']
cs_operators = OPERATORS.concat(CS_OPERATORS).concat(OPERATORS_WITH_EQUAL.concat(OPERATORS_WITH_EQUAL.map((e) -> e + '='))).sort()
js_operators = OPERATORS.concat(JS_OPERATORS).concat(OPERATORS_WITH_EQUAL.concat(OPERATORS_WITH_EQUAL.map((e) -> e + '='))).sort()

UTC_PROPERTIES = ['Date', 'Day', 'FullYear', 'Hours', 'Milliseconds', 'Minutes', 'Month', 'Seconds']
DATE_PROPERTIES = ['Time', 'Year'].concat UTC_PROPERTIES.reduce ((a, b) -> a.concat [b, 'UTC' + b]), []

js_keywords = COMMON_KEYWORDS.concat(JS_KEYWORDS).sort()
cs_keywords = COMMON_KEYWORDS.concat(COFFEE_KEYWORDS).sort()

CS_KEYWORDS_COMPLETE =
    class: ['extends']
    for: ['in', 'in when', 'of', 'of when']
    if: ['else', 'then else']
    switch: ['when else', 'when', 'when then else', 'when then']
    try: ['catch finally', 'catch']

JS_KEYWORDS_COMPLETE =
    do: ['while ( )']
    for: ['( ; ; ) { }', '( in ) { }']
    if: ['( ) { }', '( ) { } else { }']
    switch: ['( ) { case : break; default: }']
    try: ['catch finally', 'catch']
    while: ['( )']

globalProperties = (e for e of window)
globalPropertiesPlusJSKeywords = globalProperties.concat(js_keywords).sort()
globalPropertiesPlusCSKeywords = globalProperties.concat(cs_keywords).sort()
variables = []
functions = []
classes = []
for e in globalProperties.sort()
    continue if window[e] is null or (typeof window[e] isnt 'function' and /^[A-Z]/.test e)
    if typeof window[e] is 'function'
        if /^[A-Z]/.test e
            classes.push e
        else
            functions.push e
    else if not /^[A-Z]/.test e
        variables.push e

class AutoComplete
    constructor: (@cm, text) -> @char = text.charAt text.length - 1

    complete: ->
        return if @candidates?
        @candidates = []
        cursor = @cm.getCursor()

        switch @cm.getOption 'mode'
            when 'coffeescript'
                @setCandidates_ cursor, globalPropertiesPlusCSKeywords, CS_KEYWORDS_COMPLETE
            when 'javascript'
                @setCandidates_ cursor, globalPropertiesPlusJSKeywords, JS_KEYWORDS_COMPLETE

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

    setCandidates_: (cursor, globalPropertiesPlusKeywords, keywords_complete) ->
        if /[a-zA-Z_$\.]/.test @char
            propertyChain = []
            pos = cursor
            while (token = @cm.getTokenAt pos).string.charAt(0) is '.'
                propertyChain.push token
                pos = { line: cursor.line, ch: token.start }
            propertyChain.push token
            propertyChain.reverse()
            if propertyChain.length == 1
                candidates = globalPropertiesPlusKeywords
            else
                try
                    object = eval propertyChain.map((e) -> e.string)[0..-2].join()
                    switch typeof object
                        when 'boolean', 'number', 'string'
                            candidates = Object.getOwnPropertyNames object.constructor.prototype 
                        when 'fucntion', 'object'
                            candidates = Object.getOwnPropertyNames(object).concat Object.getOwnPropertyNames(Object.getPrototypeOf object)
                        else # 'undefined'
                            candidates = []
                catch err
                    console.log err
                    candidates = []
            target = propertyChain[propertyChain.length - 1].string.replace(/^\./, '')
            @candidates = candidates.filter((e) -> new RegExp('^' + target).test e)
                                    .map (e) -> e[target.length..]
        else if @char is ' '
            token = @cm.getTokenAt { line: cursor.line, ch: cursor.ch - 1 }
            if keywords_complete.hasOwnProperty token.string
                @candidates = keywords_complete[token.string]
        
window.AutoComplete = AutoComplete
