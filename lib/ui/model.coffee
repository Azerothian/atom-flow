EventEmitter = require("events").EventEmitter #require "eventemitter"
class Model extends EventEmitter
	constructor: () ->

	get: (name) =>
		if @[name]?
			return @[name];
		return null;
	set: (name, value) =>
		if @[name] isnt value
			@emit name, [value];
		@[name] = value;
	on: (name, func) =>
		@addListener name, func;
module.exports = Model
