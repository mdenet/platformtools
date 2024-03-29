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
            {token: "string", regex: "'''", next: "template-string"},
            {token: "string", regex: '["](?:(?:\\\\.)|(?:[^"\\\\]))*?["]'},
            {token: "string", regex: "['](?:(?:\\\\.)|(?:[^'\\\\]))*?[']"},
            {token: "constant.numeric", regex: "[+-]?\\d+(?:(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)?\\b"},
            {token: "constant.numeric", regex: "0[xX][0-9a-fA-F]+\\b"},
            {token: "lparen", regex: "[\\[({]"},
            {token: "rparen", regex: "[\\])}]"},
            {token: "code-embed-end", regex: "»", next: "template-string"}, // This is a bit naughty perhaps and will cause weird effects if students just type a closing guillemet
            {token: "keyword", regex: "\\b(?:" + keywords + ")\\b"}
        ],
        "comment": [
            {token: "comment", regex: ".*?\\*\\/", next : "start"},
            {token: "comment", regex: ".+"}
        ],
        "template-string": [
            {token: "string", regex: "[^«]*'''", next: "start"},
            {token: "string", "regex": "[^«]+"},
            {token: "code-embed-start", regex: "«", next: "start"} // This is a bit naughty perhaps
        ]
    };
    this.normalizeRules();
};

oop.inherits(xtendHighlightRules, TextHighlightRules);

exports.xtendHighlightRules = xtendHighlightRules;
});

define("ace/mode/xtend",["require","exports","module","ace/lib/oop","ace/mode/behaviour","ace/token_iterator","ace/mode/text","ace/mode/xtend_highlight_rules"], function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;
var xtendHighlightRules = require("./xtend_highlight_rules").xtendHighlightRules;
var Behaviour = require("../mode/behaviour").Behaviour;

var XtendBehaviour = function() {
    this.add("open_guillemet", "insertion", function (state, action, editor, session, text) {
        if (text == '<') {
            // If this is the second '<' in a sequence of two, replace both with a guillemet pair
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            if (cursor.column > 0) {
                var leftChar = line.substring(cursor.column - 1, cursor.column);

                if (leftChar == '<') {
                    // Change the editor selection to ensure the previous '<' is also deleted.
                    var sel = editor.getSelection();
                    sel.setAnchor(cursor.row, cursor.column - 1);
                    sel.selectTo(cursor.row, cursor.column);
                    return {
                        text: "«»",
                        selection: [1, 1]
                    };
                }
            }
        }
    });

    this.add("close_guillemet", "insertion", function (state, action, editor, session, text) {
        if (text == '>') {
            // If this is the second '>' in a sequence of two, replace both with a closing guillemet
            var cursor = editor.getCursorPosition();
            var line = session.doc.getLine(cursor.row);
            if (cursor.column > 0) {
                var leftChar = line.substring(cursor.column - 1, cursor.column);

                if (leftChar == '>') {
                    // Change the editor selection to ensure the previous '>' is also deleted.
                    var sel = editor.getSelection();
                    sel.setAnchor(cursor.row, cursor.column - 1);
                    sel.selectTo(cursor.row, cursor.column);
                    return {
                        text: "»",
                        selection: [0, 0]
                    };
                }
            }
       }
    });
};
oop.inherits(XtendBehaviour, Behaviour);

var Mode = function() {
    this.HighlightRules = xtendHighlightRules;
    // this.$behaviour = this.$defaultBehaviour;
    this.$behaviour = new XtendBehaviour();
    this.lineCommentStart = "//";
};
oop.inherits(Mode, TextMode);

(function() {
    this.$id = "ace/mode/xtend";
    this.snippetFileId = "ace/snippets/xtend";
}).call(Mode.prototype);

exports.Mode = Mode;

});
