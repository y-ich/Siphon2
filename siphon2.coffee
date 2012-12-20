###
# (C) 2012 New 3 Rs (ICHIKAWA, Yuji)
###

#
# global variables
#

API_KEY_FULL = 'iHaFSTo2hqA=|lC0ziIxBPWaNm/DX+ztl4p1RdqPQI2FAwofDEmJsiQ=='
API_KEY_SANDBOX = 'CCdH9UReG2A=|k8J5QIsJKiBxs2tvP5WxPZ5jhjIhJ1GS0sbPdv3xxw=='
touchDevice =
    try
        document.createEvent 'TouchEvent'
        true
    catch error
        false
config = null
spinner = new Spinner color: '#fff'
lessParser = new less.Parser()
dropbox = null

#
# function definitions
#

ext2mode = (str) ->
    exts =
        c: 'clike'
        cc: 'clike'
        clj: 'clojure'
        coffee: 'coffeescript'
        cpp: 'clike'
        css: 'css'
        erl: 'erlang'
        h: 'clike'
        hs: 'haskell'
        htm: 'htmlmixed'
        html: 'htmlmixed'
        hx: 'haxe'
        md: 'markdown'
        ml: 'ocaml'
        java: 'clike'
        js: 'javascript'
        less: 'less'
        lisp: 'commonlisp'
        pas: 'pascal'
        pl: 'perl'
        py: 'python'
        rb: 'ruby'
        scm: 'scheme'
        sh: 'shell'
        st: 'smalltalk'
        tex: 'stex'
    exts[str] ? str.toLowerCase()

newCodeMirror = (id, options, title) ->
    defaultOptions =
        lineNumbers: true
        lineWrapping: true
        onChange: newCodeMirror.onChange
        onKeyEvent: newCodeMirror.onKeyEvent
        theme: 'blackboard'
    options ?= {}
    options[key] ?= value for key, value of defaultOptions
    if touchDevice
        options.onBlur = newCodeMirror.onBlur
        options.onFocus = newCodeMirror.onFocus
    options.onGutterClick = foldFunction options.mode
    result = CodeMirror $('#editor-pane')[0], options
    $wrapper = $(result.getWrapperElement())
    $wrapper.attr 'id', id
    $wrapper.addClass 'tab-pane'
    result.siphon =
        title: title
    result

newCodeMirror.onBlur = ->
    $('.navbar-fixed-bottom').css 'bottom', '' # replace according to onscreen keyboard
    scrollTo 0, 0
newCodeMirror.onChange = (cm, change) ->
    if not cm.siphon.autoComplete? and change.text.length == 1 and change.text[0].length == 1
        cm.siphon.autoComplete = new AutoComplete cm, change.text[change.text.length - 1]
        cm.siphon.autoComplete.complete cm

    # auto save
    clearTimeout cm.siphon.timer if cm.siphon.timer?
    cm.siphon.timer = setTimeout (->
            saveBuffer cm
            cm.siphon.timer = null
        ), config.autoSaveTime

newCodeMirror.onFocus = ->
    $('.navbar-fixed-bottom').css 'bottom', "#{footerHeight config}px"
    setTimeout (-> scrollTo 0, if isPortrait() then 0 else $('#header').outerHeight(true)), 0 # hide header when landscape
newCodeMirror.onKeyEvent = (cm, event) ->
    switch event.type
        when 'keydown'
            cm.siphon.autoComplete = null # reset

foldFunction = (mode) ->
    switch mode
        when 'clike', 'clojure', 'haxe', 'java', 'javascript', 'commonlisp', 'css', 'less', 'scheme'
            CodeMirror.newFoldFunction CodeMirror.braceRangeFinder            
        when 'htmlmixed'
            CodeMirror.newFoldFunction CodeMirror.tagRangeFinder        
        when 'coffeescript', 'haskell', 'ocaml'
            CodeMirror.newFoldFunction CodeMirror.indentRangeFinder
        else
            null

saveBuffer = (cm) ->
    path = if cm.siphon['dropbox-stat']?
            cm.siphon['dropbox-stat'].path
        else if cm.siphon.title isnt 'untitled'
            cm.siphon.title
        else
            null
    return unless path?
    localStorage["siphon-buffer-#{path}"] = JSON.stringify
        title: cm.siphon['dropbox-stat'].name ? cm.siphon.title
        text: cm.getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join ' ')
        dropbox: cm.siphon['dropbox-stat'] ? null

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
                $tr.data 'dropbox-stat', e
                $table.append $tr

