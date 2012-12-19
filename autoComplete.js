// Generated by CoffeeScript 1.4.0

/*
# AutoComplete for CodeMirror in CoffeeScript
# (C) 2012 ICHIKAWA, Yuji (New 3 Rs)
*/


(function() {
  var AutoComplete, COFFEE_KEYWORDS, COMMON_KEYWORDS, CORE_CLASSES, CS_KEYWORDS_COMPLETE, CS_OPERATORS, DATE_PROPERTIES, JS_KEYWORDS, JS_KEYWORDS_COMPLETE, JS_OPERATORS, OPERATORS, OPERATORS_WITH_EQUAL, UTC_PROPERTIES, classes, cs_keywords, cs_operators, e, functions, globalProperties, globalPropertiesPlusCSKeywords, globalPropertiesPlusJSKeywords, js_keywords, js_operators, variables, _i, _len, _ref;

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

  js_keywords = COMMON_KEYWORDS.concat(JS_KEYWORDS).sort();

  cs_keywords = COMMON_KEYWORDS.concat(COFFEE_KEYWORDS).sort();

  CS_KEYWORDS_COMPLETE = {
    "if": ['else', 'then else'],
    "for": ['in', 'in when', 'of', 'of when'],
    "try": ['catch finally', 'catch'],
    "class": ['extends'],
    "switch": ['when else', 'when', 'when then else', 'when then']
  };

  JS_KEYWORDS_COMPLETE = {};

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

  AutoComplete = (function() {

    function AutoComplete(cm, text) {
      this.cm = cm;
      this.char = text.charAt(text.length - 1);
    }

    AutoComplete.prototype.complete = function() {
      var cursor;
      if (this.candidates != null) {
        return;
      }
      this.candidates = [];
      cursor = this.cm.getCursor();
      switch (this.cm.getOption('mode')) {
        case 'coffeescript':
          this.setCandidates_(cursor, globalPropertiesPlusCSKeywords, CS_KEYWORDS_COMPLETE);
          break;
        case 'javascript':
          this.setCandidates_(cursor, globalPropertiesPlusJSKeywords, JS_KEYWORDS_COMPLETE);
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

    AutoComplete.prototype.setCandidates_ = function(cursor, globalPropertiesPlusKeywords, keywords_complete) {
      var candidates, key, object, pos, propertyChain, target, token;
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
        return this.candidates = candidates.filter(function(e) {
          return new RegExp('^' + target).test(e);
        }).map(function(e) {
          return e.slice(target.length);
        });
      } else if (this.char === ' ') {
        token = this.cm.getTokenAt({
          line: cursor.line,
          ch: cursor.ch - 1
        });
        if (keywords_complete.hasOwnProperty(token.string)) {
          return this.candidates = keywords_complete[token.string];
        }
      }
    };

    return AutoComplete;

  })();

  window.AutoComplete = AutoComplete;

}).call(this);
