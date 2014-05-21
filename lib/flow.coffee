FlowView = require './flow-view'
# {View, ScrollView, $} = require 'atom'
#AtomControl = require "./ui/atomcontrol"

###
class AtomView extends ScrollView
  constructor: () ->
    super

  getTitle: ->
    return "Flow"

  @content: ->
    @div class: 'flow'

  initialize: (serializeState) ->
    @control = new AtomControl(@)
    @control.render().then () =>
      console.log "RENDER COMPLETO"
  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
###

class Flow
  activate: (state) =>
    @views = []
    console.log "FLOW OPEN"
    atom.workspaceView.command "flow:open", @createView

  createView: =>
    flowView = new FlowView()
    pane = atom.workspace.getActivePane()
    item = pane.addItem flowView
    @views.push item
  deactivate: =>
    for view in views
      view.destroy()

  serialize: =>
    #flowViewState: @flowView.serialize()

module.exports = new Flow
