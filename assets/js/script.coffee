#= require "vendor/jquery-1.9.1"
#= require "vendor/jquery-ui"
#= require "vendor/knockout-2.2.1"
#= require_tree "lib"
#= require "touch"

# debug on SPACE  
$(window).keydown (e) ->
  debugger if e.keyCode is 32
  
ko.bindingHandlers.tap =
  update: (element, valueAccessor) ->
    callback = ko.unwrapObservable valueAccessor()    
    $(element).on "tap", (e) ->
      e?.preventDefault?()
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
    @left = @left.extend throttle: 1
  
  @property "groupedSubjects", [new SubjectGroup("Safari"), new SubjectGroup("Clipboard")]
  @property "portals", ["MacBook", "MacBook Pro", "Windows PC", "iPhone", "iPod", "iMac", "Car", "TV", "Windows Phone", "Nexus 7"]
  
  @property "dragging", false
  @property "swiping", false
  @property "viewportWidth", 320
  
  @property "selectedSubject", null
  @property "detailedSubject", null
  @property "draggedSubject", null
  
  @accessor "hasNext", ->
    not @dragging() and not @swiping() and @page() is 0 and not @detailedSubject()
  
  @accessor "hasPrevious", ->
    @page() > 0
  
  @property "_left", 0
  @accessor "left", ->
    regular = -1 * @page() * @viewportWidth()
    regular += @_left() if @swiping()
    
    l = 10
    
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
    progress = (-1 * @left() / 320)
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
      .prependTo("body")
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

$ ->
  window.vm = new ViewModel
  ko.applyBindings vm