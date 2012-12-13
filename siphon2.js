// Generated by CoffeeScript 1.4.0
(function() {
  var AutoComplete, BOUNDARY, CLIENT_ID, COFFEE_KEYWORDS, CORE_CLASSES, DATE_PROPERTIES, JS_KEYWORDS, KEYWORDS, KEYWORDS_COMPLETE, OPERATORS, OPERATORS_WITH_EQUAL, SCOPES, UTC_PROPERTIES, classes, close_delim, delimiter, e, evalCS, fireKeyEvent, functions, getList, globalProperties, globalPropertiesPlusKeywords, keyboardHeight, newCodeMirror, prepareTable, spinner, touchDevice, uploadFile, variables, _i, _j, _len, _len1, _ref, _ref1;

  CLIENT_ID = '361799283439.apps.googleusercontent.com';

  SCOPES = 'https://www.googleapis.com/auth/drive';

  window.googleDrive = {
    authorized: false
  };

  BOUNDARY = '-------314159265358979323846';

  delimiter = "\r\n--" + BOUNDARY + "\r\n";

  close_delim = "\r\n--" + BOUNDARY + "--";

  googleDrive.File = (function() {

    File.insert = function(title, type, content, callback) {
      var base64Data, metadata, multipartRequestBody, request;
      metadata = {
        'title': title,
        'mimeType': type
      };
      base64Data = btoa(content);
      multipartRequestBody = delimiter + 'Content-Type: application/json\r\n\r\n' + JSON.stringify(metadata) + delimiter + ("Content-Type: " + contentType + "\r\n") + 'Content-Transfer-Encoding: base64\r\n' + '\r\n' + base64Data + close_delim;
      request = gapi.client.request({
        'path': '/upload/drive/v2/files',
        'method': 'POST',
        'params': {
          'uploadType': 'multipart'
        },
        'headers': {
          'Content-Type': "multipart/mixed; boundary=\"" + BOUNDARY + "\""
        },
        'body': multipartRequestBody
      });
      return request.execute(callback);
    };

    File.getList = function(q, callback) {
      var initialRequest, retrievePageOfFiles;
      retrievePageOfFiles = function(request, result) {
        return request.execute(function(resp) {
          var nextPageToken;
          result = result.concat(resp.items);
          nextPageToken = resp.nextPageToken;
          if (nextPageToken != null) {
            request = gapi.client.drive.files.list({
              'pageToken': nextPageToken
            });
            return retrievePageOfFiles(request, result);
          } else {
            return callback(result);
          }
        });
      };
      initialRequest = gapi.client.drive.files.list({
        q: q
      });
      return retrievePageOfFiles(initialRequest, []);
    };

    function File(idOrResource) {
      var request,
        _this = this;
      if (typeof idOrResource === 'string') {
        request = gapi.client.drive.files.get({
          'fileId': idOrResource
        });
        request.execute(function(resp) {
          return _this.resource = resp;
        });
      } else {
        this.resource = idOrResource;
      }
    }

    File.prototype.id = function() {
      return this.resource.id;
    };

    File.prototype.download = function(callback) {
      var accessToken, xhr;
      if (this.resource.downloadUrl != null) {
        accessToken = gapi.auth.getToken().access_token;
        xhr = new XMLHttpRequest();
        xhr.open('GET', this.resource.downloadUrl);
        xhr.setRequestHeader('Authorization', 'Bearer ' + accessToken);
        xhr.onload = function() {
          return callback(xhr.responseText);
        };
        xhr.onerror = function() {
          return callback(null);
        };
        return xhr.send();
      } else {
        return callback(null);
      }
    };

    File.prototype.patch = function(resource) {
      var request;
      request = gapi.client.drive.files.patch({
        'fileId': this.id(),
        'resource': resource
      });
      return request.execute(function(resp) {
        return this.resource = resp;
      });
    };

    File.prototype.update = function(resource, content, callback) {
      var base64Data, multipartRequestBody, request;
      base64Data = btoa(content);
      multipartRequestBody = delimiter + 'Content-Type: application/json\r\n\r\n' + JSON.stringify(resource) + delimiter + ("Content-Type: " + contentType + "\r\n") + 'Content-Transfer-Encoding: base64\r\n' + '\r\n' + base64Data + close_delim;
      request = gapi.client.request({
        'path': "/upload/drive/v2/files/" + (this.id()),
        'method': 'PUT',
        'params': {
          'uploadType': 'multipart',
          'alt': 'json'
        },
        'headers': {
          'Content-Type': "multipart/mixed; boundary=\"" + BOUNDARY + "\""
        },
        'body': multipartRequestBody
      });
      return request.execute(callback);
    };

    File.prototype.copy = function(title, callback) {
      var request, resource;
      resource = {
        'title': title
      };
      request = gapi.client.drive.files.copy({
        'fileId': this.id(),
        'resource': resource
      });
      return request.execute(callback);
    };

    File.prototype["delete"] = function() {
      var request;
      request = gapi.client.drive.files["delete"]({
        'fileId': this.id()
      });
      return request.execute();
    };

    File.prototype.touch = function() {
      var request,
        _this = this;
      request = gapi.client.drive.files.touch({
        'fileId': this.id()
      });
      return request.execute(function(resp) {
        return _this.resource = resp;
      });
    };

    File.prototype.trash = function() {
      var request,
        _this = this;
      request = gapi.client.drive.files.trash({
        'fileId': this.id()
      });
      return request.execute(function(resp) {
        return _this.resource = resp;
      });
    };

    File.prototype.untrash = function() {
      var request,
        _this = this;
      request = gapi.client.drive.files.untrash({
        'fileId': this.id()
      });
      return request.execute(function(resp) {
        return _this.resource = resp;
      });
    };

    return File;

  })();

  googleDrive.checkAuth = function(success) {
    var handleAuthResult;
    handleAuthResult = function(authResult) {
      if (authResult && !authResult.error) {
        googleDrive.authorized = true;
        return success();
      } else {
        return gapi.auth.authorize({
          'client_id': CLIENT_ID,
          'scope': SCOPES,
          'immediate': false
        }, handleAuthResult);
      }
    };
    return gapi.auth.authorize({
      'client_id': CLIENT_ID,
      'scope': SCOPES,
      'immediate': true
    }, handleAuthResult);
  };

  window.handleClientLoad = function() {
    return gapi.client.load('drive', 'v2');
  };

  /*
  # (C) 2012 New 3 Rs (ICHIKAWA, Yuji)
  */


  touchDevice = (function() {
    try {
      document.createEvent('TouchEvent');
      return true;
    } catch (error) {
      return false;
    }
  })();

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

  prepareTable = function(id, array) {
    var $tr, e, i, numOfColumns, rows, _i, _len;
    rows = [];
    numOfColumns = 5;
    for (i = _i = 0, _len = array.length; _i < _len; i = ++_i) {
      e = array[i];
      if (i % numOfColumns === 0) {
        $tr = $('<tr></tr>');
        rows.push($tr);
      }
      $tr.append($('<td></td>').append($('<a class="token" href="#"></a>').text(e)));
    }
    return $("#" + id).append(rows);
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

  newCodeMirror = function(tabAnchor, options, active) {
    var $wrapper, defaultOptions, key, result, value, _ref1;
    defaultOptions = {
      lineNumbers: true,
      onBlur: function() {
        return $('.navbar-fixed-bottom').css('bottom', '');
      },
      onChange: function(cm, change) {
        if (cm.siphon.autoComplete == null) {
          cm.siphon.autoComplete = new AutoComplete(cm, change.text[change.text.length - 1]);
          return cm.siphon.autoComplete.complete(cm);
        }
      },
      onFocus: function() {
        return $('.navbar-fixed-bottom').css('bottom', keyboardHeight + 'px');
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

  getList = function() {
    googleDrive.File.getList(['.html', '.css', '.js', '.less', '.coffee'].map(function(e) {
      return "title contains '" + e + "'";
    }).join(' or '), function(list) {
      var $a, _j, _len1;
      $('#download~ul > *').remove();
      for (_j = 0, _len1 = list.length; _j < _len1; _j++) {
        e = list[_j];
        $a = $("<a href=\"" + e.downloadUrl + "\">" + e.title + "</a>");
        $a.data('resource', e);
        $('#download~ul').append($("<li></li>").append($a));
      }
      return spinner.stop();
    });
    return spinner.spin(document.body);
  };

  uploadFile = function() {
    var $active, file, title;
    $active = $('#file-tabs > li.active > a');
    file = $active.data('file');
    if (file != null) {
      file.update(null, $active.data('editor').getValue(), function() {
        return spinner.stop();
      });
    } else {
      title = $active.text();
      if (title === 'untitled') {
        title = prompt();
        if (!title) {
          return;
        }
      }
      googleDrive.File.insert(title, 'text/plain', $active.data('editor').getValue(), function() {
        return spinner.stop();
      });
    }
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

  keyboardHeight = 307;

  if (/iPhone|iPad/.test(navigator.userAgent)) {
    $('#file').css('display', 'none');
  }

  spinner = new Spinner({
    color: '#fff'
  });

  newCodeMirror($('#file-tabs > li.active > a')[0], {
    extraKeys: null,
    mode: 'coffeescript'
  }, true);

  _ref1 = $('#previous-button, #next-button, .navbar-fixed-bottom');
  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
    e = _ref1[_j];
    new NoClickDelay(e, false);
  }

  $('#previous-button, #next-button').on('mousedown', function(event) {
    return event.preventDefault();
  });

  $('#previous-button').on('click', function() {
    var cm, _ref2;
    cm = $('#file-tabs > li.active > a').data('editor');
    if ((_ref2 = cm.siphon.autoComplete) != null) {
      _ref2.previous();
    }
    return cm.focus();
  });

  $('#next-button').on('click', function() {
    var cm, _ref2;
    cm = $('#file-tabs > li.active > a').data('editor');
    if ((_ref2 = cm.siphon.autoComplete) != null) {
      _ref2.next();
    }
    return cm.focus();
  });

  $('a.new-tab-type').on('click', function() {
    var $tab, id, num;
    $('#file-tabs > li.active, #editor-pane > *').removeClass('active');
    num = ((function() {
      var _k, _len2, _ref2, _results;
      _ref2 = $('#editor-pane > *');
      _results = [];
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        e = _ref2[_k];
        _results.push(parseInt(e.id.replace(/^cm/, '')));
      }
      return _results;
    })()).reduce(function(a, b) {
      return Math.max(a, b);
    });
    id = "cm" + (num + 1);
    $tab = $("<li class=\"active\"><a href=\"#" + id + "\" data-toggle=\"tab\">untitled</a></li>");
    $('#file-tabs > li.dropdown').before($tab);
    return newCodeMirror($tab.children('a')[0], (function() {
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
      if (cm.getValue() === '' && $active.text() === 'untitled') {
        $active.text(fileName);
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

  $('#delete').on('click', function() {
    var $active, $first, cm;
    $active = $('#file-tabs > li.active > a');
    if (confirm("Do you really delete \"" + ($active.text()) + "\" locally?")) {
      if ($('#file-tabs > li:not(.dropdown)').length > 1) {
        cm = $active.data('editor');
        $active.data('editor', null);
        $active.parent().remove();
        $(cm.getWrapperElement()).remove();
        $first = $('#file-tabs > li:first-child');
        $first.addClass('active');
        cm = $first.children('a').data('editor');
        $(cm.getWrapperElement().parentElement).addClass('active');
      } else {
        $active.text('untitled');
        cm = $active.data('editor');
        cm.setValue('');
      }
      return cm.focus();
    }
  });

  $('#download').on('click touchstart', function() {
    if (!googleDrive.authorized) {
      return googleDrive.checkAuth(getList);
    } else {
      return getList();
    }
  });

  $('#download~ul').on('click', 'a', function(event) {
    var file;
    event.preventDefault();
    file = new googleDrive.File($(this).data('resource'));
    file.download(function(text) {
      spinner.stop();
      $('#file-tabs > li.active > a').data('editor').setValue(text);
      return $('#file-tabs > li.active > a').data('file', file);
    });
    return spinner.spin(document.body);
  });

  $('#upload').on('click', function() {
    if (!googleDrive.authorized) {
      return googleDrive.checkAuth(uploadFile);
    } else {
      return uploadFile();
    }
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

  $('#extend').on('click', function() {
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

}).call(this);
