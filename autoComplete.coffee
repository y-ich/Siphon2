###
# AutoComplete for CodeMirror in CoffeeScript
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
###

# JavaScript/CoffeeScript constants
JS_KEYWORDS = [
  'true', 'false', 'null', 'this'
  'new', 'delete', 'typeof', 'in', 'instanceof'
  'return', 'throw', 'break', 'continue', 'debugger'
  'if', 'else', 'switch', 'for', 'while', 'do', 'try', 'catch', 'finally'
  'class', 'extends', 'super'
]

# CoffeeScript-only keywords.
COFFEE_KEYWORDS = ['undefined', 'then', 'unless', 'until', 'loop', 'of', 'by', 'when', 'yes', 'no', 'on', 'off']

OPERATORS_WITH_EQUAL = ['-','+','*','/','%','<','>','&','|','^','!','?','=']
OPERATORS = [
    '->', '=>', 'and', 'or', 'is', 'isnt', 'not', '&&', '||'
]
OPERATORS = OPERATORS.concat(OPERATORS_WITH_EQUAL.concat(OPERATORS_WITH_EQUAL.map((e) -> e + '='))).sort()

UTC_PROPERTIES = ['Date', 'Day', 'FullYear', 'Hours', 'Milliseconds', 'Minutes', 'Month', 'Seconds']
DATE_PROPERTIES = ['Time', 'Year'].concat UTC_PROPERTIES.reduce ((a, b) -> a.concat [b, 'UTC' + b]), []

CORE_CLASSES =
    # Arguments: ['callee', 'length']
    Array: ['length', 'concat', 'every', 'filter', 'forEach', 'indexOf', 'join', 'lastIndexOf', 'map', 'pop', 'push', 'reduce', 'reduceRight', 'reverse'
        'shift', 'slice', 'some', 'sort', 'splice', 'toLocaleString', 'toString', 'unshift']
    Boolean: ['toString', 'valueOf']
    Date: ['getTimezoneOffset', 'toDateString', 'toGMTString', 'toISOString', 'toJSON', 'toLocaleDateString', 'toLocaleString', 'toLocaleTimeString', 'toString', 'toTimeString', 'toUTCString', 'valueOf'].concat(DATE_PROPERTIES.reduce(((a, b) -> a.concat ['get' + b, 'set' + b]), [])).sort()
    Error: [] 
    EvalError: []
    Function: []
    Global: []
    JSON: []
    Math: []
    Number: []
    Object: []
    RangeError: []
    ReferenceError: []
    RegExp: []
    String: []
    SyntaxError: []
    TypeError: []
    URIError: []

KEYWORDS = JS_KEYWORDS.concat(COFFEE_KEYWORDS).sort()

KEYWORDS_COMPLETE =
    if: ['else', 'then else']
    for: ['in', 'in when', 'of', 'of when']
    try: ['catch finally', 'catch']
    class: ['extends']
    switch: ['when else', 'when', 'when then else', 'when then']

globalProperties = (e for e of window)
globalPropertiesPlusKeywords = globalProperties.concat(KEYWORDS).sort()
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