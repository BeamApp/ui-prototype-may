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
      callback()

Counter = ->
  i = 0
  -> i++
  
next = new Counter
  
class SubjectGroup extends ko.ViewModel
  @property "title"
  @property "items", []
  
  constructor: (t = "untitled") ->
    super
    @title t
    @items.push "Subject #{next() + 1}" for i in [1,2,3,4]

class ViewModel extends ko.ViewModel
  @property "groupedSubjects", [new SubjectGroup("Safari"), new SubjectGroup("Clipboard")]
  @property "portals", ["MBP 1", "MBP 2", "MBP 3", "iPhone", "iPod", "iMac", "Car", "TV"]
  
  @property "dragging", false
  @property "swiping", false
  
  @property "selectedSubject", null
  @property "detailedSubject", null
  @property "draggedSubject", null
  
  @accessor "hasNext", ->
    not @dragging() and @page() is 0 and not @detailedSubject()
  
  @accessor "hasPrevious", ->
    @page() > 0
  
  @property "_left", 0
  @accessor "left", ->
    if @swiping()
      Math.min(10, Math.max(-320, @_left()))
    else
      -1 * @page() * 320
      
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
    
  onCancelDetail: =>
    @detailedSubject null
    
  onSubmitDetail: =>
    @selectedSubject @detailedSubject()
    @detailedSubject null
  
  @accessor "secondPageTitle", ->
    if @swiping()
      "Portals"
    else if @dragging()
      "...to..."
    else if @selectedSubject()
      "Beam X to..."
    else
      "Your Portals"

$ ->
  window.vm = new ViewModel
  ko.applyBindings vm
  
  ko.subscribeAndDo vm.page, (i) ->
    $("body")[if i is 0 then "addClass" else "removeClass"]("firstPage")