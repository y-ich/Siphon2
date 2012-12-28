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

setValue = (cm, string) ->
    cm.setValue string
    switch cm.getOption 'mode'
        when 'javascript'
            cm.siphon.variables = getDeclaredVariables string
        when 'coffeescript'
            compileCS string, {bare: on}, (data) ->
                if data.js?
                    cm.siphon.variables = getDeclaredVariables data.js
                else if data.error?
                    cm.siphon.variables = null
                    console.log data.error.message

dateString = (date) -> date.toDateString().replace(/^.*? /, '') + ' ' + date.toTimeString().replace(/GMT.*$/, '')

byteString = (n) ->
    if n < 1000
        n.toString() + 'B'
    else if n < 1000000
        Math.floor(n / 1000).toString() + 'KB'
    else if n < 1000000000
        Math.floor(n / 1000000).toString() + 'MB'
    else if n < 1000000000000
        Math.floor(n / 1000000000).toString() + 'GB'

getExtension = (path) -> if /\./.test path then path.replace /^.*\./, '' else ''

compareString = (str1, str2) ->
    if str1 > str2
        1
    else if str1 < str2
        -1
    else
        0

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
        onBlur: newCodeMirror.onBlur
        onChange: newCodeMirror.onChange
        onCursorActivity: newCodeMirror.onCursorActivity
        onFocus: newCodeMirror.onFocus
        onKeyEvent: newCodeMirror.onKeyEvent
        theme: 'blackboard'
    options ?= {}
    options[key] ?= value for key, value of defaultOptions
    options.onGutterClick = foldFunction options.mode
    result = CodeMirror $('#editor-pane')[0], options
    $wrapper = $(result.getWrapperElement())
    $wrapper.attr 'id', id
    $wrapper.addClass 'tab-pane'
    result.siphon =
        title: title
    result

newCodeMirror.onBlur = ->
    $('#key-extension').css 'display', ''
    scrollTo 0, 0 if touchDevice

newCodeMirror.onChange = (cm, change) ->
    cm.setLineClass cm.siphon.error, null, null if cm.siphon.error?
    cm.siphon.error = null

    if not cm.siphon.autoComplete? and change.text.length == 1 and change.text[0].length == 1
        # I regard change.text[0].length == 1 as key type, change.text[0].length == 0 as delete, change.text[0].length > 1 as paste.
        # I don't know the case change.text.length > 1
        cm.siphon.autoComplete = new AutoComplete cm

    # auto save
    clearTimeout cm.siphon.timer if cm.siphon.timer?
    cm.siphon.timer = setTimeout (->
            saveBuffer cm
            cm.siphon.timer = null
        ), config.autoSaveTime
newCodeMirror.timerId = null

newCodeMirror.onCursorActivity = ->
    setTimeout (-> scrollTo 0, if isPortrait() then 0 else $('#header').outerHeight(true)), 0 # restore position against auto scroll of mobile safari

newCodeMirror.onFocus = ->
    $('#key-extension').css 'display', 'block'
    if touchDevice
        $('#key-extension').css 'bottom', "#{footerHeight config}px"
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
        title: cm.siphon['dropbox-stat']?.name ? cm.siphon.title
        text: cm.getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join ' ')
        dropbox: cm.siphon['dropbox-stat'] ? null

getList = (path) ->
    spinner.spin document.body
    dropbox.readdir path, null, (error, names, stat, stats) ->
        spinner.stop()
        if error
            showError error
        else
            makeFileList stats, config.fileList.order, config.fileList.direction

makeFileList = (stats, order, direction) ->
    ITEMS =
        image: (stat) -> "<td><img src=\"img/dropbox-api-icons/16x16/#{stat.typeIcon}.gif\"></td>"
        name: (stat) -> "<td>#{stat.name}</td>"
        date: (stat) -> "<td>#{dateString stat.modifiedAt}</td>"
        size: (stat) -> "<td style=\"text-align: right;\">#{byteString stat.size}</td>"
        kind: (stat) -> "<td>#{if stat.isFile then getExtension stat.name else 'folder'}</td>"
    $table = $('#download-modal table')
    if stats?
        $table.data 'dropbox', stats
    else
        stats = $table.data 'dropbox'
    $table.children().remove()
    
    th = (key) -> "<th#{if order is key then " class=\"#{direction}\"" else ''}><span>#{key}</span></th>"
    $table.append "<tr>#{Object.keys(ITEMS).map(th).join('')}</tr>"
            
    stats = stats.sort (a, b) ->
        result = switch order
            when 'name'
                compareString a.name, b.name
            when 'kind'
                compareString getExtension(a.name), getExtension(b.name)            
            when 'date'
                a.modifiedAt.getTime() - b.modifiedAt.getTime()
            when 'size'
                a.size - b.size

        result * if direction is 'ascending' then 1 else -1

    for stat in stats
        $tr = $("<tr>#{(value(stat) for key, value of ITEMS).join('')}</tr>")
        $tr.data 'dropbox-stat', stat
        $table.append $tr
    
