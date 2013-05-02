#= require "vendor/jquery-1.9.1"
#= require "vendor/jquery-ui"

TOUCH = ('ontouchstart' of window) or ('onmsgesturechange' of window)
  
BEAM_BY_LONGPRESS = false

class DragIntent
  constructor: (e) ->
    @startedAt = Date.now()
    @pageX = e.pageX
    @pageY = e.pageY
    @startX = e.pageX
    @startY = e.pageY
    @target = e.target
    
  update: (e) ->
    @pageX = e.pageX
    @pageY = e.pageY
    
  isTap: ->
    @isStationary() and !@isQuickTap() and !@isLongTap()
  
  isQuickTap: ->
    @isStationary() and Date.now() < @startedAt + 25
  
  isLongTap: ->
    @isStationary() and Date.now() > @startedAt + 750
    
  diff: ->
    return {
      dx: @pageX - @startX
      dy: @pageY - @startY
    }
    
  absDiff: ->
    { dx, dy } = @diff()
    return { dx: Math.abs(dx), dy: Math.abs(dy) }
  
  # manhattan distance
  distance2: ->
    { dx, dy } = @absDiff()
    dx + dy
    
  isStationary: ->
    @distance2() <= 10
    
  isVertical: ->
    { dx, dy } = @absDiff()
    dy > 0 and dy > dx
    
  isHorizontal: ->
    { dx, dy } = @absDiff()
    dx > 0 and dx > dy
    
  isSwipe: ->
    !@isTap() and !@isStationary() and @isHorizontal()
    
  isScroll: ->
    !@isTap() and !@isStationary() and @isVertical()
    
  isMaybeTap: true
  isMaybeSwipe: true
    
log = (msg) ->
  console.log arguments...
  # $("body").append("#{msg}<br>")
  true

