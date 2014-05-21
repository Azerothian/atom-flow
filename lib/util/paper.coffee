#      JointJS library.
#      (c) 2011-2013 client IO
{$} = require "atom"
Backbone = require "backbone"
_ = require "underscore"
joint = require "jointjs"
Backbone.$ = $
g = require "./util/geometry"
V = require "./util/vectorizer"

class Paper extends Backbone.View
  options:
    width: 800
    height: 600
    gridSize: 50
    perpendicularLinks: false
    elementView: joint.dia.ElementView
    linkView: joint.dia.LinkView
  # Defines what link model is added to the graph after an user clicks on an active magnet.
  # Value could be the Backbone.model or a function returning the Backbone.model
  # defaultLink: function(elementView, magnet) { return condition ? new customLink1() : new customLink2() }
  defaultLink: new joint.dia.Link
  model: new Backbone.Model
  events:
    mousedown: "pointerdown"
    dblclick: "mousedblclick"
    touchstart: "pointerdown"
    mousemove: "pointermove"
    touchmove: "pointermove"

  # Check whether to add a new link to the graph when user clicks on an a magnet.
  validateMagnet: (cellView, magnet) ->
    magnet.getAttribute("magnet") isnt "passive"


  # Check whether to allow or disallow the link connection while an arrowhead end (source/target)
  # being changed.
  validateConnection: (cellViewS, magnetS, cellViewT, magnetT, end, linkView) ->
    ((if end is "target" then cellViewT else cellViewS)) instanceof joint.dia.ElementView



  initialize: () ->
    console.log "PAPS", @
    #@model = new Backbone.Model
    #_.bindAll this, "addCell", "sortCells", "resetCells", "pointerup"
    @svg = V("svg").node
    @viewport = V("g").node

    # Append `<defs>` element to the SVG document. This is useful for filters and gradients.
    V(@svg).append V("defs").node
    V(@viewport).attr class: "viewport"
    V(@svg).append @viewport
    @$el.append @svg
    @setDimensions()
    @listenTo @model, "add", @addCell
    @listenTo @model, "reset", @resetCells
    @listenTo @model, "sort", @sortCells
    $(document).on "mouseup touchend", @pointerup
    return

  remove: =>
    $(document).off "mouseup touchend", @pointerup
    Backbone.View::remove.call this
    return

  setDimensions: (width, height) =>
    @options.width = width  if width
    @options.height = height  if height
    V(@svg).attr "width", @options.width
    V(@svg).attr "height", @options.height
    @trigger "resize"
    return


  # Expand/shrink the paper to fit the content. Snap the width/height to the grid
  # defined in `gridWidth`, `gridHeight`. `padding` adds to the resulting width/height of the paper.
  fitToContent: (gridWidth, gridHeight, padding) =>
    gridWidth = gridWidth or 1
    gridHeight = gridHeight or 1
    padding = padding or 0

    # Calculate the paper size to accomodate all the graph's elements.
    bbox = V(@viewport).bbox(true, @svg)
    calcWidth = Math.ceil((bbox.width + bbox.x) / gridWidth) * gridWidth
    calcHeight = Math.ceil((bbox.height + bbox.y) / gridHeight) * gridHeight
    calcWidth += padding
    calcHeight += padding

    # Change the dimensions only if there is a size discrepency
    @setDimensions calcWidth or @options.width, calcHeight or @options.height  if calcWidth isnt @options.width or calcHeight isnt @options.height
    return

  createViewForModel: (cell) =>
    view = undefined
    type = cell.get("type")
    module = type.split(".")[0]
    entity = type.split(".")[1]

    # If there is a special view defined for this model, use that one instead of the default `elementView`/`linkView`.
    if joint.shapes[module] and joint.shapes[module][entity + "View"]
      view = new joint.shapes[module][entity + "View"](
        model: cell
        interactive: @options.interactive
      )
    else if cell instanceof joint.dia.Element
      view = new @options.elementView(
        model: cell
        interactive: @options.interactive
      )
    else
      view = new @options.linkView(
        model: cell
        interactive: @options.interactive
      )
    view

  addCell: (cell) =>
    console.log "addCell"
    view = @createViewForModel(cell)
    V(@viewport).append view.el
    view.paper = this
    view.render()

    # This is the only way to prevent image dragging in Firefox that works.
    # Setting -moz-user-select: none, draggable="false" attribute or user-drag: none didn't help.
    $(view.el).find("image").on "dragstart", ->
      false

    return

  resetCells: (cellsCollection) =>
    $(@viewport).empty()
    cells = cellsCollection.models.slice()

    # Make sure links are always added AFTER elements.
    # They wouldn't find their sources/targets in the DOM otherwise.
    cells.sort (a, b) ->
      (if a instanceof joint.dia.Link then 1 else -1)

    _.each cells, @addCell, this

    # Sort the cells in the DOM manually as we might have changed the order they
    # were added to the DOM (see above).
    @sortCells()
    return

  sortCells: =>

    # Run insertion sort algorithm in order to efficiently sort DOM elements according to their
    # associated model `z` attribute.
    $cells = $(@viewport).children("[model-id]")
    cells = @model.get("cells")

    # Using the jquery.sortElements plugin by Padolsey.
    # See http://james.padolsey.com/javascript/sorting-elements-with-jquery/.
    $cells.sortElements (a, b) ->
      cellA = cells.get($(a).attr("model-id"))
      cellB = cells.get($(b).attr("model-id"))
      (if (cellA.get("z") or 0) > (cellB.get("z") or 0) then 1 else -1)

    return

  scale: (sx, sy, ox, oy) =>
    unless ox
      ox = 0
      oy = 0

    # Remove previous transform so that the new scale is not affected by previous scales, especially
    # the old translate() does not affect the new translate if an origin is specified.
    V(@viewport).attr "transform", ""

    # TODO: V.scale() doesn't support setting scale origin. #Fix
    V(@viewport).translate -ox * (sx - 1), -oy * (sy - 1)  if ox or oy
    V(@viewport).scale sx, sy
    @trigger "scale", ox, oy
    this

  rotate: (deg, ox, oy) =>

    # If the origin is not set explicitely, rotate around the center. Note that
    # we must use the plain bounding box (`this.el.getBBox()` instead of the one that gives us
    # the real bounding box (`bbox()`) including transformations).
    if _.isUndefined(ox)
      bbox = @viewport.getBBox()
      ox = bbox.width / 2
      oy = bbox.height / 2
    V(@viewport).rotate deg, ox, oy
    return


  # Find the first view climbing up the DOM tree starting at element `el`. Note that `el` can also
  # be a selector or a jQuery object.
  findView: (el) =>
    $el = @$(el)
    return undefined  if $el.length is 0 or $el[0] is @el
    return $el.data("view")  if $el.data("view")
    @findView $el.parent()


  # Find a view for a model `cell`. `cell` can also be a string representing a model `id`.
  findViewByModel: (cell) =>
    id = (if _.isString(cell) then cell else cell.id)
    $view = @$("[model-id=\"" + id + "\"]")
    return $view.data("view")  if $view.length
    undefined


  # Find all views at given point
  findViewsFromPoint: (p) =>
    p = g.point(p)
    views = _.map(@model.getElements(), @findViewByModel)
    _.filter views, (view) ->
      g.rect(view.getBBox()).containsPoint p



  # Find all views in given area
  findViewsInArea: (r) =>
    r = g.rect(r)
    views = _.map(@model.getElements(), @findViewByModel)
    _.filter views, (view) ->
      r.intersect g.rect(view.getBBox())


  getModelById: (id) =>
    @model.getCell id

  snapToGrid: (p) =>

    # Convert global coordinates to the local ones of the `viewport`. Otherwise,
    # improper transformation would be applied when the viewport gets transformed (scaled/rotated).
    localPoint = V(@viewport).toLocalPoint(p.x, p.y)
    x: g.snapToGrid(localPoint.x, @options.gridSize)
    y: g.snapToGrid(localPoint.y, @options.gridSize)

  getDefaultLink: (cellView, magnet) =>

    # default link is a function producing link model

    # default link is the Backbone model
    (if _.isFunction(@options.defaultLink) then @options.defultLink.call(this, cellView, magnet) else @options.defaultLink.clone())


  # Interaction.
  # ------------
  mousedblclick: (evt) =>
    evt.preventDefault()
    evt = joint.util.normalizeEvent(evt)
    view = @findView(evt.target)
    localPoint = @snapToGrid(
      x: evt.clientX
      y: evt.clientY
    )
    if view
      view.pointerdblclick evt, localPoint.x, localPoint.y
    else
      @trigger "blank:pointerdblclick", evt, localPoint.x, localPoint.y
    return

  pointerdown: (evt) =>
    evt.preventDefault()
    evt = joint.util.normalizeEvent(evt)
    view = @findView(evt.target)
    localPoint = @snapToGrid(
      x: evt.clientX
      y: evt.clientY
    )
    if view
      @sourceView = view
      view.pointerdown evt, localPoint.x, localPoint.y
    else
      @trigger "blank:pointerdown", evt, localPoint.x, localPoint.y
    return

  pointermove: (evt) =>
    evt.preventDefault()
    evt = joint.util.normalizeEvent(evt)
    if @sourceView
      localPoint = @snapToGrid(
        x: evt.clientX
        y: evt.clientY
      )
      @sourceView.pointermove evt, localPoint.x, localPoint.y
    return

  pointerup: (evt) =>
    evt = joint.util.normalizeEvent(evt)
    localPoint = @snapToGrid(
      x: evt.clientX
      y: evt.clientY
    )
    if @sourceView
      @sourceView.pointerup evt, localPoint.x, localPoint.y

      #"delete sourceView" occasionally throws an error in chrome (illegal access exception)
      @sourceView = null
    else
      @trigger "blank:pointerup", evt, localPoint.x, localPoint.y
    return


module.exports = Paper
