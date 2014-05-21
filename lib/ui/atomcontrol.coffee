{$} = require 'atom'
Control = require "./control"
class AtomControl extends Control
	constructor: (@el) ->
		super
		if @el?
			@isRendered = true

module.exports = AtomControl
