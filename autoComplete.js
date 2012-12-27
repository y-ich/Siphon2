// Generated by CoffeeScript 1.4.0

/*
# AutoComplete for CodeMirror in CoffeeScript
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
*/


(function() {
  var AutoComplete, COMMON_KEYWORDS, CS_KEYWORDS_ASSIST, CS_ONLY_KEYWORDS, GLOBAL_PROPERTIES, GLOBAL_PROPERTIES_PLUS_CS_KEYWORDS, GLOBAL_PROPERTIES_PLUS_JS_KEYWORDS, JS_KEYWORDS_ASSIST, JS_ONLY_KEYWORDS, csErrorLine, e, getDeclaredVariables;

  COMMON_KEYWORDS = ['break', 'catch', 'continue', 'debugger', 'delete', 'do', 'else', 'false', 'finally', 'for', 'if', 'in', 'instanceof', 'new', 'null', 'return', 'switch', 'this', 'throw', 'true', 'try', 'typeof', 'while'];

  JS_ONLY_KEYWORDS = ['case', 'default', 'function', 'var', 'void', 'with'];

  CS_ONLY_KEYWORDS = ['by', 'class', 'extends', 'loop', 'no', 'of', 'off', 'on', 'super', 'then', 'undefined', 'unless', 'until', 'when', 'yes'];

  GLOBAL_PROPERTIES = (function() {
    var _results;
    _results = [];
    for (e in window) {
      _results.push(e);
    }
    return _results;
  })();

  GLOBAL_PROPERTIES_PLUS_JS_KEYWORDS = GLOBAL_PROPERTIES.concat(COMMON_KEYWORDS).concat(JS_ONLY_KEYWORDS).sort();

  GLOBAL_PROPERTIES_PLUS_CS_KEYWORDS = GLOBAL_PROPERTIES.concat(COMMON_KEYWORDS).concat(CS_ONLY_KEYWORDS).sort();

  CS_KEYWORDS_ASSIST = {
    "class": ['extends'],
    "for": ['in', 'in when', 'of', 'of when'],
    "if": ['else', 'then else'],
    "switch": ['when else', 'when', 'when then else', 'when then'],
    "try": ['catch finally', 'catch']
  };

  JS_KEYWORDS_ASSIST = {
    "do": ['while ( )'],
    "for": ['( ; ; ) { }', '( in ) { }'],
    "if": ['( ) { }', '( ) { } else { }'],
    "switch": ['( ) { case : break; default: }'],
    "try": ['catch finally', 'catch'],
    "while": ['( )']
  };

  getDeclaredVariables = function(js) {
    var IDENTIFIER, IDENTIFIER_MAY_WITH_ASSIGN, match, regexp, result;
    IDENTIFIER = '[_A-Za-z$][_A-Za-z$0-9]*';
    IDENTIFIER_MAY_WITH_ASSIGN = IDENTIFIER + '\\s*(?:=\\s*\\S+)?';
    result = [];
    regexp = new RegExp("(?:^|;)\\s*(?:for\\s*\\(\\s*)?var\\s+((?:" + IDENTIFIER_MAY_WITH_ASSIGN + "\\s*,\\s*)*" + IDENTIFIER_MAY_WITH_ASSIGN + ")\\s*(?:;|$)", 'gm');
    while (match = regexp.exec(js)) {
      result = result.concat(match[1].split(/\s*,\s*/).map(function(e) {
        return e.replace(/\s*=.*$/, '');
      }));
    }
    return result;
  };

  csErrorLine = function(error) {
    var parse;
    if (parse = error.message.match(/Parse error on line (\d+): (.*)$/)) {
      return parseInt(parse[1]);
    } else {
      return null;
    }
  };

  AutoComplete = (function() {

    AutoComplete.current = null;

    function AutoComplete(cm) {
      var cursor,
        _this = this;
      this.cm = cm;
      switch (this.cm.getOption('mode')) {
        case 'javascript':
          this.globalPropertiesPlusKeywords = GLOBAL_PROPERTIES_PLUS_JS_KEYWORDS;
          this.keywordsAssist = JS_KEYWORDS_ASSIST;
          break;
        case 'coffeescript':
          this.globalPropertiesPlusKeywords = GLOBAL_PROPERTIES_PLUS_CS_KEYWORDS;
          this.keywordsAssist = CS_KEYWORDS_ASSIST;
      }
      this.candidates = [];
      cursor = this.cm.getCursor();
      this.setCandidates_(cursor, function() {
        if (AutoComplete.current === _this && _this.candidates.length > 0) {
          _this.index = 0;
          _this.cm.replaceRange(_this.candidates[_this.index], cursor);
          _this.start = cursor;
          _this.end = _this.cm.getCursor();
          return _this.cm.setSelection(_this.start, _this.end);
        }
      });
      AutoComplete.current = this;
    }

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

    AutoComplete.prototype.setCandidates_ = function(cursor, continuation) {
      var bracketStack, breakFlag, candidates, key, object, pos, propertyChain, target, token, value,
        _this = this;
      propertyChain = [];
      pos = {};
      for (key in cursor) {
        value = cursor[key];
        pos[key] = value;
      }
      bracketStack = [];
      breakFlag = false;
      while (true) {
        token = this.cm.getTokenAt(pos);
        if (token.className === 'property') {
          propertyChain.push(token);
        } else if (token.className === 'variable' && bracketStack.length === 0) {
          propertyChain.push(token);
          breakFlag = true;
        } else {
          switch (token.string) {
            case ')':
            case '}':
            case ']':
              propertyChain.push(token);
              bracketStack.push(token.string);
              break;
            case '(':
              if (bracketStack.pop() === ')') {
                propertyChain.push(token);
              } else {
                breakFlag = true;
              }
              break;
            case '{':
              if (bracketStack.pop() === '}') {
                propertyChain.push(token);
              } else {
                breakFlag = true;
              }
              break;
            case '[':
              if (bracketStack.pop() === ']') {
                propertyChain.push(token);
              } else {
                breakFlag = true;
              }
              break;
            default:
              propertyChain.push(token);
          }
        }
        if (token.start > 0) {
          pos.ch = token.start;
        } else {
          if (pos.line > 0) {
            pos.line -= 1;
            pos.ch = this.cm.getLine(pos.line).length;
          } else {
            breakFlag = true;
          }
        }
        if (breakFlag) {
          break;
        }
      }
      propertyChain.reverse();
      if (propertyChain.length === 2 && /^\s+$/.test(propertyChain[1].string)) {
        if (this.keywordsAssist.hasOwnProperty(propertyChain[0].string)) {
          this.candidates = this.keywordsAssist[propertyChain[0].string];
        }
      } else if (propertyChain.length > 1 && /^\s+$/.test(propertyChain[propertyChain.length - 1].string) && propertyChain[propertyChain.length - 2].className === 'property') {

      } else if (propertyChain.length !== 0) {
        target = /^(\s*|\.)$/.test(propertyChain[propertyChain.length - 1].string) ? '' : propertyChain[propertyChain.length - 1].string;
        if (propertyChain.length === 1) {
          this.extractVariables_(function(variables) {
            var candidates;
            candidates = /^\s*$/.test(propertyChain[0].string) ? [] : _this.globalPropertiesPlusKeywords.concat(variables).sort();
            _this.candidates = candidates.filter(function(e) {
              return new RegExp('^' + target).test(e);
            }).map(function(e) {
              return e.slice(target.length);
            });
            return continuation();
          });
          return;
        } else {
          try {
            value = eval("(" + (propertyChain.map(function(e) {
              return e.string;
            }).join('').replace(/\..*?$/, '')) + ")");
            candidates = (function() {
              switch (typeof value) {
                case 'string':
                  return Object.getOwnPropertyNames(value.__proto__);
                case 'undefined':
                  return [];
                default:
                  object = new Object(value);
                  if (object instanceof Array) {
                    return Object.getOwnPropertyNames(Object.getPrototypeOf(object));
                  } else {
                    return Object.getOwnPropertyNames(Object.getPrototypeOf(object)).concat(Object.getOwnPropertyNames(object));
                  }
              }
            })();
            this.candidates = candidates.sort().filter(function(e) {
              return new RegExp('^' + target).test(e);
            }).map(function(e) {
              return e.slice(target.length);
            });
          } catch (error) {
            console.log(error);
          }
        }
      }
      return continuation();
    };

    AutoComplete.prototype.extractVariables_ = function(callback) {
      var cs, worker;
      if (this.cm.getOption('mode') === 'coffeescript') {
        cs = this.cm.getValue();
        worker = new Worker('coffee-script-worker.js');
        worker.onmessage = function(event) {
          var tmp;
          if (event.data.js != null) {
            return callback(getDeclaredVariables(event.data.js));
          } else {
            tmp = cs.split(/\r?\n/).slice(0, csErrorLine(event.data.error) - 1);
            cs = tmp.join('\n');
            worker.onmessage = function(event) {
              return callback(event.data.js != null ? getDeclaredVariables(event.data.js) : []);
            };
            return worker.postMessage({
              source: cs,
              options: {
                bare: true
              }
            });
          }
        };
        return worker.postMessage({
          source: cs,
          options: {
            bare: true
          }
        });
      } else {
        return callback(getDeclaredVariables(this.cm.getValue()));
      }
    };

    return AutoComplete;

  })();

  window.AutoComplete = AutoComplete;

}).call(this);