uploadFile = ->
    $active = $('#file-tabs > li.active > a')
    cm = $active.data('editor')
    stat = cm.siphon['dropbox-stat']
    if stat?
        path = stat.path
    else
        folder = $('#download-modal .breadcrumb > li.active > a').data('path')
        oldname = cm.siphon.title ? 'untitled'
        filename = prompt "Input file name. (current folder is #{folder}.)", oldname
        return unless filename
        cm.siphon.title = filename
        mode = ext2mode getExtension filename
        cm.setOption 'mode', mode
        cm.setOption 'extraKeys', if mode is 'htmlmixed' then CodeMirror.defaults.extraKeys else null
        cm.setOption 'onGutterClick', foldFunction mode         
        $active.children('span').text filename
        path = folder + '/' + filename
    
    fileDeferred = $.Deferred()
    dropbox.writeFile path, $active.data('editor').getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join ' '), null, (error, stat) ->
        if error
            alert error
        else
            cm.siphon['dropbox-stat'] = stat
            saveBuffer cm
            localStorage.removeItem "siphon-buffer-#{oldname}"  if localStorage["siphon-buffer-#{oldname}"]?
        fileDeferred.resolve()

    compileDeferred = $.Deferred()        
    if config.compile
        switch getExtension path
            when 'coffee'
                compileCS $active.data('editor').getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join ' '), null, (data) ->
                    if data.js?
                        dropbox.writeFile path.replace(/coffee$/, 'js'), data.js, null, (error, stat) ->
                            if error
                                console.log error
                                alert error
                            compileDeferred.resolve()
                    else if data.error?
                        parse = data.error.message.match /Parse error on line (\d+): (.*)$/
                        if parse?
                            line = parseInt(parse[1]) - 1
                            cm.setLineClass line, 'cm-error', null
                            cm.siphon.error = line
                        alert data.error.message
                        compileDeferred.resolve()
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
    options =
        mode: mode
        tabSize: config.tabSize
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

isPortrait = -> (orientation ? 0) % 180 == 0


updateEditor = ($tabAnchor, name, content) ->    
    $tabAnchor.children('span').text name
    cm = $tabAnchor.data 'editor'
    cm.siphon.title = name
    mode = ext2mode getExtension name
    cm.setOption 'mode', mode
    cm.setOption 'extraKeys', if mode is 'htmlmixed' then CodeMirror.defaults.extraKeys else null
    cm.setOption 'onGutterClick', foldFunction mode
    setValue cm, content
    cm
#
# initialize functions
#
       
restoreConfig = ->
    defaultConfig =
        keyboard: 'normal'
        compile: false
        dropbox:
            sandbox: true
            currentFolder: '/'
        autoSaveTime: 10000
        fileList:
            order: 'name'
            direction: 'ascending'
        tabSize: 4
    config = JSON.parse localStorage['siphon-config'] ? '{}'
    for key, value of defaultConfig
        config[key] ?= value

    $("#setting input[name=\"tab-size\"]").val config.tabSize.toString()
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

restoreBuffer = ->
    for key, value of localStorage when /^siphon-buffer/.test key
        buffer = JSON.parse value
        cm = newTabAndEditor buffer.title, ext2mode getExtension buffer.title
        setValue cm, buffer.text
        cm.siphon['dropbox-stat'] = buffer.dropbox if buffer.dropbox?
    
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

    for e in $('#key-extension') # removed .navbar for a work around for dropdown menu
        new NoClickDelay e, false