uploadFile = ->
    $active = $('#file-tabs > li.active > a')
    cm = $active.data('editor')
    stat = cm.siphon['dropbox-stat']
    if stat?
        path = stat.path
    else
        folder = $('#download-modal .breadcrumb > li.active > a').data('path')
        filename = prompt "Input file name. (current folder is #{folder}.)", cm.siphon.title ? 'untitled'
        return unless filename
        cm.siphon.title = filename
        mode = ext2mode filename.replace /^.*\./, ''
        cm.setOption 'mode', mode
        cm.setOption 'extraKeys', if mode is 'htmlmixed' then CodeMirror.defaults.extraKeys else null
        cm.setOption 'onGutterClick', foldFunction options.mode         
        $active.children('span').text filename
        path = folder + '/' + filename
    
    fileDeferred = $.Deferred()
    dropbox.writeFile path, $active.data('editor').getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join ' '), null, (error, stat) ->
        if error
            alert error
        else
            cm.siphon['dropbox-stat'] = stat
        fileDeferred.resolve()

    compileDeferred = $.Deferred()        
    if config.compile
        switch path.replace /^.*\./, ''
            when 'coffee'
                try
                    compiled = CoffeeScript.compile $active.data('editor').getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join ' ')
                    dropbox.writeFile path.replace(/coffee$/, 'js'), compiled, null, (error, stat) ->
                        if error
                            alert error
                        compileDeferred.resolve()
                catch error
                    compileDeferred.resolve()
                    alert error
            when 'less'
                lessParser.parse $active.data('editor').getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join ' '), (error, tree) ->
                    if error?
                        compileDeferred.resolve()                
                        alert "Line #{error.line}: #{error.message}"
                    else
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
            alert 'Authentication is expired. Please sign-in again.'
            $('#dropbox').button 'reset'
        when 404
            alert 'No such file or folder.'
        when 507
            alert 'Your Dropbox seems full.'
        when 503
            alert 'Dropbox seems busy. Please try again later.'
        when 400
            alert 'Bad input parameter.'
        when 403  
            alert 'Please sign-in at first.'
        when 405
            alert 'Request method not expected.'
        else
            alert 'Sorry, there seems something wrong in software.'


keyboardHeight = (config) ->
    IPAD_KEYBOARD_HEIGHT =
        portrait: 307
        landscape: 395
    IPAD_SPLIT_KEYBOARD_HEIGHT =
        portrait: 283
        landscape: 329

    (switch config.keyboard
        when 'normal' then IPAD_KEYBOARD_HEIGHT
        when 'split' then IPAD_SPLIT_KEYBOARD_HEIGHT
        when 'user-defined' then config['user-defined-keyboard'])[if isPortrait() then 'portrait' else 'landscape']

footerHeight = (config) ->
    keyboardHeight(config) - if isPortrait() then 0 else $('#header').outerHeight(true)
    
newTabAndEditor = (title = 'untitled', mode = null) ->
    $('#file-tabs > li.active, #editor-pane > .active').removeClass 'active'
    id = "cm#{newTabAndEditor.num}"
    newTabAndEditor.num += 1
    $tab = $("""
        <li class="active">
            <a href="##{id}" class="editor-anchor" data-toggle="tab">
                <button class="close" type="button">&times;</button>
                <span>#{title}</span>
            </a>
        </li>
        """)
    $('#file-tabs > li.dropdown').before $tab
    options = mode: mode
    options.extraKeys = null if mode isnt 'htmlmixed'
    cm = newCodeMirror id, options, title, true
    $tab.children('a').data 'editor', cm
    $('#editor-pane .CodeMirror').removeClass 'active'
    $(cm.getWrapperElement()).addClass 'active' 
    cm
newTabAndEditor.num = 0

# '/a/b/c' => ['', '/a', '/a/b', '/a/b/c']
ancestorFolders = (path) ->
    split = path.split '/'
    split[0..i].join '/' for e, i in split

isPortrait = -> orientation % 180 == 0
    
#
# initialize functions
#
       
