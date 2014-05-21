{$} = require "atom"
joint = require "./util/joint"
{Graph, Link, Paper} = joint.dia
_ = require "lodash"
V = joint.V

module.exports = class FlowView extends View


  getTitle: ->
    return "Flow"

  @content: ->
    @div class: 'flow'

  initialize: (serializeState) ->

    el = $("<div></div>")
    link = (a, b) ->
      new pn.Link(
        source:
          id: a.id
          selector: ".root"

        target:
          id: b.id
          selector: ".root"
      )
    fireTransition = (t, sec) ->
      inbound = graph.getConnectedLinks(t,
        inbound: true
      )
      outbound = graph.getConnectedLinks(t,
        outbound: true
      )
      placesBefore = _.map(inbound, (link) ->
        graph.getCell link.get("source").id
      )
      placesAfter = _.map(outbound, (link) ->
        graph.getCell link.get("target").id
      )
      isFirable = true
      _.each placesBefore, (p) ->
        isFirable = false  if p.get("tokens") is 0
        return

      if isFirable
        _.each placesBefore, (p) ->

          # Let the execution finish before adjusting the value of tokens. So that we can loop over all transitions
          # and call fireTransition() on the original number of tokens.
          _.defer ->
            p.set "tokens", p.get("tokens") - 1
            return

          token = V("circle",
            r: 5
            fill: "red"
          )
          link = _.find(inbound, (l) ->
            l.get("source").id is p.id
          )
          $(paper.viewport).append token.node
          token.animateAlongPath
            dur: sec + "s"
            repeatCount: 1
          , paper.findViewByModel(link).$(".connection")[0]
          _.delay (->
            token.remove()
            return
          ), sec * 1000
          return

        _.each placesAfter, (p) ->
          token = V("circle",
            r: 5
            fill: "red"
          )
          link = _.find(outbound, (l) ->
            l.get("target").id is p.id
          )
          $(paper.viewport).append token.node
          token.animateAlongPath
            dur: sec + "s"
            repeatCount: 1
          , paper.findViewByModel(link).$(".connection")[0]
          _.delay (->
            p.set "tokens", p.get("tokens") + 1
            token.remove()
            return
          ), sec * 1000
          return

      return
    simulate = ->
      transitions = [
        pProduce
        pSend
        cAccept
        cConsume
      ]
      _.each transitions, (t) ->
        fireTransition t, 1  if Math.random() < 0.7
        return

      setInterval (->
        _.each transitions, (t) ->
          fireTransition t, 1  if Math.random() < 0.7
          return

        return
      ), 2000
    stopSimulation = (simulationId) ->
      clearInterval simulationId
      return
    graph = new joint.dia.Graph
    paper = new joint.dia.Paper(
      el: el
      width: 800
      height: 350
      gridSize: 10
      perpendicularLinks: true
      model: graph
    )
    pn = joint.shapes.pn
    pReady = new pn.Place(
      position:
        x: 140
        y: 50

      attrs:
        ".label":
          text: "ready"

      tokens: 1
    )
    pIdle = new pn.Place(
      position:
        x: 140
        y: 260

      attrs:
        ".label":
          text: "idle"

      tokens: 2
    )
    buffer = new pn.Place(
      position:
        x: 350
        y: 160

      attrs:
        ".label":
          text: "buffer"

      tokens: 12
    )
    cAccepted = new pn.Place(
      position:
        x: 550
        y: 50

      attrs:
        ".label":
          text: "accepted"

      tokens: 1
    )
    cReady = new pn.Place(
      position:
        x: 560
        y: 260

      attrs:
        ".label":
          text: "ready"

      tokens: 3
    )
    pProduce = new pn.Transition(
      position:
        x: 50
        y: 160

      attrs:
        ".label":
          text: "produce"
    )
    pSend = new pn.Transition(
      position:
        x: 270
        y: 160

      attrs:
        ".label":
          text: "send"
    )
    cAccept = new pn.Transition(
      position:
        x: 470
        y: 160
 
      attrs:
        ".label":
          text: "accept"
    )
    cConsume = new pn.Transition(
      position:
        x: 680
        y: 160

      attrs:
        ".label":
          text: "consume"
    )
    graph.addCell [
      pReady
      pIdle
      buffer
      cAccepted
      cReady
      pProduce
      pSend
      cAccept
      cConsume
    ]
    graph.addCell [
      link(pProduce, pReady)
      link(pReady, pSend)
      link(pSend, pIdle)
      link(pIdle, pProduce)
      link(pSend, buffer)
      link(buffer, cAccept)
      link(cAccept, cAccepted)
      link(cAccepted, cConsume)
      link(cConsume, cReady)
      link(cReady, cAccept)
    ]
    simulationId = simulate()

    $(@get(0)).append(el);
  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()
  unsubscribe: ->
