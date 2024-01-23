# Xtext tool

The Xtext tool enables students to write a grammar and generate a working online editor from it.
The tool uses a backend stateful server that maintains the currently generated editors and assigns a unique URL to each of them.
Each editor is generated so it can provide access to the Xtext-generated meta-model (under `<editor-url>/xtext-resources/generated/meta-model.ecore`) and provides a new [platform tool](/xtext/editorserver/editor_tool.json) offering functions for transforming a model to XMI and to an SVG object diagram, respectively.
