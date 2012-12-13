###
# (C) 2012 New 3 Rs (ICHIKAWA, Yuji)
###

touchDevice =
    try
        document.createEvent 'TouchEvent'
        true
    catch error
        false

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

newCodeMirror = (tabAnchor, options, active) ->
    defaultOptions =
        lineNumbers: true
        onBlur: ->
            $('.navbar-fixed-bottom').css 'bottom', ''           
        # CodeMirror 2
        onChange: (cm, change)->
            unless cm.siphon.autoComplete?
                cm.siphon.autoComplete = new AutoComplete cm, change.text[change.text.length - 1]
                cm.siphon.autoComplete.complete cm
        # end of CodeMirror 2
        onFocus: ->
            $('.navbar-fixed-bottom').css 'bottom', keyboardHeight + 'px'
        onKeyEvent: (cm, event) ->
            switch event.type
                when 'keydown'
                    cm.siphon.autoComplete = null # reset
        theme: 'blackboard'
    options ?= {}
    options[key] ?= value for key, value of defaultOptions
    if not touchDevice
        options.onBlur = null
        options.onFocus = null
    result = CodeMirror $('#editor-pane')[0], options
    $wrapper = $(result.getWrapperElement())
    $wrapper.attr 'id', "cm#{newCodeMirror.number}"
    $wrapper.addClass 'tab-pane'
    $wrapper.addClass 'active' if active
    newCodeMirror.number += 1
    result.siphon = {}
    $(tabAnchor).data 'editor', result
    ### CodeMirror 3
    CodeMirror.on result, 'change', (cm, change)->
        if change.origin is 'input'
            cm.siphon.autoComplete = new AutoComplete cm, change.text[change.text.length - 1]
            cm.siphon.autoComplete.complete cm
    ###
    result

newCodeMirror.number = 0

getList = ->     
    spinner.spin document.body
    $('#download~ul > *').remove()
    deferreds = []
    for extension in ['.html', '.css', '.js', '.less', '.coffee']
        deferred = $.Deferred()
        deferreds.push deferred
        dropbox.findByName '', extension, null, ((deferred) ->
            (error, stats) ->
                for e in stats
                    $a = $("<a href=\"#\">#{e.path}</a>")
                    $a.data 'dropbox', e
                    $('#download~ul').append $("<li></li>").append $a
                deferred.resolve()
        )(deferred)
    $.when.apply(window, deferreds).then -> spinner.stop()

uploadFile = ->
    cloud = $('#cloud > .active').attr 'id'

    $active = $('#file-tabs > li.active > a')
    file = $active.data('file')
    if file?
        file.update null, $active.data('editor').getValue(), -> spinner.stop()
    else
        title = $active.text()
        if title is 'untitled'
            title = prompt()
            return unless title
        dropbox.writeFile title, $active.data('editor').getValue(), null, -> spinner.stop()
    spinner.spin document.body

fireKeyEvent = (type, keyIdentifier, keyCode, charCode = 0) ->
    DOM_KEY_LOCATION_STANDARD = 0
    KEY_CODES =
        'Left': 37
        'Right': 39
        'Up': 38
        'Down': 40
        'U+0009': 9
    e = document.createEvent 'KeyboardEvent'
    e.initKeyboardEvent type, true, true, window, keyIdentifier, DOM_KEY_LOCATION_STANDARD, ''
    # There is no getModifiersState method in webkit, so you have no way to know the content of modifiersList. So I use '' in the last argument.

    e.override =
        keyCode : keyCode ? KEY_CODES[keyIdentifier]
        charCode : charCode
    document.activeElement.dispatchEvent(e)

evalCS = (str) ->
    try
        jssnippet = CoffeeScript.compile str, bare : on
        result = eval jssnippet
    catch error
        result = error.message
    result
    
#
# main
#

keyboardHeight = 307

$('#file').css 'display', 'none' if /iPhone|iPad/.test navigator.userAgent

spinner = new Spinner(color: '#fff')

apiKey = 'hQovC3k4w4A=|uGAxh2R5OvngTLzgpdby+tAhTTOj2KMnaKb1r1rZvg=='
dropbox = new Dropbox.Client
    key: apiKey
    sandbox: true
dropbox.authDriver new Dropbox.Drivers.Redirect rememberUser: true
for key, value of localStorage
    try
        if /^dropbox-auth/.test(key) and JSON.parse(value).key is apiKey
            $('#dropbox').button 'loading'
            dropbox.authenticate (error, client) ->
                if error
                    showError error 
                    $('#dropbox').button 'reset'
                else
                    $('#dropbox').button 'signout'
            break
    catch error
        null

newCodeMirror $('#file-tabs > li.active > a')[0], { extraKeys: null, mode: 'coffeescript' }, true

for e in $('.navbar-fixed-bottom') # removed .navbar for a work around for dropdown menu
    new NoClickDelay e, false

