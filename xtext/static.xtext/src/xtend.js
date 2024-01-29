import {define} from "ace-builds";

define("ace/mode/xtend_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var xtendHighlightRules = function() {
 
    var keywords = (
        "AFTER|BEFORE|ELSE|ELSEIF|ENDFOR|ENDIF|FOR|IF|SEPARATOR|abstract|annotation|as|case|catch|class|create|def|default|dispatch|do|else|enum|extends|extension|false|final|finally|for|if|implements|import|instanceof|interface|native|new|null|override|package|private|protected|public|return|static|strictfp|super|switch|synchronized|throw|throws|transient|true|try|typeof|val|var|volatile|while"
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
            {token: "constant.numeric", regex: "0[xX][0-9a-fA-F]+\\b"},
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

oop.inherits(xtendHighlightRules, TextHighlightRules);

exports.xtendHighlightRules = xtendHighlightRules;
});

define("ace/mode/xtend",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/xtend_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var xtendHighlightRules = require("./xtend_highlight_rules").xtendHighlightRules;

var Mode = function() {
    this.HighlightRules = xtendHighlightRules;
    this.$behaviour = this.$defaultBehaviour;
};
oop.inherits(Mode, TextMode);

(function() {
    this.$id = "ace/mode/xtend";
    this.snippetFileId = "ace/snippets/xtend";
}).call(Mode.prototype);

exports.Mode = Mode;

});
