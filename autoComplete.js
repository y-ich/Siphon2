// Generated by CoffeeScript 1.4.0

/*
# AutoComplete for CodeMirror in CoffeeScript
# requirement: coffee-script-worker.js
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
*/


(function() {
  var AutoComplete, COMMON_KEYWORDS, CS_KEYWORDS_ASSIST, CS_ONLY_KEYWORDS, GLOBAL_PROPERTIES, GLOBAL_PROPERTIES_PLUS_CS_KEYWORDS, GLOBAL_PROPERTIES_PLUS_JS_KEYWORDS, JS_KEYWORDS_ASSIST, JS_ONLY_KEYWORDS, csErrorLine, e, extractVariablesAndShowFirst__, getDeclaredVariables, _ref,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

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

    AutoComplete.latest = null;

    function AutoComplete(cm) {
      this.cm = cm;
      this.addVariablesAndShowFirst_ = __bind(this.addVariablesAndShowFirst_, this);

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
      this.setCandidatesAndShowFirst_();
      AutoComplete.latest = this;
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

    AutoComplete.prototype.setCandidatesAndShowFirst_ = function() {
      var candidates, object, propertyChain, target, value;
      propertyChain = this.getPropertyChain_();
      if (propertyChain.length === 2 && /^\s+$/.test(propertyChain[1].string)) {
        if (this.keywordsAssist.hasOwnProperty(propertyChain[0].string)) {
          this.candidates = this.keywordsAssist[propertyChain[0].string];
        }
      } else if (propertyChain.length > 1 && /^\s+$/.test(propertyChain[propertyChain.length - 1].string) && propertyChain[propertyChain.length - 2].className === 'property') {

      } else if (propertyChain.length !== 0) {
        target = /^(\s*|\.)$/.test(propertyChain[propertyChain.length - 1].string) ? '' : propertyChain[propertyChain.length - 1].string;
        if (propertyChain.length === 1) {
          this.extractVariablesAndShowFirst_();
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
      return this.showFirstCandidate_();
    };

    AutoComplete.prototype.getPropertyChain_ = function() {
      var bracketStack, breakFlag, cursor, key, pos, propertyChain, token, value;
      cursor = this.cm.getCursor();
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
      return propertyChain.reverse();
    };

    AutoComplete.prototype.showFirstCandidate_ = function() {
      if (AutoComplete.latest === this && this.candidates.length > 0) {
        this.index = 0;
        this.cm.replaceRange(this.candidates[this.index], cursor);
        this.start = cursor;
        this.end = this.cm.getCursor();
        return this.cm.setSelection(this.start, this.end);
      }
    };

    AutoComplete.prototype.extractVariablesAndShowFirst_ = function() {
      var cs;
      if (this.cm.getOption('mode') === 'coffeescript') {
        cs = this.cm.getValue();
        return csWorker.postMessage({
          sender: 'autoComplete',
          callback: extractVariablesAndShowFirst__,
          source: cs,
          options: {
            bare: true
          }
        });
      } else {
        return postProcess(getDeclaredVariables(this.cm.getValue()));
      }
    };

    AutoComplete.prototype.addVariablesAndShowFirst_ = function(variables) {
      var candidates;
      candidates = /^\s*$/.test(propertyChain[0].string) ? [] : this.globalPropertiesPlusKeywords.concat(variables).sort();
      this.candidates = candidates.filter(function(e) {
        return new RegExp('^' + target).test(e);
      }).map(function(e) {
        return e.slice(target.length);
      });
      return this.showFirstCandidate_();
    };

    return AutoComplete;

  })();

  extractVariablesAndShowFirst__ = function(data) {
    var cs, tmp;
    if (data.js != null) {
      return addVariablesAndShowFirst_(getDeclaredVariables(data.js));
    } else if (data.sender === 'autoComplete') {
      tmp = cs.split(/\r?\n/).slice(0, csErrorLine(event.data.error) - 1);
      cs = tmp.join('\n');
      return worker.postMessage({
        sender: 'autoComplete-retry',
        callback: extractVariablesAndShowFirst__,
        source: cs,
        options: {
          bare: true
        }
      });
    } else {
      return addVariablesAndShowFirst_([]);
    }
  };

  window.AutoComplete = AutoComplete;

  if ((_ref = window.csWorker) == null) {
    window.csWorker = new Worker('coffee-script-worker.js');
  }

  window.csWorker.addEventListener('message', (function(event) {
    if (!/autoComplete/.test(event.data.sender)) {
      return;
    }
    return event.data.callback(data);
  }), false);

}).call(this);