$ ->
  $c = $("#container")
  $d = $(document)
  
  dragIndicator = null
  dragging = false
  dragIntent = null
  
  moveDragIndicator = (e) ->
    return unless e? and dragIndicator?
    
    dragIndicator.css
      left: e.pageX - 12
      top: e.pageY - 12
      
    true
  
  beginDrag = (e) ->
    $(e.target).addClass("dragHover")
  
    dragIntent = new DragIntent e
      
    if BEAM_BY_LONGPRESS
      dragIntent.timeout = setTimeout _beginDrag, 250

  checkDrag = (e) ->
    return unless dragIntent
    
    dragIntent.update e
    
    unless dragIntent.detected
      return if dragIntent.isStationary()
    
      if dragIntent.isVertical()
        dragIntent.detected = "scroll"
        
    # log "LOCKED: " + dragIntent.detected
    
    return if dragIntent.detected is "scroll"
    
    dx = dragIntent.diff().dx
    e.preventDefault()
    
    if dragIntent.isMaybeTap and dx > 0
      dragIntent.detected = "drag"
      _beginDrag()
    else
      dragIntent.detected = "swipe"
      dragIntent.isMaybeTap = false
      $(".pages").removeClass('animated')
        .css(left: Math.min(dx, 10))
    
  _beginDrag = ->
    return unless dragIntent
    
    clearTimeout dragIntent.timeout if dragIntent.timeout 
    
    dragging = dragIntent
    $c.addClass "dragging"
    dragIndicator = $("<span></span>")
      .addClass("drag")
      .appendTo("body")
    
    $t = $(dragIntent.target)
    o = $t.offset()
    dragIndicator.text $t.text()
    
    w = dragIndicator.outerWidth()
    h = 24
    
    dragIndicator.css
      marginLeft: o.left - dragIntent.pageX + 12
      marginTop: o.top - dragIntent.pageY + 12
      padding: 0
      width: $t.outerWidth()
      height: $t.outerHeight()
      lineHeight: "#{$t.outerHeight()}px"
      
    dest =
      marginLeft: 0
      marginTop: 0
      width: w
      height: h
      opacity: 0.8
      borderRadius: h
      lineHeight: "#{h}px"
      padding: "0 20px"
      color: "rgba(0,0,0,1)"
      
    dragIndicator.animate dest, 150, "swing"
    
    moveDragIndicator dragIntent
    dragIntent = null
    
    true
    
  endDrag = ->
    if dragIntent?
      clearTimeout dragIntent.timeout
      dragIntent = null
  
    dragging = false
    $c.removeClass "dragging"
    $(".dragHover").removeClass("dragHover")
    $(".pages").css(left: '').addClass('animated')
    
    if dragIndicator
      oldIndicator = dragIndicator
      oldIndicator.fadeOut 250, ->
        oldIndicator.remove()
      
    dragIndicator = null
    true  
  
  $d.on "mouseenter", ".portals li", (e) ->
    $(this).addClass "dragHover" if dragging
    true
  
  $d.on "mouseleave", ".portals li", (e) ->
    $(this).removeClass "dragHover"
    true
    
  $d.on "mousemove", (e) ->
    if dragging
      e.preventDefault()
      moveDragIndicator e
    else
      checkDrag e
      
  $d.on "click", ".subjects li input[type=submit]", (e) ->
    e.preventDefault()
    e.stopPropagation()
    $c.addClass 'manualBeam'
  
  $d.on "click", ".subjects li a", (e) ->
    e.preventDefault()
    $this = $(this).closest 'li'
    $this.text $this.data 'originalText'
    $this.removeClass 'expanded'
  
  $d.on "expand", ".subjects li", (e) ->
    $this = $(this)
    
    return if $this.is '.expanded'
    
    $this.data 'originalText', $this.text()
    
    $this.append("<br>")
      .append("More info")
      .append("<br>")
      .append("<textarea></textarea>")
      .append("<br>")
      .append("<input type='submit'>")
      .append(" or ")
      .append("<a href='#'>cancel</a>")
      
    $this.addClass 'expanded'
  
  $d.on "mouseup", ".subjects li", (e) ->
    if dragIntent?.isTap()
      $(this).trigger "expand"
    else if dragIntent?.isSwipe()
      if dragIntent.diff().dx < 0
        $c.addClass "editPortals"
        
    return
  
  $d.on "mousedown", ".subjects li", (e) ->
    return if $(e.target).is ":input"
    return if $(this).is ".expanded"
    # e.preventDefault()
    beginDrag e
  
  $d.on "mouseup", ".portals li", ->
    log "BEAM!" if dragging
    true
    
  $d.on "mouseup", (e) ->
    endDrag e
  
  $d.on "mousedown", ".right-edge", ->
    $c.addClass "editPortals"
    
  $d.on "mousedown", ".left-edge", ->
    $c.removeClass "editPortals manualBeam"
 
  # mouse emulation
  
  touchEntered = $([])
  
  copyCoords = (touchEvent, mouseEvent = {}) ->
    x = y = 0
    
    if touchEvent.touches?.length > 0
      x = touchEvent.touches[0].pageX
      y = touchEvent.touches[0].pageY
    else if touchEvent.changedTouches?.lenght > 0
      x = touchEvent.changedTouches[0].pageX
      y = touchEvent.changedTouches[0].pageY
    else
      x = touchEvent.pageX
      y = touchEvent.pageY
      
    mouseEvent.pageX = x
    mouseEvent.pageY = y
    
    return mouseEvent
  
  $d.on "touchstart", (e) ->
    log "touchStart"
    down = $.Event('mousedown')
    copyCoords e.originalEvent, down
    $(e.target).trigger down
    
    if down.isDefaultPrevented()
      e.preventDefault()
      
    true
  
  $d.on "touchmove", (e) ->
    e.preventDefault() if dragging
  
    { pageX, pageY } = copyCoords e.originalEvent
    el = document.elementFromPoint pageX, pageY
    return unless el?
    
    newTouchEntered = $(el).parents().andSelf()
    
    for el in touchEntered
      if el not in newTouchEntered
        # log "Left #{el.tagName}"
        leave = $.Event 'mouseout'
        leave.pageX = pageX
        leave.pageY = pageY
        leave.target = el
        leave.relatedTarget = newTouchEntered.get(-1)
        $(el).trigger leave
    
    for el in newTouchEntered
      if el not in touchEntered
        # log "Entered #{el.tagName}"
        enter = $.Event 'mouseover'
        enter.pageX = pageX
        enter.pageY = pageY
        enter.target = el
        enter.relatedTarget = touchEntered.get(-1)
        $(el).trigger enter
        
    touchEntered = newTouchEntered
    
    fakeEvent = $.Event('mousemove')
    fakeEvent.pageX = pageX
    fakeEvent.pageY = pageY
    $(el).trigger fakeEvent
    
    if fakeEvent.isDefaultPrevented()
      # console.log "PREVENTED"
      e.preventDefault()
      
    return
  
  $d.on "touchend touchcancel", (e) ->
    log "touchEnd"
    
    touchEntered = $([])
    up = $.Event('mouseup')
    copyCoords e.originalEvent, up
    $(e.target).trigger up
    
    if up.isDefaultPrevented()
      e.preventDefault()
      
    true

$ ->
  log "JS booted!"
  log "Touch: #{TOUCH}"
  
# debug on SPACE  
$(window).keydown (e) ->
  log "WAT"
  debugger if e.keyCode is 32