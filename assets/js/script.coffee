#= require "vendor/jquery-1.9.1"
#= require "vendor/jquery-ui"
#= require "vendor/knockout-2.2.1"
#= require_tree "lib"
#= require "touch"

TOUCH = ('ontouchstart' of window) or ('onmsgesturechange' of window)
KEYBOARD = not TOUCH

$(document).on "keydown", (e) ->
  return if $(e.target).is(":input")
  
  switch e.which ? e.keyCode
    when 8, 46 # backspace
      vm.onBack()
    when 13 # enter/return
      vm.onAction()
    when 32 # space
      vm.onSelect()
    when 37 # left
      vm.onLeft()
    when 38 # up
      vm.onUp()
    when 39 # right
      vm.onRight()
    when 40 # down
      vm.onDown()
    when 96 # numpad 0
      debugger
    else
      return
      
  e.preventDefault()
  return
  
ko.bindingHandlers.tap =
  update: (element, valueAccessor) ->
    callback = ko.unwrapObservable valueAccessor()    
    $(element).on "tap", (e) ->
      e?.preventDefault?() if $(this).is("a")
      e?.stopPropagation()
      return if window.vm.swiping() or window.vm.dragging()
      callback()
      
ko.bindingHandlers.click =
  update: (element, valueAccessor) ->
    callback = ko.unwrapObservable valueAccessor()
    $(element).on "click", (e) ->
      e?.preventDefault?() if $(this).is("a")
      e?.stopPropagation()
      return if window.vm.swiping() or window.vm.dragging()
      callback()

Counter = ->
  i = 0
  -> i++
  
Math.clamp ?= (min, max, v) ->
  if max < min
    t = min
    min = max
    max = t
    
  Math.min(max, Math.max(min, v))
  
Math.sinh ?= (arg) ->
 (Math.exp(arg) - Math.exp(-arg)) / 2
  
next = new Counter
  
class SubjectGroup extends ko.ViewModel
  @property "title"
  @property "items", []
  
  constructor: (t = "untitled") ->
    super
    @title t
    @items.push "Subject #{next() + 1}" for i in [1,2,3,4]

class ViewModel extends ko.ViewModel
  
  constructor: ->
    super
    @left = @left.extend throttle: 5
  
  @property "groupedSubjects", [new SubjectGroup("Safari"), new SubjectGroup("Clipboard"), new SubjectGroup("Guru")]
  @accessor "flatSubjects", ->
    result = []
    
    for group in @groupedSubjects()
      result = result.concat group.items()
      
    result
    
  @property "portals", ["MacBook", "MacBook Pro", "Windows PC", "iPhone", "iPod", "iMac", "Car", "TV", "Windows Phone", "Nexus 7"]
  
  @property "dragging", false
  @property "swiping", false
  @property "viewportWidth", document.width
  
  @property "detailedSubject", null
  @property "selectedSubject", null
  
  @property "_focusedSubjectIndex", 0
  @accessor "focusedSubjectIndex", (v) -> Math.clamp 0, (@flatSubjects().length - 1), @_focusedSubjectIndex()
  @accessor "focusedSubject", -> @flatSubjects()[@focusedSubjectIndex()] if KEYBOARD and not (@detailedSubject() or @selectedSubject())
  
  @property "_focusedPortalIndex", 0
  @accessor "focusedPortalIndex", (v) -> Math.clamp 0, (@portals().length - 1), @_focusedPortalIndex()
  @accessor "focusedPortal", -> @portals()[@focusedPortalIndex()] if KEYBOARD and not @dragging()
  
  @accessor "hasNext", ->
    not @dragging() and not @swiping() and @page() is 0 and not @detailedSubject()
  
  @accessor "hasPrevious", ->
    @page() > 0
  
  @property "_left", 0
  @accessor "left", ->
    regular = -1 * @page() * @viewportWidth()
    regular += @_left() if @swiping()
    
    l = document.width * 0.33
    
    if regular > 0
      x = regular
      regular = Math.atan(x / l) * l
    else if regular < -@viewportWidth()
      x = -1 * (regular + @viewportWidth())
      x = Math.atan(x / l) * l
      regular = -1 * (x + @viewportWidth())
      
    regular
      
  @accessor "iconLeft", ->
    return 0 if @detailedSubject()
    progress = (-1 * @left() / @viewportWidth())
    -1 * (5 + 1 + 10 + 24 / 2 + 20) * (1 - progress)
  
  @property "_page", 0
  @accessor "page", ->
    if @dragging()
      1
    else if @selectedSubject()
      1
    else
      @_page()
      
  onNext: =>
    @_page 1
    
  onPrevious: =>
    @_page 0
    @selectedSubject null
  
  onTap: (item) =>
    @detailedSubject item
  
  onPortalClicked: (item) =>
    if @selectedSubject()
      @onBeam()
  
  onBeam: (item) =>
    @selectedSubject null
    
    self = $("<div>")
      .text("Beamed!")
      .addClass("message")
      .appendTo("#container")
      .css(opacity: 0)
      .fadeTo(100, 1)
      .delay(500)
      .fadeOut 100, ->
        self.remove()
    
  onCancelDetail: =>
    @detailedSubject null
    
  onSubmitDetail: =>
    $(":focus").blur()
    @selectedSubject @detailedSubject()
    @detailedSubject null
  
  @accessor "secondPageTitle", ->
    if @dragging() or @selectedSubject()
      "...to..."
    else
      "Your Portals"
      
  onUp: ->
    if @page() is 0
      @_focusedSubjectIndex(@focusedSubjectIndex() - 1)
    else
      @_focusedPortalIndex(@focusedPortalIndex() - 1)
      
  onDown: ->
    if @page() is 0
      @_focusedSubjectIndex(@focusedSubjectIndex() + 1)
    else
      @_focusedPortalIndex(@focusedPortalIndex() + 1)
    
  onLeft: -> @_page 0
  onRight: -> @_page 1
  
  onSelect: ->
    if @page() is 0
      @detailedSubject @focusedSubject()
    else if @selectedSubject()
      @onBeam()
      
  onAction: ->
    if @page() is 0
      @selectedSubject @focusedSubject()
    else if @selectedSubject()
      @onBeam()
      
  onBack: ->
    @_page 0
    @selectedSubject null

$ ->
  window.vm = vm = new ViewModel
  ko.applyBindings vm
  $(window).on "resize", -> vm.viewportWidth document.width