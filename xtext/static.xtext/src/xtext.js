import {define} from "ace-builds";

define("ace/mode/xtext_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var xtextHighlightRules = function() {
 
    var keywords = (
        "EOF|as|current|enum|false|fragment|generate|grammar|hidden|import|returns|terminal|true|with"
    );

    var builtinConstants = (
        ""
    );

    var builtinFunctions = (
        ""
    );

    var dataTypes = (
        ""
    );

    var keywordMapper = this.createKeywordMapper({
        "support.function": builtinFunctions,
        "keyword": keywords,
        "constant.language": builtinConstants,
        "storage.type": dataTypes
    }, "identifier", true);

    this.$rules = {
        "start": [
            {token: "comment", regex: "\\/\\/.*$"},
            {token: "comment", regex: "\\/\\*", next : "comment"},
            {token: "string", regex: '["](?:(?:\\\\.)|(?:[^"\\\\]))*?["]'},
            {token: "string", regex: "['](?:(?:\\\\.)|(?:[^'\\\\]))*?[']"},
            {token: "constant.numeric", regex: "[+-]?\\d+(?:(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)?\\b"},
            {token: "lparen", regex: "[\\[({]"},
            {token: "rparen", regex: "[\\])}]"},
            {token: "keyword", regex: "\\b(?:" + keywords + ")\\b"}
        ],
        "comment": [
            {token: "comment", regex: ".*?\\*\\/", next : "start"},
            {token: "comment", regex: ".+"}
        ]
    };
    this.normalizeRules();
};

oop.inherits(xtextHighlightRules, TextHighlightRules);

exports.xtextHighlightRules = xtextHighlightRules;
});

define("ace/mode/xtext",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/xtext_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var xtextHighlightRules = require("./xtext_highlight_rules").xtextHighlightRules;

var Mode = function() {
    this.HighlightRules = xtextHighlightRules;
    this.$behaviour = this.$defaultBehaviour;
    this.lineCommentStart = "//";
};
oop.inherits(Mode, TextMode);

(function() {
    this.$id = "ace/mode/xtext";
    this.snippetFileId = "ace/snippets/xtext";
}).call(Mode.prototype);

exports.Mode = Mode;

});
