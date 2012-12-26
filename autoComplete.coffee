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
    constructor: (@cm) ->
        switch @cm.getOption 'mode' 
            when 'coffeescript'
                @globalPropertiesPlusKeywords = globalPropertiesPlusCSKeywords
                @keywordsAssist = CS_KEYWORDS_ASSIST
            when 'javascript'
                @globalPropertiesPlusKeywords = globalPropertiesPlusJSKeywords
                @keywordsAssist = JS_KEYWORDS_ASSIST
        
        return if @candidates?
        @candidates = []
        cursor = @cm.getCursor()

        @setCandidates_ cursor

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

    setCandidates_: (cursor) ->
        propertyChain = []
        pos = {}
        pos[key] = value for key, value of cursor
        bracketStack = []
        breakFlag = false
        loop
            token = @cm.getTokenAt pos
            if token.className is 'property'
                propertyChain.push token
            else if token.className is 'variable' and bracketStack.length == 0
                propertyChain.push token
                breakFlag = true
            else
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

        if propertyChain.length == 2 and /^\s+$/.test propertyChain[1].string # keyword assist
            if @keywordsAssist.hasOwnProperty propertyChain[0].string
                @candidates = @keywordsAssist[propertyChain[0].string]
            return
        else if propertyChain.length > 1 and /^\s+$/.test(propertyChain[propertyChain.length - 1].string) and propertyChain[propertyChain.length - 2].className is 'property'
            return
        else if propertyChain.length == 1
            candidates = if /^\s*$/.test propertyChain[0].string then [] else @globalPropertiesPlusKeywords 
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
                candidates.sort()
            catch err
                console.log err
                return
        target = if /^(\s*|\.)$/.test propertyChain[propertyChain.length - 1].string then '' else propertyChain[propertyChain.length - 1].string
        @candidates = candidates.filter((e) -> new RegExp('^' + target).test e).map (e) -> e[target.length..]

window.AutoComplete = AutoComplete
