TOUCH = ('ontouchstart' of window) or ('onmsgesturechange' of window)
  
BEAM_BY_LONGPRESS = true

defer = (f) ->
  scheduler = webkitRequestAnimationFrame ? setTimeout
  scheduler f, 0
    
log = (msg) ->
  console.log arguments...
  # $("body").append("#{msg}<br>")
  true

$ ->
  $c = $("#container")
  $c.on "scrollstart", ->
    e.preventDefault()
    false
  
  $d = $(document)
  
  dragIndicator = null
  dragging = false
  dragIntent = null
  
  moveDragIndicator = (e) ->
    return unless e? and dragIndicator?
    
    dragIndicator.css
      left: e.pageX
      top: e.pageY
      
    true
  
  beginDrag = (e) ->
    chain = $(e.target).parents().andSelf()
    chain.filter(".draggable").addClass "dragHover"
  
    dragIntent = new DragIntent e
    dragIntent.isMaybeDrag = chain.is(".draggable")
    dragIntent.isMaybeSwipe = chain.is(".swipeable")
      
    if BEAM_BY_LONGPRESS
      dragIntent.timeout = setTimeout _beginDrag, 250

  checkDrag = (e) ->
    return unless dragIntent
    
    dragIntent.update e
    
    unless dragIntent.detected
      return if dragIntent.isStationary()
    
      if dragIntent.isVertical()
        dragIntent.detected = "scroll"
        dragIntent.isMaybeTap = dragIntent.isMaybeDrag = dragIntent.isMaybeSwipe = false
        
    # log "LOCKED: " + dragIntent.detected
    
    return if dragIntent.detected is "scroll"
    
    dx = dragIntent.diff().dx
    e.preventDefault()
    
    if dragIntent.isMaybeTap and dragIntent.isMaybeDrag and dx > 0
      dragIntent.detected = "drag"
      _beginDrag()
    else if dragIntent.isMaybeSwipe
      dragIntent.detected = "swipe"
      dragIntent.isMaybeTap = dragIntent.isMaybeDrag = false
      $(".pages").removeClass('animated')
      window.vm.swiping true
      window.vm._left dx
    
  _beginDrag = ->
    return unless dragIntent?.isMaybeDrag
    
    clearTimeout dragIntent.timeout if dragIntent.timeout 
    
    dragging = dragIntent
    window.vm.dragging true
    
    $c.addClass "dragging"
    dragIndicator = $("<span></span>")
      .addClass("drag")
      .appendTo("#container")
    
    $t = $(dragIntent.target).closest(".draggable")
    o = $t.offset()
    dragIndicator.text($t.attr('title') ? $t.text())
    
    w = dragIndicator.width()
    ow = dragIndicator.outerWidth()
    h = dragIndicator.outerHeight()
    lh = dragIndicator.css "line-height"
    
    dragIndicator.css
      marginLeft: o.left - dragIntent.pageX
      marginTop: o.top - dragIntent.pageY
      width: $t.outerWidth()
      lineHeight: "#{$t.outerHeight()}px"
      "-webkit-transform": "rotate(-5deg)"
      
    dest =
      marginLeft: -ow / 2
      marginRight: 0
      marginTop: - h - 10
      width: w
      opacity: 1
      lineHeight: lh
      color: "rgba(0,0,0,1)"
      
    dragIndicator.animate dest, 200, "swing"
    
    moveDragIndicator dragIntent
    dragIntent = null
    
    true
    
  endDrag = (e) ->
    if dragIntent?
      clearTimeout dragIntent.timeout
      dragIntent = null
  
    e?.preventDefault()
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
    $t = $(e.target)
    
    if dragging
      # nothing to do
    else if not dragIntent or dragIntent.isTap()
      
      defaultPrevented = false
      
      for eventType in ['tap', 'click']
        unless defaultPrevented
          afterEvent = $.Event eventType
          $t.trigger afterEvent 
          defaultPrevented or= afterEvent.isDefaultPrevented()
      
      return if $t.is "textarea"
      
      if $t.is "input[type=submit]:enabled" and not defaultPrevented
        $t.closest("form").trigger("submit")
        
    else if dragIntent?.isSwipe()
      dx = dragIntent.diff().dx
      if dx < 0
        window.vm.onNext()
      else if dx > 0
        window.vm.onPrevious()
    
    endDrag e
    e.preventDefault()
    return
  
  $d.on "mousedown", ".page", (e) ->
    beginDrag e unless $(e.target).is ":input, a"
    return
  
  $d.on "mouseup", ".portals li", ->
    window.vm.onBeam() if dragging  
    return

  # mouse emulation
  
  touchEntered = $([])
  
  copyCoords = (touchEvent, mouseEvent = {}) ->
    x = y = 0
    
    if touchEvent.touches?.length > 0
      x = touchEvent.touches[0].pageX
      y = touchEvent.touches[0].pageY
    else if touchEvent.changedTouches?.length > 0
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
    
    el = document.elementFromPoint up.pageX, up.pageY
    $(el).trigger up
    
    # $(e.target).trigger up
    
    if up.isDefaultPrevented()
      e.preventDefault()
      
    true