// Generated by CoffeeScript 1.4.0

/*
# AutoComplete for CodeMirror in CoffeeScript
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
*/


(function() {
  var API_KEY_FULL, API_KEY_SANDBOX, AutoComplete, COFFEE_KEYWORDS, CORE_CLASSES, DATE_PROPERTIES, JS_KEYWORDS, KEYWORDS, KEYWORDS_COMPLETE, OPERATORS, OPERATORS_WITH_EQUAL, UTC_PROPERTIES, classes, config, dropbox, e, evalCS, fireKeyEvent, functions, getList, globalProperties, globalPropertiesPlusKeywords, key, keyboardHeight, newCodeMirror, showError, spinner, touchDevice, uploadFile, value, variables, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3, _ref4;

  JS_KEYWORDS = ['true', 'false', 'null', 'this', 'new', 'delete', 'typeof', 'in', 'instanceof', 'return', 'throw', 'break', 'continue', 'debugger', 'if', 'else', 'switch', 'for', 'while', 'do', 'try', 'catch', 'finally', 'class', 'extends', 'super'];

  COFFEE_KEYWORDS = ['undefined', 'then', 'unless', 'until', 'loop', 'of', 'by', 'when', 'yes', 'no', 'on', 'off'];

  OPERATORS_WITH_EQUAL = ['-', '+', '*', '/', '%', '<', '>', '&', '|', '^', '!', '?', '='];

  OPERATORS = ['->', '=>', 'and', 'or', 'is', 'isnt', 'not', '&&', '||'];

  OPERATORS = OPERATORS.concat(OPERATORS_WITH_EQUAL.concat(OPERATORS_WITH_EQUAL.map(function(e) {
    return e + '=';
  }))).sort();

  UTC_PROPERTIES = ['Date', 'Day', 'FullYear', 'Hours', 'Milliseconds', 'Minutes', 'Month', 'Seconds'];

  DATE_PROPERTIES = ['Time', 'Year'].concat(UTC_PROPERTIES.reduce((function(a, b) {
    return a.concat([b, 'UTC' + b]);
  }), []));

  CORE_CLASSES = {
    Array: ['length', 'concat', 'every', 'filter', 'forEach', 'indexOf', 'join', 'lastIndexOf', 'map', 'pop', 'push', 'reduce', 'reduceRight', 'reverse', 'shift', 'slice', 'some', 'sort', 'splice', 'toLocaleString', 'toString', 'unshift'],
    Boolean: ['toString', 'valueOf'],
    Date: ['getTimezoneOffset', 'toDateString', 'toGMTString', 'toISOString', 'toJSON', 'toLocaleDateString', 'toLocaleString', 'toLocaleTimeString', 'toString', 'toTimeString', 'toUTCString', 'valueOf'].concat(DATE_PROPERTIES.reduce((function(a, b) {
      return a.concat(['get' + b, 'set' + b]);
    }), [])).sort(),
    Error: [],
    EvalError: [],
    Function: [],
    Global: [],
    JSON: [],
    Math: [],
    Number: [],
    Object: [],
    RangeError: [],
    ReferenceError: [],
    RegExp: [],
    String: [],
    SyntaxError: [],
    TypeError: [],
    URIError: []
  };

  KEYWORDS = JS_KEYWORDS.concat(COFFEE_KEYWORDS).sort();

  KEYWORDS_COMPLETE = {
    "if": ['else', 'then else'],
    "for": ['in', 'in when', 'of', 'of when'],
    "try": ['catch finally', 'catch'],
    "class": ['extends'],
    "switch": ['when else', 'when', 'when then else', 'when then']
  };

  globalProperties = (function() {
    var _results;
    _results = [];
    for (e in window) {
      _results.push(e);
    }
    return _results;
  })();

  globalPropertiesPlusKeywords = globalProperties.concat(KEYWORDS).sort();

  variables = [];

  functions = [];

  classes = [];

  _ref = globalProperties.sort();
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    e = _ref[_i];
    if (window[e] === null || (typeof window[e] !== 'function' && /^[A-Z]/.test(e))) {
      continue;
    }
    if (typeof window[e] === 'function') {
      if (/^[A-Z]/.test(e)) {
        classes.push(e);
      } else {
        functions.push(e);
      }
    } else if (!/^[A-Z]/.test(e)) {
      variables.push(e);
    }
  }

  AutoComplete = (function() {

    function AutoComplete(cm, text) {
      this.cm = cm;
      this.char = text.charAt(text.length - 1);
    }

    AutoComplete.prototype.complete = function() {
      var candidates, cursor, key, object, pos, propertyChain, target, token;
      if (this.candidates != null) {
        return;
      }
      this.candidates = [];
      cursor = this.cm.getCursor();
      switch (this.cm.getOption('mode')) {
        case 'coffeescript':
          if (/[a-zA-Z_$\.]/.test(this.char)) {
            propertyChain = [];
            pos = cursor;
            while ((token = this.cm.getTokenAt(pos)).string.charAt(0) === '.') {
              propertyChain.push(token);
              pos = {
                line: cursor.line,
                ch: token.start - 1
              };
            }
            propertyChain.push(token);
            propertyChain.reverse();
            if (propertyChain.length === 1) {
              candidates = globalPropertiesPlusKeywords;
            } else {
              try {
                object = eval(propertyChain.map(function(e) {
                  return e.string;
                }).slice(0, -1).join());
                candidates = (function() {
                  var _results;
                  _results = [];
                  for (key in object) {
                    _results.push(key);
                  }
                  return _results;
                })();
              } catch (err) {
                console.log(err);
                candidates = [];
              }
            }
            target = propertyChain[propertyChain.length - 1].string.replace(/^\./, '');
            this.candidates = candidates.filter(function(e) {
              return new RegExp('^' + target).test(e);
            }).map(function(e) {
              return e.slice(target.length);
            });
          } else if (this.char === ' ') {
            token = this.cm.getTokenAt({
              line: cursor.line,
              ch: cursor.ch - 1
            });
            if (KEYWORDS_COMPLETE.hasOwnProperty(token.string)) {
              this.candidates = KEYWORDS_COMPLETE[token.string];
            }
          }
      }
      if (this.candidates.length > 0) {
        this.index = 0;
        this.cm.replaceRange(this.candidates[this.index], cursor);
        this.start = cursor;
        this.end = this.cm.getCursor();
        return this.cm.setSelection(this.start, this.end);
      }
    };

    AutoComplete.prototype.previous = function() {
      return this.next_(-1);
    };

    AutoComplete.prototype.next = function() {
      return this.next_(1);
    };

    AutoComplete.prototype.next_ = function(increment) {
      var cursor;
      if (this.candidates.length > 1) {
        cursor = this.cm.getCursor();
        this.index += increment;
        if (this.index < 0) {
          this.index = this.candidates.length - 1;
        } else if (this.index >= this.candidates.length) {
          this.index = 0;
        }
        this.cm.replaceRange(this.candidates[this.index], this.start, this.end);
        this.end = this.cm.getCursor();
        return this.cm.setSelection(this.start, this.end);
      }
    };

    return AutoComplete;

  })();

  /*
  # (C) 2012 New 3 Rs (ICHIKAWA, Yuji)
  */


  API_KEY_FULL = 'iHaFSTo2hqA=|lC0ziIxBPWaNm/DX+ztl4p1RdqPQI2FAwofDEmJsiQ==';

  API_KEY_SANDBOX = 'CCdH9UReG2A=|k8J5QIsJKiBxs2tvP5WxPZ5jhjIhJ1GS0sbPdv3xxw==';

  newCodeMirror = function(tabAnchor, options, active) {
    var $wrapper, defaultOptions, key, result, value, _ref1;
    defaultOptions = {
      lineNumbers: true,
      lineWrapping: true,
      onBlur: function() {
        return $('.navbar-fixed-bottom').css('bottom', '');
      },
      onChange: function(cm, change) {
        if (!(cm.siphon.autoComplete != null) && change.text.length === 1 && change.text[0].length === 1) {
          cm.siphon.autoComplete = new AutoComplete(cm, change.text[change.text.length - 1]);
          return cm.siphon.autoComplete.complete(cm);
        }
      },
      onFocus: function() {
        return $('.navbar-fixed-bottom').css('bottom', "" + (keyboardHeight(config)) + "px");
      },
      onKeyEvent: function(cm, event) {
        switch (event.type) {
          case 'keydown':
            return cm.siphon.autoComplete = null;
        }
      },
      theme: 'blackboard'
    };
    if (options == null) {
      options = {};
    }
    for (key in defaultOptions) {
      value = defaultOptions[key];
      if ((_ref1 = options[key]) == null) {
        options[key] = value;
      }
    }
    if (!touchDevice) {
      options.onBlur = null;
      options.onFocus = null;
    }
    result = CodeMirror($('#editor-pane')[0], options);
    $wrapper = $(result.getWrapperElement());
    $wrapper.attr('id', "cm" + newCodeMirror.number);
    $wrapper.addClass('tab-pane');
    if (active) {
      $wrapper.addClass('active');
    }
    newCodeMirror.number += 1;
    result.siphon = {};
    $(tabAnchor).data('editor', result);
    /* CodeMirror 3
    CodeMirror.on result, 'change', (cm, change)->
        if change.origin is 'input'
            cm.siphon.autoComplete = new AutoComplete cm, change.text[change.text.length - 1]
            cm.siphon.autoComplete.complete cm
    */

    return result;
  };

  newCodeMirror.number = 0;

  getList = function(path) {
    var $table;
    $table = $('#download-modal table');
    spinner.spin(document.body);
    return dropbox.readdir(path, null, function(error, names, stat, stats) {
      var $tr, _j, _len1, _results;
      spinner.stop();
      $table.children().remove();
      if (error) {
        return alert(error);
      } else {
        _results = [];
        for (_j = 0, _len1 = stats.length; _j < _len1; _j++) {
          e = stats[_j];
          $tr = $("<tr><td>" + e.name + "</td></tr>");
          $tr.data('dropbox', e);
          _results.push($table.append($tr));
        }
        return _results;
      }
    });
  };

  uploadFile = function() {
    var $active, filename, folder, path, stat;
    $active = $('#file-tabs > li.active > a');
    stat = $active.data('dropbox');
    if (stat != null) {
      path = stat.path;
    } else {
      folder = $('#download-modal .breadcrumb > li.active > a').data('path');
      filename = prompt("Input file name. (current folder is " + folder + ".)", $active.text());
      if (!filename) {
        return;
      }
      path = folder + '/' + filename;
    }
    dropbox.writeFile(path, $active.data('editor').getValue(), null, function(error, stat) {
      spinner.stop();
      if (error) {
        return alert(error);
      } else {
        return $active.data('dropbox', stat);
      }
    });
    return spinner.spin(document.body);
  };

  fireKeyEvent = function(type, keyIdentifier, keyCode, charCode) {
    var DOM_KEY_LOCATION_STANDARD, KEY_CODES;
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
        return null;
      case 404:
        return null;
      case 507:
        return null;
      case 503:
        return null;
      case 400:
        return null;
      case 403:
        return null;
      case 405:
        return null;
      default:
        return null;
    }
  };

  keyboardHeight = function(config) {
    var IPAD_KEYBOARD_HEIGHT, IPAD_SPLIT_KEYBOARD_HEIGHT, r;
    IPAD_KEYBOARD_HEIGHT = {
      portrait: 307,
      landscape: 395
    };
    IPAD_SPLIT_KEYBOARD_HEIGHT = {
      portrait: 283,
      landscape: 277
    };
    r = ((function() {
      switch (config.keyboard) {
        case 'normal':
          return IPAD_KEYBOARD_HEIGHT;
        case 'split':
          return IPAD_SPLIT_KEYBOARD_HEIGHT;
        case 'user-defined':
          return config['user-defined-keyboard'];
      }
    })())[orientation % 180 === 0 ? 'portrait' : 'landscape'];
    console.log(r);
    return r;
  };

  touchDevice = (function() {
    try {
      document.createEvent('TouchEvent');
      return true;
    } catch (error) {
      return false;
    }
  })();

  if (/iPhone|iPad/.test(navigator.userAgent)) {
    $('#file').css('display', 'none');
  }

  if (!touchDevice) {
    $('#soft-key').css('display', 'none');
  }

  config = JSON.parse((_ref1 = localStorage['siphon-config']) != null ? _ref1 : '{}');

  if ((_ref2 = config.keyboard) == null) {
    config.keyboard = 'normal';
  }

  if ((_ref3 = config.sandbox) == null) {
    config.sandbox = true;
  }

  $("#setting input[name=\"keyboard\"][value=\"" + config.keyboard + "\"]").attr('checked', '');

  if (config['user-defined-keyboard'] != null) {
    $('#setting input[name="keyboard-height-portrait"]').value(config['user-defined-keyboard'].portrait);
    $('#setting input[name="keyboard-height-landscape"]').value(config['user-defined-keyboard'].landscape);
  }

  $("#setting input[name=\"sandbox\"][value=\"" + (config.sandbox.toString()) + "\"]").attr('checked', '');

  spinner = new Spinner({
    color: '#fff'
  });

  dropbox = new Dropbox.Client({
    key: config.sandbox ? API_KEY_SANDBOX : API_KEY_FULL,
    sandbox: config.sandbox
  });

  dropbox.authDriver(new Dropbox.Drivers.Redirect({
    rememberUser: true
  }));

  if (!/not_approved=true/.test(location.toString())) {
    for (key in localStorage) {
      value = localStorage[key];
      try {
        if (/^dropbox-auth/.test(key) && JSON.parse(value).key === dropbox.oauth.key) {
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
  }

  newCodeMirror($('#file-tabs > li.active > a')[0], {
    extraKeys: null,
    mode: 'coffeescript'
  }, true);

  _ref4 = $('.navbar-fixed-bottom');
  for (_j = 0, _len1 = _ref4.length; _j < _len1; _j++) {
    e = _ref4[_j];
    new NoClickDelay(e, false);
  }

  $('#previous-button').on('click', function() {
    var cm, _ref5;
    cm = $('#file-tabs > li.active > a').data('editor');
    if ((_ref5 = cm.siphon.autoComplete) != null) {
      _ref5.previous();
    }
    return cm.focus();
  });

  $('#next-button').on('click', function() {
    var cm, _ref5;
    cm = $('#file-tabs > li.active > a').data('editor');
    if ((_ref5 = cm.siphon.autoComplete) != null) {
      _ref5.next();
    }
    return cm.focus();
  });

  $('a.new-tab-type').on('click', function() {
    var $tab, id, num;
    $('#file-tabs > li.active, #editor-pane > *').removeClass('active');
    num = ((function() {
      var _k, _len2, _ref5, _results;
      _ref5 = $('#editor-pane > *');
      _results = [];
      for (_k = 0, _len2 = _ref5.length; _k < _len2; _k++) {
        e = _ref5[_k];
        _results.push(parseInt(e.id.replace(/^cm/, '')));
      }
      return _results;
    })()).reduce(function(a, b) {
      return Math.max(a, b);
    });
    id = "cm" + (num + 1);
    $tab = $("<li class=\"active\">\n    <a href=\"#" + id + "\" data-toggle=\"tab\">\n        <button class=\"close\" type=\"button\">&times;</button>\n        <span>untitled</span>\n    </a>\n</li>");
    $('#file-tabs > li.dropdown').before($tab);
    newCodeMirror($tab.children('a')[0], (function() {
      switch ($(this).text()) {
        case 'HTMl':
          return {
            mode: 'text/html'
          };
        case 'CSS':
          return {
            extraKeys: null,
            mode: 'css'
          };
        case 'LESS':
          return {
            extraKyes: null,
            mode: 'less'
          };
        case 'JavaScript':
          return {
            extraKeys: null,
            mode: 'javascript'
          };
        case 'CofeeScript':
          return {
            extraKeys: null,
            mode: 'coffeescript'
          };
        default:
          return null;
      }
    }).call(this), true);
    return false;
  });

  $('#file').on('click', function() {
    return $('#file-picker').click();
  });

  $('#file-picker').on('change', function(event) {
    var fileName, reader;
    fileName = this.value.replace(/^.*\\/, '');
    reader = new FileReader();
    reader.onload = function() {
      var $active, cm, extension;
      $active = $('#file-tabs > li.active > a');
      cm = $active.data('editor');
      if (cm.getValue() === '' && $active.children('span').text() === 'untitled') {
        $active.children('span').text(fileName);
        extension = fileName.replace(/^.*\./, '');
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
      if ($('#file-tabs > li:not(.dropdown)').length > 1) {
        cm = $tabAnchor.data('editor');
        $tabAnchor.data('editor', null);
        $tabAnchor.parent().remove();
        $(cm.getWrapperElement()).remove();
        $first = $('#file-tabs > li:first-child');
        $first.addClass('active');
        cm = $first.children('a').data('editor');
        $(cm.getWrapperElement().parentElement).addClass('active');
      } else {
        $tabAnchor.children('span').text('untitled');
        cm = $tabAnchor.data('editor');
        cm.setValue('');
      }
      return cm.focus();
    }
  });

  $('#download-button').on('click', function() {
    return getList($('#download-modal .breadcrumb > li.active > a').data('path'));
  });

  $('#download-modal .breadcrumb').on('click', 'li:not(.active) > a', function() {
    var $this;
    $this = $(this);
    $this.parent().nextUntil().remove();
    $this.parent().addClass('active');
    getList($this.data('path'));
    return false;
  });

  $('#download-modal table').on('click', 'tr', function() {
    var $this, stat;
    $this = $(this);
    stat = $this.data('dropbox');
    if (stat.isFile) {
      $('#download-modal table tr').removeClass('info');
      return $this.addClass('info');
    } else if (stat.isFolder) {
      $('#download-modal .breadcrumb > li.active').removeClass('active');
      $('#download-modal .breadcrumb').append($("<li class=\"active\">\n    <span class=\"divider\">/</span>\n    <a href=\"#\" data-path=\"" + stat.path + "\"}>" + stat.name + "</a>\n</li>"));
      return getList(stat.path);
    }
  });

  $('#open').on('click', function() {
    var stat;
    stat = $('#download-modal table tr.info').data('dropbox');
    if (stat != null ? stat.isFile : void 0) {
      dropbox.readFile(stat.path, null, function(error, string, stat) {
        spinner.stop();
        $('#file-tabs > li.active > a').data('editor').setValue(string);
        return $('#file-tabs > li.active > a').data('dropbox', stat);
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

  $('#save-setting').on('click', function() {
    config.keyboard = $('#setting input[name="keyboard"]:checked').val();
    if (config.keyboard === 'user-defined') {
      config['user-defined-keyboard'] = {
        portrait: parseInt($('#setting input[name="keyboard-height-portrait"]').val()),
        landscape: parseInt($('#setting input[name="keyboard-height-landscape"]').val())
      };
    }
    if (config.sandbox.toString() !== $('#setting input[name="sandbox"]:checked').val()) {
      config.sandbox = !config.sandbox;
    }
    return localStorage['siphon-config'] = JSON.stringify(config);
  });

}).call(this);