restore = ->
    defaultConfig =
        keyboard: 'normal'
        compile: false
        dropbox:
            sandbox: true
            currentFolder: '/'
        autoSaveTime: 10000
    config = JSON.parse localStorage['siphon-config'] ? '{}'
    for key, value of defaultConfig
        config[key] ?= value

    for key, value of localStorage when /^siphon-buffer/.test key
        buffer = JSON.parse value
        cm = newTabAndEditor buffer.title, ext2mode buffer.title.replace /^.*\./, ''
        cm.setValue buffer.text
        cm.siphon['dropbox-stat'] = buffer.dropbox if buffer.dropbox?
    
    $("#setting input[name=\"keyboard\"][value=\"#{config.keyboard}\"]").attr 'checked', ''
    if config['user-defined-keyboard']?
        $('#setting input[name="keyboard-height-portrait"]').value config['user-defined-keyboard'].portrait
        $('#setting input[name="keyboard-height-landscape"]').value config['user-defined-keyboard'].landscape
    $("#setting input[name=\"sandbox\"][value=\"#{config.dropbox.sandbox.toString()}\"]").attr 'checked', ''
    $("#setting input[name=\"compile\"]").attr 'checked', '' if config.compile
    for e, i in ancestorFolders config.dropbox.currentFolder
        if i == 0
            $('#download-modal .breadcrumb').append '<li><a href="#" data-path="/">Home</a></li>'
        else
            name = e.replace /^.*\//, ''
            $('#download-modal .breadcrumb').append """
                <li>
                    <span class="divider">/</span>
                    <a href="#" data-path="#{e}">#{name}</a>
                </li>
                """
    $('#download-modal .breadcrumb > li:last-child').addClass 'active'

initializeDropbox = ->
    dropbox = new Dropbox.Client
        key: if config.dropbox.sandbox then API_KEY_SANDBOX else API_KEY_FULL
        sandbox: config.dropbox.sandbox
    dropbox.authDriver new Dropbox.Drivers.Redirect rememberUser: true
    if not /not_approved=true/.test location.toString() # if redirect result is not user reject
        try
            for key, value of localStorage when /^dropbox-auth/.test(key) and JSON.parse(value).key is dropbox.oauth.key
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

    for e in $('.navbar-fixed-bottom') # removed .navbar for a work around for dropdown menu
        new NoClickDelay e, false

