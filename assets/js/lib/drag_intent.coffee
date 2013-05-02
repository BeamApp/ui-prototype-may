class @DragIntent
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
    # @isStationary() and Date.now() < @startedAt + 25
    false
  
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