$('#previous-button').on 'click', ->
    cm = $('#file-tabs > li.active > a').data('editor')
    cm.siphon.autoComplete?.previous()
    cm.focus()
        
$('#next-button').on 'click', ->
    cm = $('#file-tabs > li.active > a').data('editor')
    cm.siphon.autoComplete?.next()
    cm.focus()
        
$('a.new-tab-type').on 'click', ->
    $('#file-tabs > li.active, #editor-pane > *').removeClass 'active'
    num = (parseInt e.id.replace /^cm/, '' for e in $('#editor-pane > *')).reduce (a, b) -> Math.max a, b
    id = "cm#{num + 1}"
    $tab = $("<li class=\"active\"><a href=\"##{id}\" data-toggle=\"tab\">untitled</a></li>")
    $('#file-tabs > li.dropdown').before $tab
    newCodeMirror $tab.children('a')[0], switch $(this).text()
            when 'HTMl' then mode: 'text/html'
            when 'CSS' then { extraKeys: null, mode: 'css' }
            when 'LESS' then { extraKyes: null, mode: 'less' }
            when 'JavaScript' then { extraKeys: null, mode: 'javascript' }
            when 'CofeeScript' then { extraKeys: null, mode: 'coffeescript' }
            else null
        , true
    false # prevent default action

$('#file').on 'click', -> $('#file-picker').click()
$('#file-picker').on 'change', (event) ->
    fileName = this.value.replace /^.*\\/, ''
    reader = new FileReader()
    reader.onload = ->
        $active = $('#file-tabs > li.active > a')
        cm = $active.data 'editor'
        if cm.getValue() is '' and $active.text() is 'untitled'
            $active.text fileName
            extension = fileName.replace /^.*\./, ''
            cm.setOption 'mode', switch extension
                when 'html' then 'text/html'
                when 'css' then 'css'
                when 'js' then 'javascript'
                when 'coffee' then 'coffeescript'
                when 'less' then 'less'
                else null
            cm.setOption 'extraKeys', null unless extension is 'html'
            cm.setValue reader.result
    reader.readAsText event.target.files[0]

$('#delete').on 'click', ->
    $active = $('#file-tabs > li.active > a')
    if confirm "Do you really delete \"#{$active.text()}\" locally?"
        if $('#file-tabs > li:not(.dropdown)').length > 1
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

# Including touchstart is work around that touchstart in bootstrap dropdown return false and that prevents default actions such as triggering click event.
$('#download').on 'click touchstart', ->
    getList()

$('#download~ul').on 'click', 'a', (event) ->
    event.preventDefault()
    stat = $(this).data('dropbox')
    dropbox.readFile stat.path, null, (error, string, stat) ->
        spinner.stop()
        $('#file-tabs > li.active > a').data('editor').setValue string
        $('#file-tabs > li.active > a').data 'dropbox', stat
    spinner.spin document.body

$('#upload').on 'click', ->
    uploadFile()

$('.key').on (if touchDevice then 'touchstart' else 'mousedown'), -> fireKeyEvent 'keydown', $(this).data('identifier')
    
$('.key').on (if touchDevice then 'touchend' else 'mouseup'), -> fireKeyEvent 'keyup', $(this).data('identifier')

$('#undo').on 'click', ->
    $('#file-tabs > li.active > a').data('editor').undo()

$('#eval').on 'click', ->
    cm = $('#file-tabs > li.active > a').data('editor')
    return unless cm.getOption('mode') is 'coffeescript'
    if not cm.somethingSelected()
        line = cm.getCursor().line
        cm.setSelection { line: line, ch: 0 }, { line: line, ch: cm.getLine(line).length}
    cm.replaceSelection evalCS(cm.getSelection()).toString()

showError = (error) ->
    console.error error if (window.console)
    switch error.status
        when 401
            # If you're using dropbox.js, the only cause behind this error is that
            # the user token expired.
            # Get the user through the authentication flow again.
            null
        when 404
            # The file or folder you tried to access is not in the user's Dropbox.
            # Handling this error is specific to your application.
            null            
        when 507
            # The user is over their Dropbox quota.
            # Tell them their Dropbox is full. Refreshing the page won't help.
            null
        when 503
            # Too many API requests. Tell the user to try again later.
            # Long-term, optimize your code to use fewer API calls.
            null
        when 400
            # Bad input parameter
            null
        when 403  
            # Bad OAuth request.
            null
        when 405
            # Request method not expected
            null
        else
            # Caused by a bug in dropbox.js, in your application, or in Dropbox.
            # Tell the user an error occurred, ask them to refresh the page.
            null

$('#dropbox').on 'click', ->
    $this = $(this)
    if $this.text() is 'sign-in'
        $this.button 'loading'
        dropbox.authenticate (error, client) ->
            spinner.stop()
            if error
                showError error 
            else
                $this.button 'signout'
    else
        dropbox.signOut (error) ->
            spinner.stop()
            if error
                showError error 
            else
                $this.button 'reset'
            
    spinner.spin document.body
