TOUCH = ('ontouchstart' of window) or ('onmsgesturechange' of window)
  
BEAM_BY_LONGPRESS = false
    
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
      window.vm.swiping true
      window.vm._left dx
    
  _beginDrag = ->
    return unless dragIntent
    
    clearTimeout dragIntent.timeout if dragIntent.timeout 
    
    dragging = dragIntent
    window.vm.dragging true
    
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
    window.vm.dragging false
    
    $c.removeClass "dragging"
    $(".dragHover").removeClass("dragHover")
    
    window.vm._left 0
    window.vm.swiping false
    $(".pages").addClass('animated')
    
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
  
  $d.on "mouseup", (e) ->
    if dragging
      e.preventDefault()
      return
      
    $t = $(e.target)

    if not dragIntent or dragIntent.isTap()
      click = $.Event('click')
      $t.trigger click
      
      if $t.is "input[type=submit]:enabled" and not click.isDefaultPrevented()
        $t.closest("form").trigger("submit")
      else if $t.is "textarea"
        return
        
      e.preventDefault()
        
    else if dragIntent?.isSwipe()
      dx = dragIntent.diff().dx
      e.preventDefault()
      
      if dx < 0
        window.vm.onNext()
      else if dx > 0
        window.vm.onPrevious()
    
    return
  
  $d.on "mousedown", ".subjects li", (e) ->
    unless $(e.target).is ":input, a"
      beginDrag e
  
  $d.on "mouseup", ".portals li", ->
    log "BEAM!" if dragging
    true
    
  $d.on "mouseup", (e) ->
    setTimeout (-> endDrag(e)), 0
   
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