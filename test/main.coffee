
###
Promise = require "bluebird"

EventEmitter = require("events").EventEmitter


class Pipe


class Module
  constructor: (@options) ->
    @in = {}
    @out

class TestModule extends Module
  constructor: () ->
    super
    @in["LOG"] = {
      type: "any"
    }

  LOG: () =>
    return new Pipe {
      in:
        "WRITE"
    }


class Graph
  constructor: () ->
    @components = {}


class OutPort
  constructor: (@pipe, @options) ->
    {@type} = @options
  emit: () =>




class Pipe extends EventEmitter
  constructor: (@options, @func) ->
    @in = {}
    @in.ports = {}

    @out = {}
    @out.ports = {}
    @out.funcs = {}

    for outPort of @options.outPorts
      @out.funcs[outPort] = (value) =>
        @emit "out:#{outPort}", value
  then: (resolve, reject) =>
    @func(@in, @out, resolve, reject)



  then: () =>
    resolve = () =>

    reject = () =>

    @func resolve, reject





class Test
  SayHello: () =>
    return new Pipe {
      outPorts:
        "OUTPORT":
          type: "any"

    }, (in, out, resolve, reject) =>
      ports.outPorts["OUTPORT"]("Hello World")
      return resolve()

  Log: () =>
    return new Pipe {
      inPorts:
        "WRITE":
          type: "any"

    }, (ports, resolve, reject) =>


class Gen
  constructor: () ->
    @components = {}

  addComponent: (name, init) =>
    @components[name] = init

###





chai = require 'chai'
chai.should()

describe 'Paper Joint', ->
  it 'should have a name', ->
    Vectorizer = require "../lib/vectorizer"
    console.log "yey"
