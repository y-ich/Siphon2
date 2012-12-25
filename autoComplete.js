// Generated by CoffeeScript 1.4.0

/*
# AutoComplete for CodeMirror in CoffeeScript
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
*/


(function() {
  var AutoComplete, COFFEE_KEYWORDS, COMMON_KEYWORDS, CS_KEYWORDS_ASSIST, CS_OPERATORS, DATE_PROPERTIES, JS_KEYWORDS, JS_KEYWORDS_ASSIST, JS_OPERATORS, OPERATORS, OPERATORS_WITH_EQUAL, UTC_PROPERTIES, classes, csGetTokenAt, cs_keywords, cs_operators, e, functions, getCharAt, globalProperties, globalPropertiesPlusCSKeywords, globalPropertiesPlusJSKeywords, js_keywords, js_operators, variables, _i, _len, _ref;

  COMMON_KEYWORDS = ['break', 'catch', 'continue', 'debugger', 'delete', 'do', 'else', 'false', 'finally', 'for', 'if', 'in', 'instanceof', 'new', 'null', 'return', 'switch', 'this', 'throw', 'true', 'try', 'typeof', 'while'];

  JS_KEYWORDS = ['case', 'default', 'function', 'var', 'void', 'with'];

  COFFEE_KEYWORDS = ['by', 'class', 'extends', 'loop', 'no', 'of', 'off', 'on', 'super', 'then', 'undefined', 'unless', 'until', 'when', 'yes'];

  OPERATORS_WITH_EQUAL = ['-', '+', '*', '/', '%', '<<', '>>', '>>>', '<', '>', '&', '|', '^', '!', '='];

  OPERATORS = ['&&', '||', '~'];

  JS_OPERATORS = ['++', '--', '===', '!=='];

  CS_OPERATORS = ['->', '=>', 'and', 'or', 'is', 'isnt', 'not', '?', '?='];

  cs_operators = OPERATORS.concat(CS_OPERATORS).concat(OPERATORS_WITH_EQUAL.concat(OPERATORS_WITH_EQUAL.map(function(e) {
    return e + '=';
  }))).sort();

  js_operators = OPERATORS.concat(JS_OPERATORS).concat(OPERATORS_WITH_EQUAL.concat(OPERATORS_WITH_EQUAL.map(function(e) {
    return e + '=';
  }))).sort();

  UTC_PROPERTIES = ['Date', 'Day', 'FullYear', 'Hours', 'Milliseconds', 'Minutes', 'Month', 'Seconds'];

  DATE_PROPERTIES = ['Time', 'Year'].concat(UTC_PROPERTIES.reduce((function(a, b) {
    return a.concat([b, 'UTC' + b]);
  }), []));

  js_keywords = COMMON_KEYWORDS.concat(JS_KEYWORDS).sort();

  cs_keywords = COMMON_KEYWORDS.concat(COFFEE_KEYWORDS).sort();

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

  globalProperties = (function() {
    var _results;
    _results = [];
    for (e in window) {
      _results.push(e);
    }
    return _results;
  })();

  globalPropertiesPlusJSKeywords = globalProperties.concat(js_keywords).sort();

  globalPropertiesPlusCSKeywords = globalProperties.concat(cs_keywords).sort();

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

  csGetTokenAt = function(editor, pos) {
    var nextToken, token;
    token = editor.getTokenAt(pos);
    if (token.string.charAt(0) === '.' && token.start === pos.ch - 1) {
      token.className = null;
      token.string = '.';
      token.end = pos.ch;
    } else if (/^\.[\w$_]+$/.test(token.string)) {
      token.className = "property";
      token.start += 1;
      token.string = token.string.slice(1);
    } else if (/^\.\s+$/.test(token.string)) {
      token.className = null;
      token.start += 1;
      token.string = token.string.slice(1);
    } else if (token.className === 'variable') {
      nextToken = editor.getTokenAt({
        line: pos.line,
        ch: token.start
      });
      if (nextToken.string.charAt(0) === '.') {
        token.className = 'property';
      }
    }
    return token;
  };

  getCharAt = function(cm, pos) {
    return cm.getLine(pos.line).charAt(pos.ch);
  };

  AutoComplete = (function() {

    function AutoComplete(cm) {
      var cursor;
      this.cm = cm;
      switch (this.cm.getOption('mode')) {
        case 'coffeescript':
          this.globalPropertiesPlusKeywords = globalPropertiesPlusCSKeywords;
          this.keywordsAssist = CS_KEYWORDS_ASSIST;
          this.getTokenAt = function(pos) {
            return csGetTokenAt(this.cm, pos);
          };
          break;
        case 'javascript':
          this.globalPropertiesPlusKeywords = globalPropertiesPlusJSKeywords;
          this.keywordsAssist = JS_KEYWORDS_ASSIST;
          this.getTokenAt = function(pos) {
            return this.cm.getTokenAt(pos);
          };
      }
      if (this.candidates != null) {
        return;
      }
      this.candidates = [];
      cursor = this.cm.getCursor();
      this.setCandidates_(cursor);
      if (this.candidates.length > 0) {
        this.index = 0;
        this.cm.replaceRange(this.candidates[this.index], cursor);
        this.start = cursor;
        this.end = this.cm.getCursor();
        this.cm.setSelection(this.start, this.end);
      }
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

    AutoComplete.prototype.setCandidates_ = function(cursor) {
      var bracketStack, breakFlag, candidates, object, pos, propertyChain, target, token, value;
      propertyChain = [];
      pos = cursor;
      bracketStack = [];
      breakFlag = false;
      while (true) {
        token = this.getTokenAt(pos);
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
        pos = {
          line: cursor.line,
          ch: token.start
        };
        if (breakFlag || pos.ch === 0) {
          break;
        }
      }
      propertyChain.reverse();
      if (propertyChain.length === 2 && /^\s+$/.test(propertyChain[1].string)) {
        if (this.keywordsAssist.hasOwnProperty(propertyChain[0].string)) {
          this.candidates = this.keywordsAssist[propertyChain[0].string];
        }
        return;
      } else if (propertyChain.length > 1 && /^\s+$/.test(propertyChain[propertyChain.length - 1].string) && propertyChain[propertyChain.length - 2].className === 'property') {
        return;
      } else if (propertyChain.length === 1) {
        candidates = /^\s*$/.test(propertyChain[0].string) ? [] : this.globalPropertiesPlusKeywords;
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
          candidates.sort();
        } catch (err) {
          console.log(err);
          return;
        }
      }
      target = /^(\s*|\.)$/.test(propertyChain[propertyChain.length - 1].string) ? '' : propertyChain[propertyChain.length - 1].string;
      return this.candidates = candidates.filter(function(e) {
        return new RegExp('^' + target).test(e);
      }).map(function(e) {
        return e.slice(target.length);
      });
    };

    return AutoComplete;

  })();

  window.AutoComplete = AutoComplete;

}).call(this);
