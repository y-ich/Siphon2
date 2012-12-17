###
# (C) 2012 New 3 Rs (ICHIKAWA, Yuji)
###

API_KEY_FULL = 'iHaFSTo2hqA=|lC0ziIxBPWaNm/DX+ztl4p1RdqPQI2FAwofDEmJsiQ=='
API_KEY_SANDBOX = 'CCdH9UReG2A=|k8J5QIsJKiBxs2tvP5WxPZ5jhjIhJ1GS0sbPdv3xxw=='

#
# function definitions
#

newCodeMirror = (tabAnchor, options, active) ->
    defaultOptions =
        lineNumbers: true
        lineWrapping: true
        onBlur: ->
            $('.navbar-fixed-bottom').css 'bottom', ''           
        # CodeMirror 2
        onChange: (cm, change)->
            if not cm.siphon.autoComplete? and change.text.length == 1 and change.text[0].length == 1
                cm.siphon.autoComplete = new AutoComplete cm, change.text[change.text.length - 1]
                cm.siphon.autoComplete.complete cm
        # end of CodeMirror 2
        onFocus: ->
            $('.navbar-fixed-bottom').css 'bottom', "#{keyboardHeight config}px"
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

getList = (path) ->
    $table = $('#download-modal table')
    spinner.spin document.body
    dropbox.readdir path, null, (error, names, stat, stats) ->
        spinner.stop()
        $table.children().remove()
        if error
            alert error
        else
            for e in stats
                $tr = $("<tr><td>#{e.name}</td></tr>")
                $tr.data 'dropbox', e
                $table.append $tr

uploadFile = ->
    $active = $('#file-tabs > li.active > a')
    stat = $active.data 'dropbox'
    if stat?
        path = stat.path
    else
        folder = $('#download-modal .breadcrumb > li.active > a').data('path')
        filename = prompt "Input file name. (current folder is #{folder}.)", $active.text()
        return unless filename
        path = folder + '/' + filename
    
    fileDeferred = $.Deferred()
    dropbox.writeFile path, $active.data('editor').getValue(), null, (error, stat) ->
        if error
            alert error
        else
            $active.data 'dropbox', stat
        fileDeferred.resolve()

    compileDeferred = $.Deferred()        
    if config.compile
        switch path.replace /^.*\./, ''
            when 'coffee'
                dropbox.writeFile path.replace(/coffee$/, 'js'), CoffeeScript.compile($active.data('editor').getValue()), null, (error, stat) ->
                    if error
                        alert error
                    compileDeferred.resolve()
            when 'less'
                lessParser.parse $active.data('editor').getValue(), (error, tree) ->
                    console.log error
                    dropbox.writeFile path.replace(/less$/, 'css'), tree.toCSS(), null, (error, stat) ->
                        if error
                            alert error
                        compileDeferred.resolve()                
            else
                compileDeferred.resolve()
    else
        compileDeferred.resolve()

    $.when(fileDeferred, compileDeferred).then -> spinner.stop()
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

keyboardHeight = (config) ->
    IPAD_KEYBOARD_HEIGHT =
        portrait: 307
        landscape: 395
    IPAD_SPLIT_KEYBOARD_HEIGHT =
        portrait: 283
        landscape: 277

    (switch config.keyboard
        when 'normal' then IPAD_KEYBOARD_HEIGHT
        when 'split' then IPAD_SPLIT_KEYBOARD_HEIGHT
        when 'user-defined' then config['user-defined-keyboard'])[if orientation % 180 == 0 then 'portrait' else 'landscape']

newTabAndEditor = (title = 'untitled', mode) ->
    $('#file-tabs > li.active, #editor-pane > *').removeClass 'active'
    newTabAndEditor.num += 1
    id = "cm#{newTabAndEditor.num}"
    $tab = $("""
        <li class="active">
            <a href="##{id}" data-toggle="tab">
                <button class="close" type="button">&times;</button>
                <span>#{title}</span>
            </a>
        </li>
        """)
    $('#file-tabs > li.dropdown').before $tab
    newCodeMirror $tab.children('a')[0], switch mode
            when 'html' then mode: 'text/html'
            when 'css' then { extraKeys: null, mode: 'css' }
            when 'less' then { extraKyes: null, mode: 'less' }
            when 'javascript' then { extraKeys: null, mode: 'javascript' }
            when 'cofeescript' then { extraKeys: null, mode: 'coffeescript' }
            else null
        , true
newTabAndEditor.num = 0

#
# main
#

touchDevice =
    try
        document.createEvent 'TouchEvent'
        true
    catch error
        false

$('#file').css 'display', 'none' if /iPhone|iPad/.test navigator.userAgent
$('#soft-key').css 'display', 'none' unless touchDevice

config = JSON.parse localStorage['siphon-config'] ? '{}'
config.keyboard ?= 'normal'
config.sandbox ?= true
config.compile ?= false
$("#setting input[name=\"keyboard\"][value=\"#{config.keyboard}\"]").attr 'checked', ''
if config['user-defined-keyboard']?
    $('#setting input[name="keyboard-height-portrait"]').value config['user-defined-keyboard'].portrait
    $('#setting input[name="keyboard-height-landscape"]').value config['user-defined-keyboard'].landscape
$("#setting input[name=\"sandbox\"][value=\"#{config.sandbox.toString()}\"]").attr 'checked', ''
$("#setting input[name=\"compile\"]").attr 'checked', '' if config.compile

