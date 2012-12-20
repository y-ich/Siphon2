// Generated by CoffeeScript 1.4.0

/*
# (C) 2012 New 3 Rs (ICHIKAWA, Yuji)
*/


(function() {
  var API_KEY_FULL, API_KEY_SANDBOX, ancestorFolders, config, dropbox, evalCS, ext2mode, fireKeyEvent, getList, initializeDropbox, initializeEventHandlers, keyboardHeight, lessParser, newCodeMirror, newTabAndEditor, restore, showError, spinner, touchDevice, uploadFile;

  API_KEY_FULL = 'iHaFSTo2hqA=|lC0ziIxBPWaNm/DX+ztl4p1RdqPQI2FAwofDEmJsiQ==';

  API_KEY_SANDBOX = 'CCdH9UReG2A=|k8J5QIsJKiBxs2tvP5WxPZ5jhjIhJ1GS0sbPdv3xxw==';

  touchDevice = (function() {
    try {
      document.createEvent('TouchEvent');
      return true;
    } catch (error) {
      return false;
    }
  })();

  config = null;

  spinner = new Spinner({
    color: '#fff'
  });

  lessParser = new less.Parser();

  dropbox = null;

  ext2mode = function(str) {
    var exts, _ref;
    exts = {
      c: 'clike',
      cc: 'clike',
      clj: 'clojure',
      coffee: 'coffeescript',
      cpp: 'clike',
      css: 'css',
      erl: 'erlang',
      h: 'clike',
      hs: 'haskell',
      htm: 'htmlmixed',
      html: 'htmlmixed',
      hx: 'haxe',
      md: 'markdown',
      ml: 'ocaml',
      java: 'clike',
      js: 'javascript',
      less: 'less',
      lisp: 'commonlisp',
      pas: 'pascal',
      pl: 'perl',
      py: 'python',
      rb: 'ruby',
      scm: 'scheme',
      sh: 'shell',
      st: 'smalltalk',
      tex: 'stex'
    };
    return (_ref = exts[str]) != null ? _ref : str.toLowerCase();
  };

  newCodeMirror = function(id, options, title, active) {
    var $wrapper, defaultOptions, key, result, value, _ref;
    if (title == null) {
      title = null;
    }
    if (active == null) {
      active = false;
    }
    defaultOptions = {
      lineNumbers: true,
      lineWrapping: true,
      onChange: newCodeMirror.onChange,
      onKeyEvent: newCodeMirror.onKeyEvent,
      theme: 'blackboard'
    };
    if (options == null) {
      options = {};
    }
    for (key in defaultOptions) {
      value = defaultOptions[key];
      if ((_ref = options[key]) == null) {
        options[key] = value;
      }
    }
    if (touchDevice) {
      options.onBlur = newCodeMirror.onBlur;
      options.onFocus = newCodeMirror.onFocus;
    }
    options.onGutterClick = (function() {
      switch (options.mode) {
        case 'clike':
        case 'clojure':
        case 'haxe':
        case 'java':
        case 'javascript':
        case 'commonlisp':
        case 'css':
        case 'less':
        case 'scheme':
          return CodeMirror.newFoldFunction(CodeMirror.braceRangeFinder);
        case 'htmlmixed':
          return CodeMirror.newFoldFunction(CodeMirror.tagRangeFinder);
        case 'coffeescript':
        case 'haskell':
        case 'ocaml':
          return CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder);
        default:
          return null;
      }
    })();
    result = CodeMirror($('#editor-pane')[0], options);
    $wrapper = $(result.getWrapperElement());
    $wrapper.attr('id', id);
    $wrapper.addClass('tab-pane');
    if (active) {
      $('#editor-pane .CodeMirror').removeClass('active');
      $wrapper.addClass('active');
    }
    result.siphon = {
      title: title
    };
    return result;
  };

  newCodeMirror.onBlur = function() {
    return $('.navbar-fixed-bottom').css('bottom', '');
  };

  newCodeMirror.onChange = function(cm, change) {
    if (cm.siphon.timer != null) {
      clearTimeout(cm.siphon.timer);
    }
    cm.siphon.timer = setTimeout((function() {
      var path, _ref;
      if (cm.siphon['dropbox-stat'] != null) {
        path = cm.siphon['dropbox-stat'].path;
      } else if (cm.siphon.title != null) {
        path = cm.siphon.title;
      } else {
        return;
      }
      localStorage["siphon-buffer-" + path] = JSON.stringify({
        title: cm.siphon.title,
        text: cm.getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join(' ')),
        dropbox: (_ref = cm.siphon['dropbox-stat']) != null ? _ref : null
      });
      return cm.siphon.timer = null;
    }), config.autoSaveTime);
    if (!(cm.siphon.autoComplete != null) && change.text.length === 1 && change.text[0].length === 1) {
      cm.siphon.autoComplete = new AutoComplete(cm, change.text[change.text.length - 1]);
      return cm.siphon.autoComplete.complete(cm);
    }
  };

  newCodeMirror.onFocus = function() {
    $('.navbar-fixed-bottom').css('bottom', "" + (keyboardHeight(config)) + "px");
    return scrollTo(0, 0);
  };

  newCodeMirror.onKeyEvent = function(cm, event) {
    switch (event.type) {
      case 'keydown':
        return cm.siphon.autoComplete = null;
    }
  };

  getList = function(path) {
    var $table;
    $table = $('#download-modal table');
    spinner.spin(document.body);
    return dropbox.readdir(path, null, function(error, names, stat, stats) {
      var $tr, e, _i, _len, _results;
      spinner.stop();
      $table.children().remove();
      if (error) {
        return alert(error);
      } else {
        _results = [];
        for (_i = 0, _len = stats.length; _i < _len; _i++) {
          e = stats[_i];
          $tr = $("<tr><td>" + e.name + "</td></tr>");
          $tr.data('dropbox-stat', e);
          _results.push($table.append($tr));
        }
        return _results;
      }
    });
  };

  uploadFile = function() {
    var $active, cm, compileDeferred, compiled, fileDeferred, filename, folder, mode, path, stat, _ref;
    $active = $('#file-tabs > li.active > a');
    cm = $active.data('editor');
    stat = cm.siphon['dropbox-stat'];
    if (stat != null) {
      path = stat.path;
    } else {
      folder = $('#download-modal .breadcrumb > li.active > a').data('path');
      filename = prompt("Input file name. (current folder is " + folder + ".)", (_ref = cm.siphon.title) != null ? _ref : 'untitled');
      if (!filename) {
        return;
      }
      cm.siphon.title = filename;
      mode = ext2mode(filename.replace(/^.*\./, ''));
      cm.setOption('mode', mode);
      cm.setOption('extraKeys', mode === 'htmlmixed' ? CodeMirror.defaults.extraKeys : null);
      cm.setOption('onGutterClick', options.mode === 'coffeescript' ? CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder) : CodeMirror.newFoldFunction(CodeMirror.braceRangeFinder));
      $active.children('span').text(filename);
      path = folder + '/' + filename;
    }
    fileDeferred = $.Deferred();
    dropbox.writeFile(path, $active.data('editor').getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join(' ')), null, function(error, stat) {
      if (error) {
        alert(error);
      } else {
        cm.siphon['dropbox-stat'] = stat;
      }
      return fileDeferred.resolve();
    });
    compileDeferred = $.Deferred();
    if (config.compile) {
      switch (path.replace(/^.*\./, '')) {
        case 'coffee':
          try {
            compiled = CoffeeScript.compile($active.data('editor').getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join(' ')));
            dropbox.writeFile(path.replace(/coffee$/, 'js'), compiled, null, function(error, stat) {
              if (error) {
                alert(error);
              }
              return compileDeferred.resolve();
            });
          } catch (error) {
            compileDeferred.resolve();
            alert(error);
          }
          break;
        case 'less':
          lessParser.parse($active.data('editor').getValue().replace(/\t/g, new Array(cm.getOption('tabSize')).join(' ')), function(error, tree) {
            if (error != null) {
              compileDeferred.resolve();
              return alert("Line " + error.line + ": " + error.message);
            } else {
              return dropbox.writeFile(path.replace(/less$/, 'css'), tree.toCSS(), null, function(error, stat) {
                if (error) {
                  alert(error);
                }
                return compileDeferred.resolve();
              });
            }
          });
          break;
        default:
          compileDeferred.resolve();
      }
    } else {
      compileDeferred.resolve();
    }
    $.when(fileDeferred, compileDeferred).then(function() {
      return spinner.stop();
    });
    return spinner.spin(document.body);
  };

  fireKeyEvent = function(type, keyIdentifier, keyCode, charCode) {
    var DOM_KEY_LOCATION_STANDARD, KEY_CODES, e;
    if (charCode == null) {
      charCode = 0;
    }
    DOM_KEY_LOCATION_STANDARD = 0;
    KEY_CODES = {
      'Left': 37,
      'Right': 39,
      'Up': 38,
      'Down': 40,
      'U+0009': 9
    };
    e = document.createEvent('KeyboardEvent');
    e.initKeyboardEvent(type, true, true, window, keyIdentifier, DOM_KEY_LOCATION_STANDARD, '');
    e.override = {
      keyCode: keyCode != null ? keyCode : KEY_CODES[keyIdentifier],
      charCode: charCode
    };
    return document.activeElement.dispatchEvent(e);
  };

  evalCS = function(str) {
    var jssnippet, result;
    try {
      jssnippet = CoffeeScript.compile(str, {
        bare: true
      });
      result = eval(jssnippet);
    } catch (error) {
      result = error.message;
    }
    return result;
  };

  showError = function(error) {
    if (window.console) {
      console.error(error);
    }
    switch (error.status) {
      case 401:
        alert('Authentication is expired. Please sign-in again.');
        return $('#dropbox').button('reset');
      case 404:
        return alert('No such file or folder.');
      case 507:
        return alert('Your Dropbox seems full.');
      case 503:
        return alert('Dropbox seems busy. Please try again later.');
      case 400:
        return alert('Bad input parameter.');
      case 403:
        return alert('Please sign-in at first.');
      case 405:
        return alert('Request method not expected.');
      default:
        return alert('Sorry, there seems something wrong in software.');
    }
  };

  keyboardHeight = function(config) {
    var IPAD_KEYBOARD_HEIGHT, IPAD_SPLIT_KEYBOARD_HEIGHT;
    IPAD_KEYBOARD_HEIGHT = {
      portrait: 307,
      landscape: 395
    };
    IPAD_SPLIT_KEYBOARD_HEIGHT = {
      portrait: 283,
      landscape: 329
    };
    return ((function() {
      switch (config.keyboard) {
        case 'normal':
          return IPAD_KEYBOARD_HEIGHT;
        case 'split':
          return IPAD_SPLIT_KEYBOARD_HEIGHT;
        case 'user-defined':
          return config['user-defined-keyboard'];
      }
    })())[orientation % 180 === 0 ? 'portrait' : 'landscape'];
  };

  newTabAndEditor = function(title, mode) {
    var $tab, cm, id, options;
    if (title == null) {
      title = 'untitled';
    }
    if (mode == null) {
      mode = null;
    }
    $('#file-tabs > li.active, #editor-pane > .active').removeClass('active');
    id = "cm" + newTabAndEditor.num;
    newTabAndEditor.num += 1;
    $tab = $("<li class=\"active\">\n    <a href=\"#" + id + "\" data-toggle=\"tab\">\n        <button class=\"close\" type=\"button\">&times;</button>\n        <span>" + title + "</span>\n    </a>\n</li>");
    $('#file-tabs > li.dropdown').before($tab);
    options = {
      mode: mode
    };
    if (mode !== 'htmlmixed') {
      options.extraKeys = null;
    }
    cm = newCodeMirror(id, options, title, true);
    $tab.children('a').data('editor', cm);
    return cm;
  };

  newTabAndEditor.num = 0;

  ancestorFolders = function(path) {
    var e, i, split, _i, _len, _results;
    split = path.split('/');
    _results = [];
    for (i = _i = 0, _len = split.length; _i < _len; i = ++_i) {
      e = split[i];
      _results.push(split.slice(0, +i + 1 || 9e9).join('/'));
    }
    return _results;
  };

  restore = function() {
    var buffer, cm, defaultConfig, e, i, key, name, value, _i, _len, _ref, _ref1, _ref2;
    defaultConfig = {
      keyboard: 'normal',
      compile: false,
      dropbox: {
        sandbox: true,
        currentFolder: '/'
      },
      autoSaveTime: 10000
    };
    config = JSON.parse((_ref = localStorage['siphon-config']) != null ? _ref : '{}');
    for (key in defaultConfig) {
      value = defaultConfig[key];
      if ((_ref1 = config[key]) == null) {
        config[key] = value;
      }
    }
    for (key in localStorage) {
      value = localStorage[key];
      if (!(/^siphon-buffer/.test(key))) {
        continue;
      }
      buffer = JSON.parse(value);
      cm = newTabAndEditor(buffer.title, ext2mode(buffer.title.replace(/^.*\./, '')));
      cm.setValue(buffer.text);
      if (buffer.dropbox != null) {
        cm.siphon['dropbox-stat'] = buffer.dropbox;
      }
    }
    $("#setting input[name=\"keyboard\"][value=\"" + config.keyboard + "\"]").attr('checked', '');
    if (config['user-defined-keyboard'] != null) {
      $('#setting input[name="keyboard-height-portrait"]').value(config['user-defined-keyboard'].portrait);
      $('#setting input[name="keyboard-height-landscape"]').value(config['user-defined-keyboard'].landscape);
    }
    $("#setting input[name=\"sandbox\"][value=\"" + (config.dropbox.sandbox.toString()) + "\"]").attr('checked', '');
    if (config.compile) {
      $("#setting input[name=\"compile\"]").attr('checked', '');
    }
    _ref2 = ancestorFolders(config.dropbox.currentFolder);
    for (i = _i = 0, _len = _ref2.length; _i < _len; i = ++_i) {
      e = _ref2[i];
      if (i === 0) {
        $('#download-modal .breadcrumb').append('<li><a href="#" data-path="/">Home</a></li>');
      } else {
        name = e.replace(/^.*\//, '');
        $('#download-modal .breadcrumb').append("<li>\n    <span class=\"divider\">/</span>\n    <a href=\"#\" data-path=\"" + e + "\">" + name + "</a>\n</li>");
      }
    }
    return $('#download-modal .breadcrumb > li:last-child').addClass('active');
  };

  initializeDropbox = function() {
    var e, key, value, _i, _len, _ref, _results;
    dropbox = new Dropbox.Client({
      key: config.dropbox.sandbox ? API_KEY_SANDBOX : API_KEY_FULL,
      sandbox: config.dropbox.sandbox
    });
    dropbox.authDriver(new Dropbox.Drivers.Redirect({
      rememberUser: true
    }));
    if (!/not_approved=true/.test(location.toString())) {
      try {
        for (key in localStorage) {
          value = localStorage[key];
          if (!(/^dropbox-auth/.test(key) && JSON.parse(value).key === dropbox.oauth.key)) {
            continue;
          }
          $('#dropbox').button('loading');
          dropbox.authenticate(function(error, client) {
            if (error) {
              showError(error);
              return $('#dropbox').button('reset');
            } else {
              return $('#dropbox').button('signout');
            }
          });
          break;
        }
      } catch (error) {
        console.log(error);
      }
    }
    _ref = $('.navbar-fixed-bottom');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      _results.push(new NoClickDelay(e, false));
    }
    return _results;
  };

  initializeEventHandlers = function() {
    window.addEventListener('orientationchange', (function() {
      if ($('.navbar-fixed-bottom').css('bottom') !== '0px') {
        return $('.navbar-fixed-bottom').css('bottom', "" + (keyboardHeight(config)) + "px");
      }
    }), false);
    window.addEventListener('scroll', (function() {
      if ((document.body.scrollLeft !== 0 || document.body.scrollTop !== 0) && $('.open').length === 0) {
        return scrollTo(0, 0);
      }
    }), false);
    $('#previous-button').on('click', function() {
      var cm, _ref;
      cm = $('#file-tabs > li.active > a').data('editor');
      if ((_ref = cm.siphon.autoComplete) != null) {
        _ref.previous();
      }
      return cm.focus();
    });
    $('#next-button').on('click', function() {
      var cm, _ref;
      cm = $('#file-tabs > li.active > a').data('editor');
      if ((_ref = cm.siphon.autoComplete) != null) {
        _ref.next();
      }
      return cm.focus();
    });
    $('a.new-tab-type').on('click', function() {
      newTabAndEditor('untitled', $(this).text().toLowerCase());
      $(this).parent().parent().prev().dropdown('toggle');
      return false;
    });
    $('#import').on('click', function() {
      return $('#file-picker').click();
    });
    $('#file-picker').on('change', function(event) {
      var filename, reader;
      filename = this.value.replace(/^.*\\/, '');
      reader = new FileReader();
      reader.onload = function() {
        var $active, cm, mode;
        $active = $('#file-tabs > li.active > a');
        cm = $active.data('editor');
        if (cm.getValue() === '' && $active.children('span').text() === 'untitled') {
          $active.children('span').text(filename);
          mode = ext2mode(filename.replace(/^.*\./, ''));
          cm.setOption('mode', mode);
          cm.setOption('extraKeys', mode === 'htmlmixed' ? CodeMirror.defaults.extraKeys : null);
          cm.setOption('onGutterClick', mode === 'coffeescript' ? CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder) : CodeMirror.newFoldFunction(CodeMirror.braceRangeFinder));
          return cm.setValue(reader.result);
        }
      };
      return reader.readAsText(event.target.files[0]);
    });
    $('#file-tabs').on('click', 'button.close', function() {
      var $first, $tabAnchor, $this, cm;
      $this = $(this);
      $tabAnchor = $this.parent();
      if (confirm("Do you really delete \"" + ($tabAnchor.children('span').text()) + "\" locally?")) {
        cm = $tabAnchor.data('editor');
        if (cm.siphon.timer != null) {
          clearTimeout(cm.siphon.timer);
        }
        cm.siphon.timer = null;
        if (cm.siphon['dropbox-stat'] != null) {
          localStorage.removeItem("siphon-buffer-" + cm.siphon['dropbox-stat'].path);
        } else if ($tabAnchor.children('span').text() !== 'untitled') {
          localStorage.removeItem("siphon-buffer-" + ($tabAnchor.children('span').text()));
        }
        if ($('#file-tabs > li:not(.dropdown)').length > 1) {
          $tabAnchor.data('editor', null);
          $tabAnchor.parent().remove();
          $(cm.getWrapperElement()).remove();
          $first = $('#file-tabs > li:first-child');
          $first.addClass('active');
          cm = $first.children('a').data('editor');
          $(cm.getWrapperElement()).addClass('active');
        } else {
          $tabAnchor.children('span').text('untitled');
          cm.siphon['dropbox-stat'] = null;
          cm.setValue('');
        }
        return cm.focus();
      }
    });
    $('#download-button').on('click', function() {
      return getList(config.dropbox.currentFolder);
    });
    $('#download-modal .breadcrumb').on('click', 'li:not(.active) > a', function() {
      var $this, path;
      $this = $(this);
      $this.parent().nextUntil().remove();
      $this.parent().addClass('active');
      path = $this.data('path');
      getList(path);
      config.dropbox.currentFolder = path;
      localStorage['siphon-config'] = JSON.stringify(config);
      return false;
    });
    $('#download-modal table').on('click', 'tr', function() {
      var $this, stat;
      $this = $(this);
      stat = $this.data('dropbox-stat');
      if (stat.isFile) {
        $('#download-modal table tr').removeClass('info');
        return $this.addClass('info');
      } else if (stat.isFolder) {
        $('#download-modal .breadcrumb > li.active').removeClass('active');
        $('#download-modal .breadcrumb').append($("<li class=\"active\">\n    <span class=\"divider\">/</span>\n    <a href=\"#\" data-path=\"" + stat.path + "\"}>" + stat.name + "</a>\n</li>"));
        getList(stat.path);
        config.dropbox.currentFolder = stat.path;
        return localStorage['siphon-config'] = JSON.stringify(config);
      }
    });
    $('#open').on('click', function() {
      var $tabs, stat;
      stat = $('#download-modal table tr.info').data('dropbox-stat');
      if (stat != null ? stat.isFile : void 0) {
        $tabs = $('#file-tabs > li > a').filter(function() {
          var _ref;
          return ((_ref = $(this).data('editor').siphon['dropbox-stat']) != null ? _ref.path : void 0) === stat.path;
        });
        if ($tabs.length > 0 && !confirm("There is a buffer editing. Do you want to discard a content of the buffer and update to the server's?")) {
          $tabs = null;
        }
        dropbox.readFile(stat.path, null, function(error, string, stat) {
          var $active, cm, e, extension, _i, _len;
          if (($tabs != null) && $tabs.length > 0) {
            for (_i = 0, _len = $tabs.length; _i < _len; _i++) {
              e = $tabs[_i];
              $(e).trigger('click');
              $(e).data('editor').setValue(string);
              $(e).data('editor').siphon['dropbox-stat'] = stat;
            }
          } else {
            $active = $('#file-tabs > li.active > a');
            cm = $active.data('editor');
            extension = stat.name.replace(/^.*\./, '');
            if (cm.getValue() === '' && $active.children('span').text() === 'untitled') {
              $active.children('span').text(stat.name);
              cm.setOption('mode', (function() {
                switch (extension) {
                  case 'html':
                    return 'text/html';
                  case 'css':
                    return 'css';
                  case 'js':
                    return 'javascript';
                  case 'coffee':
                    return 'coffeescript';
                  case 'less':
                    return 'less';
                  default:
                    return null;
                }
              })());
              if (extension !== 'html') {
                cm.setOption('extraKeys', null);
              }
              cm.setOption('onGutterClick', cm.getOption('mode') === 'coffeescript' ? CodeMirror.newFoldFunction(CodeMirror.indentRangeFinder) : CodeMirror.newFoldFunction(CodeMirror.braceRangeFinder));
            } else {
              cm = newTabAndEditor(stat.name, (function() {
                switch (extension) {
                  case 'js':
                    return 'javascript';
                  case 'coffee':
                    return 'coffeescript';
                  default:
                    return extension;
                }
              })());
              $active = $('#file-tabs > li.active > a');
            }
            cm.setValue(string);
            cm.siphon['dropbox-stat'] = stat;
          }
          return spinner.stop();
        });
        return spinner.spin(document.body);
      }
    });
    $('#upload').on('click', function() {
      return uploadFile();
    });
    $('.key').on((touchDevice ? 'touchstart' : 'mousedown'), function() {
      return fireKeyEvent('keydown', $(this).data('identifier'));
    });
    $('.key').on((touchDevice ? 'touchend' : 'mouseup'), function() {
      return fireKeyEvent('keyup', $(this).data('identifier'));
    });
    $('#undo').on('click', function() {
      return $('#file-tabs > li.active > a').data('editor').undo();
    });
    $('#eval').on('click', function() {
      var cm, line;
      cm = $('#file-tabs > li.active > a').data('editor');
      if (cm.getOption('mode') !== 'coffeescript') {
        return;
      }
      if (!cm.somethingSelected()) {
        line = cm.getCursor().line;
        cm.setSelection({
          line: line,
          ch: 0
        }, {
          line: line,
          ch: cm.getLine(line).length
        });
      }
      return cm.replaceSelection(evalCS(cm.getSelection()).toString());
    });
    $('#dropbox').on('click', function() {
      var $this;
      $this = $(this);
      if ($this.text() === 'sign-in') {
        $this.button('loading');
        dropbox.reset();
        dropbox.authenticate(function(error, client) {
          spinner.stop();
          if (error) {
            return showError(error);
          } else {
            return $this.button('signout');
          }
        });
      } else {
        dropbox.signOut(function(error) {
          spinner.stop();
          if (error) {
            showError(error);
            return alart('pass');
          } else {
            return $this.button('reset');
          }
        });
      }
      return spinner.spin(document.body);
    });
    $('#save-setting').on('click', function() {
      config.keyboard = $('#setting input[name="keyboard"]:checked').val();
      if (config.keyboard === 'user-defined') {
        config['user-defined-keyboard'] = {
          portrait: parseInt($('#setting input[name="keyboard-height-portrait"]').val()),
          landscape: parseInt($('#setting input[name="keyboard-height-landscape"]').val())
        };
      }
      if (config.dropbox.sandbox.toString() !== $('#setting input[name="sandbox"]:checked').val()) {
        config.dropbox.sandbox = !config.dropbox.sandbox;
      }
      if ((typeof $('#setting input[name="compile"]').attr('checked') !== 'undefined') !== config.compile) {
        config.compile = !config.compile;
      }
      return localStorage['siphon-config'] = JSON.stringify(config);
    });
    return (function() {
      var query, searchCursor;
      searchCursor = null;
      query = null;
      $('#search').on('submit', function(e) {
        var cm;
        cm = $('#file-tabs > .active > a').data('editor');
        query = $('#search > input[name="query"]').val();
        searchCursor = cm.getSearchCursor(query, cm.getCursor(), false);
        if (searchCursor.findNext()) {
          cm.setSelection(searchCursor.from(), searchCursor.to());
        } else {
          alert("No more \"" + query + "\"");
        }
        return false;
      });
      $('#search-backward').on('click', function() {
        if (searchCursor.findPrevious()) {
          return searchCursor.cm.setSelection(searchCursor.from(), searchCursor.to());
        } else {
          return alert("No more \"" + query + "\"");
        }
      });
      return $('#search-forward').on('click', function() {
        if (searchCursor.findNext()) {
          return searchCursor.cm.setSelection(searchCursor.from(), searchCursor.to());
        } else {
          return alert("No more \"" + query + "\"");
        }
      });
    })();
  };

  if (!touchDevice) {
    $('#soft-key').css('display', 'none');
  }

  if (/iPad|iPhone/.test(navigator.userAgent)) {
    $('#import').css('display', 'none');
  }

  newTabAndEditor();

  restore();

  initializeDropbox();

  initializeEventHandlers();

}).call(this);
