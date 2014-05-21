{$} = require "atom"
Model = require "./model"
Chains = require "./chains"
Util = require "./util"
Promise = require "bluebird"
log = console.log

Tree = require "./Tree"

class Control extends Tree

  constructor: () ->
    super
    @isRendered = false
    @model.on "Name", (value) =>
      @Name = value
      @createId(value)


  addChild: (child) =>
    promise = super
    return new Promise (resolve, reject) =>
      promise.then () =>
        if @isRendered
          return child.render().then(resolve, reject)
        else
          return resolve()
      , reject

  render: () =>
    return new Promise (resolve, reject) =>
      chain = new Chains()
      if @["OnInit"]?
        chain.push @["OnInit"], @, ["OnInit"]
      if @["OnRender"]?
        chain.push @["OnRender"], @, ["OnRender"]
      chain.push @renderChildren, @, ["renderChildren"]
      chain.push @renderFinished, @, ["renderFinished"]
      if @["OnAfterRender"]?
        chain.push @["OnAfterRender"], @, ["OnAfterRender"]

      #console.log("Control: Render", Chains.length)

      return chain.run().then () =>
        #log("Control - Finished Rendering")
        return resolve()
      , reject
      .caught () =>
        console.log(arguments)

  renderChildren: () =>
    return new Promise (resolve, reject) =>
      childrenLength = @getLengthOfChildren()
      #log "Control: renderChildren" , childrenLength
      chain = new Chains()
      for chain of @children
        chain.push @children[child].render, @children[child]
      return chain.run().then resolve, reject

  renderFinished: () =>
    return new Promise (resolve, reject) =>
      #log("Control: renderFinished")
      @isRendered = true
      return resolve()

  OnLoadFinished: () =>
    return new Promise (resolve, reject) =>
      if @children? and @getLengthOfChildren() > 0
        chain = new Chains()
        for child in @children
          chain.push child.OnLoadFinished, child, []
        return chain.run().then resolve, reject
      return resolve()

  dispose: () =>
    promise = super
    return new Promise (resolve, reject) =>
      promise.then () =>
        @isRendered = false
        return resolve()
      , reject


module.exports = Control