spinner = new Spinner(color: '#fff')

dropbox = new Dropbox.Client
    key: if config.sandbox then API_KEY_SANDBOX else API_KEY_FULL
    sandbox: config.sandbox
dropbox.authDriver new Dropbox.Drivers.Redirect rememberUser: true
if not /not_approved=true/.test location.toString() # if redirect result is not user reject
    for key, value of localStorage
        try
            if /^dropbox-auth/.test(key) and JSON.parse(value).key is dropbox.oauth.key
                $('#dropbox').button 'loading'
                dropbox.authenticate (error, client) ->
                    if error
                        showError error 
                        $('#dropbox').button 'reset'
                    else
                        $('#dropbox').button 'signout'
                break
        catch error
            console.log error

lessParser = new less.Parser()

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
    newTabAndEditor 'untitled', $(this).text().toLowerCase()
    false # prevent default action

$('#file').on 'click', -> $('#file-picker').click()
$('#file-picker').on 'change', (event) ->
    fileName = this.value.replace /^.*\\/, ''
    reader = new FileReader()
    reader.onload = ->
        $active = $('#file-tabs > li.active > a')
        cm = $active.data 'editor'
        if cm.getValue() is '' and $active.children('span').text() is 'untitled'
            $active.children('span').text fileName
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

$('#file-tabs').on 'click', 'button.close', ->
    $this = $(this)
    $tabAnchor = $this.parent()
    if confirm "Do you really delete \"#{$tabAnchor.children('span').text()}\" locally?" # slice removes close button "x"
        if $('#file-tabs > li:not(.dropdown)').length > 1
            cm = $tabAnchor.data 'editor'
            $tabAnchor.data 'editor', null
            $tabAnchor.parent().remove()
            $(cm.getWrapperElement()).remove()
            $first = $('#file-tabs > li:first-child')
            $first.addClass 'active'
            cm = $first.children('a').data 'editor'
            $(cm.getWrapperElement().parentElement).addClass 'active'
        else
            $tabAnchor.children('span').text 'untitled'
            cm = $tabAnchor.data('editor')
            cm.setValue ''
        cm.focus()

$('#download-button').on 'click', ->
    getList $('#download-modal .breadcrumb > li.active > a').data('path')

$('#download-modal .breadcrumb').on 'click', 'li:not(.active) > a', ->
    $this = $(this)
    $this.parent().nextUntil().remove()
    $this.parent().addClass 'active'
    getList $this.data 'path'
    false # prevent default
    
$('#download-modal table').on 'click', 'tr', ->
    $this =$(this)
    stat = $this.data('dropbox')
    if stat.isFile
        $('#download-modal table tr').removeClass 'info'
        $this.addClass 'info'
    else if stat.isFolder
        $('#download-modal .breadcrumb > li.active').removeClass 'active'
        $('#download-modal .breadcrumb').append $("""
            <li class="active">
                <span class="divider">/</span>
                <a href="#" data-path="#{stat.path}"}>#{stat.name}</a>
            </li>
            """)
        getList stat.path
    
$('#open').on 'click', ->
    stat = $('#download-modal table tr.info').data('dropbox')
    if stat?.isFile
        dropbox.readFile stat.path, null, (error, string, stat) ->
            $active = $('#file-tabs > li.active > a')
            cm = $active.data 'editor'
            extension = stat.name.replace /^.*\./, ''
            if cm.getValue() is '' and $active.children('span').text() is 'untitled'
                $active.children('span').text stat.name
                cm.setOption 'mode', switch extension
                    when 'html' then 'text/html'
                    when 'css' then 'css'
                    when 'js' then 'javascript'
                    when 'coffee' then 'coffeescript'
                    when 'less' then 'less'
                    else null
                cm.setOption 'extraKeys', null unless extension is 'html'
            else
                cm = newTabAndEditor stat.name, switch extension
                        when 'js' then 'javascript'
                        when 'coffee' then 'coffeescript'
                        else extension
                $active = $('#file-tabs > li.active > a')
            cm.setValue string
            $active.data 'dropbox', stat
                
            spinner.stop()
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

$('#dropbox').on 'click', ->
    $this = $(this)
    if $this.text() is 'sign-in'
        $this.button 'loading'
        dropbox.reset()
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
                alart 'pass'
            else
                $this.button 'reset'
            
    spinner.spin document.body


window.addEventListener 'orientationchange', (->
        if $('.navbar-fixed-bottom').css('bottom') isnt '0px'
            $('.navbar-fixed-bottom').css 'bottom', "#{keyboardHeight config}px"
    ), false

window.addEventListener 'scroll', (->
    if (document.body.scrollLeft != 0 or document.body.scrollTop != 0) and $('.open').length == 0 then scrollTo 0, 0
), false

$('#save-setting').on 'click', ->
    config.keyboard = $('#setting input[name="keyboard"]:checked').val()
    if config.keyboard is 'user-defined'
        config['user-defined-keyboard'] =
            portrait: parseInt $('#setting input[name="keyboard-height-portrait"]').val()
            landscape: parseInt $('#setting input[name="keyboard-height-landscape"]').val()
    if config.sandbox.toString() isnt $('#setting input[name="sandbox"]:checked').val()
        config.sandbox = not config.sandbox
    if (typeof $('#setting input[name="compile"]').attr('checked') isnt 'undefined') isnt config.compile
        config.compile = not config.compile
    localStorage['siphon-config'] = JSON.stringify config
