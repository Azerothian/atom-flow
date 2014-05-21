Promise = require "bluebird"
Model = require "./model"
Util = require "./util"
class Tree

  constructor: () ->
    @parent = null
    @children = {}
    @model = new Model()

  getAllParents: () =>
    parent = @parent
    data = []

    loop
      break if not parent?
      data.push parent
      parent = parent.parent

    return data
  getId: () =>
    id = model.get "Id"
    if not id?
      return @createId()
    return id

  createId: (name = @Name) =>
    id = @model.get "Id"
    if name?
      realid = ""
      parents = @paths.getAllParents()

      for parent in parents
        if parent.Name?
          realid = "#{parent.Name}_#{realid}"
      realid = "#{realid}#{name}"
      @model.set "Id", realid

      return realid
    else if not id?
      id = Util.GenerateGuid()
      @model.set "Id", id
    return id
  addChild: (child) =>
    return new Promise (resolve, reject) =>
      if child.model.get("Id") == @model.get("Id")
        return reject("Cannot add same control to itself")
      child.model.set "ParentId", @model.get("Id")
      child.parent = @
      child.createId()
      #child.setModel("Name", name)
      @children[child.model.get("Id")] = child
      return resolve()

  getParentByName: (name) =>
    return new Promise (resolve, reject) =>
      if @model?
        controlName = @model.get "Name"
        if controlName is name
          return resolve(@)
      if @parent?
        if @parent.getParentByName?
          return @parent.getParentByName(name).then resolve, reject
      return reject()

  removeChild: (id) =>
    return new Promise (resolve, reject) =>
      if not @children[id]?
        return reject("Child id not found in the children collection")
      delete @children[id]
      return resolve()


  getLengthOfChildren: () =>
    return Util.getLengthOfObject(@children)

  clearChildren: () =>
    return new Promise (resolve, reject) =>
      promises = new Promises()
      for child in @children
        promises.push child.clearChildren, child
        promises.push child.dispose, child
        promises.push child.removeChild, child, [child]
      return promises.chain().then () =>
        return resolve()

  OnLoadFinished: () =>
    return new Promise (resolve, reject) =>
      if @children? and @getLengthOfChildren() > 0
        promises = new Promises()
        for child in @children
          promises.push child.OnLoadFinished, child, []
        return promises.chain().then resolve, reject
      return resolve()

  dispose: () =>
    return new Promise (resolve, reject) =>
      promises = new Promises()
      for child in @children
        promises.push child.dispose, child
      if @["OnDispose"]?
        promises.push @["OnDispose"], @ #this will get executed after all children dispose actions
      return promises.chain().then resolve, reject

module.exports = Tree