initializeEventHandlers = ->
    window.addEventListener 'orientationchange', (->
            if $('.navbar-fixed-bottom').css('bottom') isnt '0px'
                $('.navbar-fixed-bottom').css 'bottom', "#{footerHeight config}px"
            scrollTo 0, if isPortrait() then 0 else $('#header').outerHeight(true)
        ), false

    ###
    window.addEventListener 'scroll', (->
        if (document.body.scrollLeft != 0 or document.body.scrollTop != 0) and $('.open').length == 0 then scrollTo 0, 0
    ), false
    ###
    
    $('#previous-button').on 'click', ->
        cm = $('#file-tabs > li.active > a').data('editor')
        cm.siphon.autoComplete?.previous()
        cm.focus()
        
    $('#next-button').on 'click', ->
        cm = $('#file-tabs > li.active > a').data('editor')
        cm.siphon.autoComplete?.next()
        cm.focus()
        
    $('#plus-editor').on 'touchstart', -> scrollTo 0, 0 # work around dropdown menu bug. When scrollTop is not 0, you can not touch correctly.
    $('a.new-tab-type').on 'click', ->
        newTabAndEditor 'untitled', $(this).text().toLowerCase()
        $(this).parent().parent().prev().dropdown 'toggle'
        false # prevent default action

    $('#import').on 'click', ->
        return if $(this).hasClass 'disabled'
        $('#file-picker').click()
    $('#file-picker').on 'change', (event) ->
        filename = this.value.replace /^.*\\/, ''
        reader = new FileReader()
        reader.onload = ->
            $active = $('#file-tabs > li.active > a')
            cm = $active.data 'editor'
            if cm.getValue() is '' and $active.children('span').text() is 'untitled'
                $active.children('span').text filename
                mode = ext2mode filename.replace /^.*\./, ''
                cm.setOption 'mode', mode
                cm.setOption 'extraKeys', if mode is 'htmlmixed' then CodeMirror.defaults.extraKeys else null
                cm.setOption 'onGutterClick', foldFunction mode     
                cm.setValue reader.result
        reader.readAsText event.target.files[0]

    $('#file-tabs').on 'click', 'button.close', ->
        $this = $(this)
        $tabAnchor = $this.parent()
        if confirm "Do you really delete \"#{$tabAnchor.children('span').text()}\" locally?" # slice removes close button "x"
            cm = $tabAnchor.data 'editor'
            clearTimeout cm.siphon.timer if cm.siphon.timer?
            cm.siphon.timer = null
            if cm.siphon['dropbox-stat']?
                localStorage.removeItem "siphon-buffer-#{cm.siphon['dropbox-stat'].path}"
            else if $tabAnchor.children('span').text() isnt 'untitled'
                localStorage.removeItem "siphon-buffer-#{$tabAnchor.children('span').text()}"
            if $('#file-tabs > li:not(.dropdown)').length > 1
                $tabAnchor.data 'editor', null
                $tabAnchor.parent().remove()
                $(cm.getWrapperElement()).remove()
                $first = $('#file-tabs > li:first-child')
                $first.addClass 'active'
                cm = $first.children('a').data 'editor'
                $(cm.getWrapperElement()).addClass 'active'
            else
                $tabAnchor.children('span').text 'untitled'
                cm.siphon['dropbox-stat'] = null
                cm.setValue ''
            cm.focus()

    $('#download-button').on 'click', ->
        getList config.dropbox.currentFolder

    $('#download-modal .breadcrumb').on 'click', 'li:not(.active) > a', ->
        $this = $(this)
        $this.parent().nextUntil().remove()
        $this.parent().addClass 'active'
        path = $this.data 'path'
        getList path
        config.dropbox.currentFolder = path
        localStorage['siphon-config'] = JSON.stringify config
        false # prevent default
    
    $('#download-modal table').on 'click', 'tr', ->
        $this =$(this)
        stat = $this.data('dropbox-stat')
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
            config.dropbox.currentFolder = stat.path
            localStorage['siphon-config'] = JSON.stringify config
    
    $('#open').on 'click', ->
        stat = $('#download-modal table tr.info').data('dropbox-stat')
        if stat?.isFile
            $tabs = $('#file-tabs > li > a.editor-anchor').filter -> $(this).data('editor').siphon['dropbox-stat']?.path is stat.path
            $tabs = null if $tabs.length > 0 and
                not confirm "There is a buffer editing. Do you want to discard a content of the buffer and update to the server's?"
            dropbox.readFile stat.path, null, (error, string, stat) ->
                if $tabs? and $tabs.length > 0
                    for e in $tabs
                        $(e).trigger 'click' # You need an editor to be active in order to render successfully when setValue.
                        $(e).data('editor').setValue string
                        $(e).data('editor').siphon['dropbox-stat'] = stat
                else
                    $active = $('#file-tabs > li.active > a')
                    cm = $active.data 'editor'
                    extension = stat.name.replace /^.*\./, ''
                    if cm.getValue() is '' and $active.children('span').text() is 'untitled'
                        $active.children('span').text stat.name
                        cm.setOption 'mode', ext2mode extension
                        cm.setOption 'extraKeys', null unless extension is 'htmlmixed'
                        cm.setOption 'onGutterClick', foldFunction cm.getOption 'mode'     
                    else
                        cm = newTabAndEditor stat.name, ext2mode extension
                        $active = $('#file-tabs > li.active > a')
                    cm.setValue string
                    cm.siphon['dropbox-stat'] = stat
                    saveBuffer cm
                    console.log 'saved'
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

    $('#save-setting').on 'click', ->
        config.keyboard = $('#setting input[name="keyboard"]:checked').val()
        if config.keyboard is 'user-defined'
            config['user-defined-keyboard'] =
                portrait: parseInt $('#setting input[name="keyboard-height-portrait"]').val()
                landscape: parseInt $('#setting input[name="keyboard-height-landscape"]').val()
        if config.dropbox.sandbox.toString() isnt $('#setting input[name="sandbox"]:checked').val()
            config.dropbox.sandbox = not config.dropbox.sandbox
        if (typeof $('#setting input[name="compile"]').attr('checked') isnt 'undefined') isnt config.compile
            config.compile = not config.compile
        localStorage['siphon-config'] = JSON.stringify config
    
    (->
        searchCursor = null
        query = null
        $('#search').on 'submit', (e)->
            cm = $('#file-tabs > .active > a').data 'editor'
            query = $('#search > input[name="query"]').val()
            searchCursor = cm.getSearchCursor query, cm.getCursor(), false
            if searchCursor.findNext()
                cm.setSelection searchCursor.from(), searchCursor.to()
            else
                alert "No more \"#{query}\""
            false
        find = (method) ->
            if searchCursor[method]()
                searchCursor.cm.setSelection searchCursor.from(), searchCursor.to()
                pos = searchCursor.cm.cursorCoords true, 'local'
                searchCursor.cm.scrollTo 0, pos.y - ($(searchCursor.cm.getScrollerElement()).height() -  keyboardHeight(config)) / 2
            else
                alert "No more \"#{query}\""
            
        $('#search-backward').on 'click', -> find 'findPrevious'
        $('#search-forward').on 'click', -> find 'findNext'
    )()
#
# main
#

scrollTo 0, 0 # reset previous scroll position
$('#soft-key').css 'display', 'block' if touchDevice

$('#import').addClass 'disabled' if /iPad|iPhone/.test navigator.userAgent

newTabAndEditor()

restore()

initializeDropbox()

initializeEventHandlers()
