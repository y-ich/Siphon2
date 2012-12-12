###
# (C) 2012 New 3 Rs (ICHIKAWA, Yuji)
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

prepareTable = (id, array) ->
    rows = []
    numOfColumns = 5
    for e, i in array
        if i % numOfColumns == 0
            $tr = $('<tr></tr>')
            rows.push $tr
        $tr.append $('<td></td>').append $('<a class="token" href="#"></a>').text(e)
    $("##{id}").append rows

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

newCodeMirror = (tabAnchor, mode, active) ->        
    result = CodeMirror $('#editor-pane')[0],
        mode: mode
        lineNumbers: true
        onKeyEvent: (cm, event) ->
            switch event.type
                when 'keydown'
                    cm.siphon.autoComplete = null # reset
        theme: 'blackboard'
    $wrapper = $(result.getWrapperElement())
    $wrapper.attr 'id', "cm#{newCodeMirror.number}"
    $wrapper.addClass 'tab-pane'
    $wrapper.addClass 'active' if active
    newCodeMirror.number += 1
    result.siphon = {}
    $(tabAnchor).data 'editor', result
    CodeMirror.on result, 'change', (cm, change)->
        if change.origin is 'input'
            cm.siphon.autoComplete = new AutoComplete cm, change.text[change.text.length - 1]
            cm.siphon.autoComplete.complete cm
    result

newCodeMirror.number = 0

newCodeMirror $('#file-tabs > li.active > a')[0], 'coffeescript', true

for e in $('#previous-button, #next-button, .btn-toolbar')
    new NoClickDelay e, false

$('#previous-button, #next-button').on 'mousedown', (event) ->
    event.preventDefault()

$('#previous-button').on 'click', ->
    cm = $('#file-tabs > li.active').data('editor')
    cm.siphon.autoComplete?.previous()
    cm.focus()
        
$('#next-button').on 'click', ->
    cm = $('#file-tabs > li.active').data('editor')
    cm.siphon.autoComplete?.next()
    cm.focus()
        
$('a.new-tab-type').on 'click', ->
    $('#file-tabs > li.active, #editor-pane > *').removeClass 'active'
    num = (parseInt e.id.replace /^cm/, '' for e in $('#editor-pane > *')).reduce (a, b) -> Math.max a, b
    id = "cm#{num + 1}"
    $tab = $("<li class=\"active\"><a href=\"##{id}\" data-toggle=\"tab\">untitled</a></li>")
    $('#file-tabs > li.dropdown').before $tab
    newCodeMirror $tab.children('a')[0], switch $(this).text()
        when 'HTMl' then 'xml'
        when 'CSS' then 'css'
        when 'LESS' then 'less'
        when 'JavaScript' then 'javascript'
        when 'CofeeScript' then 'coffeescript'
        else null
    
$('#file').on 'click', -> $('#file-picker').click()
$('#file-picker').on 'change', (event) ->
    fileName = this.value.replace /^.*\\/, ''
    reader = new FileReader()
    reader.onload = ->
        $active = $('#file-tabs > li.active > a')
        cm = $active.data 'editor'
        if cm.getValue() is '' and $active.text() is 'untitled'
            $active.text fileName
            cm.setOption 'mode', switch fileName.replace /^.*\./, ''
                when 'html' then 'xml'
                when 'css' then 'css'
                when 'js' then 'javascript'
                when 'coffee' then 'coffeescript'
                when 'less' then 'less'
                else null
            cm.setValue reader.result
    reader.readAsText event.target.files[0]

$('#delete').on 'click', ->
    $active = $('#file-tabs > li.active > a')
    if confirm "Do you really delete #{$active.text()}?"
        if $('#file-tabs > li').length > 1
            cm = $active.data 'editor'
            $active.data 'editor', null
            $active.parent().remove()
            $(cm.getWrapperElement()).remove()
            $first = $('#file-tabs > li:first-child')
            $first.addClass 'active'
            cm = $first.children('a').data 'editor'
            $(cm.getWrapperElement().parentElement).addClass 'active'
        else
            $active.text 'untitled'
            cm = $active.data('editor')
            cm.setValue ''
        cm.focus()
            
downloadFile = (file, callback) ->
    accessToken = gapi.auth.getToken().access_token
    xhr = new XMLHttpRequest()
    xhr.open 'GET', file.downloadUrl
    xhr.setRequestHeader 'Authorization', 'Bearer ' + accessToken
    xhr.onload = -> callback xhr.responseText
    xhr.onerror = -> callback(null)
    xhr.send();


getList = ->
    googleDrive.getList ['.html', '.css', '.js', '.less', '.coffee'].map((e) -> "title contains '#{e}'").join(' or '), (list) ->
        for e in list
            $a = $("<a href=\"#{e.downloadUrl}\">#{e.title}</a>")
            $a.data 'resource', e
            $('#download~ul').append $("<li></li>").append $a
    
$('#download').on 'click', ->
    if not googleDrive.authorized
        googleDrive.checkAuth getList
    else
        getList()

$('#download~ul').on 'click', 'a', (event) ->
    event.preventDefault()
    file = new googleDrive.File $(this).data('resource').download (text) -> 
        $('#file-tabs > li.active > a').data('editor').setValue text
        $('#file-tabs > li.active > a').data 'file', file
        
uploadFile = ->
    $active = $('#file-tabs > li.active > a')
    file = $active.data('file')
    if file?
        file.update null, $active.data('editor').getValue()
    else
        googleDrive.File.insert $active.text(),  'text/plain', $active.data('editor').getValue()

$('#upload').on 'click', ->
    if not googleDrive.authorized
        googleDrive.checkAuth uploadFile
    else
        uploadFile()