initializeEventHandlers = ->
    window.addEventListener 'orientationchange', (->
            $('#key-extension').css 'bottom', "#{footerHeight config}px"
            if isPortrait()
                $('.tabbable').removeClass 'tabs-left'
            else
                $('.tabbable').addClass 'tabs-left'
            scrollTo 0, if not isPortrait() and $('CodeMirror :focus').length > 0 then $('#header').outerHeight(true) else 0
        ), false

    window.addEventListener 'resize', (-> $('#file-tabs > li.active > a').data('editor').refresh()), false
    
    $('#plus-editor').on 'touchstart', -> scrollTo 0, 0 # work around dropdown menu bug. When scrollTop is not 0, you can not touch correctly.
    $('a.new-tab-type').on 'click', ->
        newTabAndEditor 'untitled', ext2mode $(this).text().toLowerCase()
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
                updateEditor $active, filename, reader.result
            else
                cm = newTabAndEditor filename, ext2mode getExtension filename
                setValue cm, reader.result
                
        reader.readAsText event.target.files[0]

    $('#file-tabs').on 'shown', 'a[data-toggle="tab"]', ->
        console.log 'shown'
        $(this).data('editor').refresh()

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
        if not stat?
            return
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
                        cm = $(e).data 'editor'
                        setValue cm, string
                        cm.siphon['dropbox-stat'] = stat
                else
                    $active = $('#file-tabs > li.active > a')
                    if $active.data('editor').getValue() is '' and $active.children('span').text() is 'untitled'
                        cm = updateEditor $active, stat.name, string
                    else
                        cm = newTabAndEditor stat.name, ext2mode getExtension stat.name
                        $active = $('#file-tabs > li.active > a')
                        setValue cm, string
                    cm.siphon['dropbox-stat'] = stat
                    saveBuffer cm
                    console.log 'saved'
                spinner.stop()
            spinner.spin document.body
        

    $('#upload').on 'click', ->
        uploadFile()

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
        config.tabSize = parseInt $('#setting input[name="tab-size"]').val()
        for e in $('#file-tabs > li:not(.dropdown) > a')
            $(e).data('editor').setOption 'tabSize', config.tabSize
        localStorage['siphon-config'] = JSON.stringify config
    
    (->
        searchCursor = null
        query = null
        find = (method) ->
            if not searchCursor?
                cm = $('#file-tabs > .active > a').data 'editor'
                query = $('#search > input[name="query"]').val()
                searchCursor = cm.getSearchCursor query, cm.getCursor(), false                
            if searchCursor[method]()
                searchCursor.cm.setSelection searchCursor.from(), searchCursor.to()
                pos = searchCursor.cm.cursorCoords true, 'local'
                searchCursor.cm.scrollTo 0, pos.y - ($(searchCursor.cm.getScrollerElement()).height() -  keyboardHeight(config)) / 2
            else
                alert "No more \"#{query}\""
        $('#search').on 'change', -> searchCursor = null            
        $('#search').on 'submit', ->
            find 'findNext'
            false
        $('#search-backward').on 'click', -> find 'findPrevious'
        $('#search-forward').on 'click', -> find 'findNext'
    )()

    $('.key').on (if touchDevice then 'touchstart' else 'mousedown'), -> fireKeyEvent 'keydown', $(this).data('identifier')
    
    $('.key').on (if touchDevice then 'touchend' else 'mouseup'), -> fireKeyEvent 'keyup', $(this).data('identifier')

    $('#undo').on 'click', ->
        $('#file-tabs > li.active > a').data('editor').undo()

    $('#eval, #previous-button, #next-button').on 'mousedown', (event) -> event.preventDefault()
        

    $('#eval').on 'click', ->
        cm = $('#file-tabs > li.active > a').data 'editor'
        mode = cm.getOption 'mode'
        return unless mode is 'coffeescript' or mode is 'javascript'

        if not cm.somethingSelected()
            line = cm.getCursor().line
            cm.setSelection { line: line, ch: 0 }, { line: line, ch: cm.getLine(line).length}
        source = cm.getSelection()

        switch cm.getOption 'mode'
            when 'coffeescript'
                compileCS source, {bare: on}, (data) ->
                    if data.js?
                        try
                            result = eval data.js
                        catch error
                            result = error.message
                    else if data.error?
                        result = data.error.message
                    cm.replaceSelection result.toString()
            when 'javascript'
                try
                    result = eval source
                catch error
                    result = error.message
                cm.replaceSelection result.toString()
            
    $('#previous-button').on 'click', ->
        cm = $('#file-tabs > li.active > a').data('editor')
        cm.siphon.autoComplete?.previous()
        cm.focus()
        
    $('#next-button').on 'click', ->
        cm = $('#file-tabs > li.active > a').data('editor')
        cm.siphon.autoComplete?.next()
        cm.focus()
        
    $('#download-modal table'). on 'click', 'tr > th:not(:first)', ->
        $this = $(this)
        if $this.hasClass 'ascending'
            config.fileList.direction = 'descending'
        else if $this.hasClass 'descending'
            config.fileList.direction = 'ascending'
        else
            config.fileList.order = $this.children('span').text()
            config.fileList.direction = 'ascending'
        makeFileList null, config.fileList.order, config.fileList.direction

        
#
# main
#

unless isPortrait()
    $('.tabbable').addClass 'tabs-left' 

$('#soft-key').css 'display', 'block' if touchDevice
$('#import').addClass 'disabled' if /iPad|iPhone/.test navigator.userAgent
restoreConfig()
newTabAndEditor 'untitled', 'coffeescript'
restoreBuffer()
initializeDropbox()
initializeEventHandlers()
scrollTo 0, 0 # reset previous scroll position
