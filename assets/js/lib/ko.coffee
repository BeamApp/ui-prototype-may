NO_CSS_TRANSITIONS = true

ko.bindingHandlers.classes =
  init: (element, valueAccessor, allBindingsAccessor) ->

  update: (element, valueAccessor) ->
    $el = $(element)

    for className, binding of valueAccessor()
      val = ko.utils.unwrapObservable(binding)

      if val
        $el.addClass(className)
      else
        $el.removeClass(className)

ko.bindingHandlers.error =
  init: -> ko.bindingHandlers.error.update(arguments...)

  update: (element, valueAccessor) ->
    value = ko.unwrapObservable valueAccessor()

    $el = $(element)

    if value
      $el.addClass "invalid"
      icon = $el.find ".invalid-icon"

      if icon.length == 0
        icon = $("<div>").addClass "invalid-icon"
        $el.append icon

      icon.attr "title", value
    else
      $el.removeClass("invalid")

ko.bindingHandlers.date =
  init: -> ko.bindingHandlers.date.update(arguments...)

  update: (element, valueAccessor) ->
    value = ko.unwrapObservable valueAccessor()
    value = value.toString("d.M.yyyy") if value?
    $(element).text value

ko.bindingHandlers.price =
  update: (element, valueAccessor) ->
    value = ko.unwrapObservable valueAccessor()
    return $(element).text("") unless value?
    
    value = parseFloat(value).toFixed(2)
    $(element).text("#{value}€")

ko.bindingHandlers.width =
  update: (element, valueAccessor) ->
    width = ko.utils.unwrapObservable(valueAccessor())
    
    if width and isFinite width
      width = Math.max(0, Math.min(1, width)) * 100
      element.style.width ="#{width}%"
    else
      element.style.width = ''

ko.bindingHandlers.left =
  update: (element, valueAccessor) ->
    left = ko.unwrapObservable valueAccessor()
    if left and isFinite left
      element.style.left = "#{left}px"
    else
      element.style.left = ''

ko.bindingHandlers.visibility =
  init: -> ko.bindingHandlers.visibility.update(arguments...)

  update: (element, valueAccessor) ->
    visible = ko.utils.unwrapObservable(valueAccessor())
    visibility = if visible then "visible" else "hidden"
    element.style.visibility = visibility

ko.bindingHandlers.fadeVisible =
  init: ko.bindingHandlers.visible.update
  update: (element, valueAccessor) ->
    visible = ko.utils.unwrapObservable(valueAccessor())
    el = $(element).stop true, true
    el[if visible then "fadeIn" else "fadeOut"](200)

ko.bindingHandlers.slideVisible =
  init: ko.bindingHandlers.visible.update
  update: (element, valueAccessor) ->
    visible = ko.utils.unwrapObservable(valueAccessor())
    el = $(element).stop true, true
    el[if visible then "slideDown" else "slideUp"](200)

ko.bindingHandlers.hasFocusOneWay =
  init: ko.bindingHandlers.hasfocus.init

ko.bindingHandlers.scroll =

  init: (element, valueAccessor) ->
    ko.bindingHandlers.scroll._update element, valueAccessor, false

    if Modernizr.csstransitions and not NO_CSS_TRANSITIONS
      $(element).css
        "-webkit-transition": "left 250ms ease-out",
           "-moz-transition": "left 250ms ease-out",
             "-o-transition": "left 250ms ease-out",
                "transition": "left 250ms ease-out"

  update: (element, valueAccessor) ->
    ko.bindingHandlers.scroll._update element, valueAccessor, true

  _update: (element, valueAccessor, animate) ->
    $el = $(element)
    index = valueAccessor()()
    target = $el.children().slice(index, index + 1).position()?.left
    # target = $el.outerWidth() * index
    return unless target?
    css = { left: -1 * target }

    if Modernizr.csstransitions and not NO_CSS_TRANSITIONS
      $el.css "left", css
    else if animate
      _.defer ->
        $el.stop(true, true).animate css,
          duration: 250
          easing: "easeOutCubic"

ko.bindingHandlers.autocomplete =

  init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    $el = $(element)
    options = valueAccessor() or {}
    options.valueProperty ?= "name"
    options.labelProperty ?= "name"
    options.value ?= ko.observable()

    $el.data 'ko-autocomplete-options', options

    allBindings = allBindingsAccessor()

    options.mapItem = (item) ->
      _.tap {}, (mappedItem) ->
        if item?
          mappedItem.value = mappedItem.actualValue = item
          mappedItem.value = ko.unwrapObservable item[options.valueProperty]
          mappedItem.label = ko.unwrapObservable (item[options.labelProperty] ? String(item))
        else
          mappedItem.actualValue = null
          mappedItem.value = mappedItem.label = ""

    options.mapList = (source) ->
      _.map source, options.mapItem

    $el.val options.mapItem(ko.unwrapObservable(options.value)).value

    $el.autocomplete
      delay: 150
      minLength: 1

      select: (event, ui) ->
        if ui.item?
          $el.val ui.item.value
          options.value ui.item.actualValue
        else
          $el.val ""
          options.value null

        return

      source: (query, callback) ->
        options.callback.call viewModel, query.term, (results) ->
          callback options.mapList results

        return

  update: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    $el = $(element)
    return if $el.is(":focus")

    options = $el.data 'ko-autocomplete-options'

    if currentValue = ko.unwrapObservable options.value
      currentValue = currentValue.name

      if $el.val() isnt currentValue
        $el.val currentValue

ko.subscribeAndDo = (observable, handler) ->
  # observable.extend(throttle: 10).subscribe(handler)
  observable.subscribe(handler)
  handler(observable())

ko.unwrapOneObservable = (value) ->
  if ko.isObservable(value) then value() else value

ko.unwrapObservable = (value) ->
  value = value() while ko.isObservable(value)
  value

ko.finalObservable = (value) ->
  last = value

  while ko.isObservable(value)
    last = value
    value = value()

  last

ko.isDependentObservable = (value) ->
  value and value.__ko_proto__ == ko.dependentObservable

ko.unwrapDependentObservable = (value) ->
  value = value() while ko.isDependentObservable(value)
  value

ko.extendMapped = (dest, src, map = null, onlyMapped = false) ->
  for own srcKey, v of src
    v = ko.unwrapObservable v
    destKey = srcKey

    if map? and _(map).has srcKey
      destKey = map[srcKey] unless map[srcKey] == true
    else if onlyMapped
      continue

    destKeys = (if _.isArray(destKey) then destKey else [destKey])

    for k in destKeys
      if ko.isObservable dest[k]
        dest[k] v
      else
        dest[k] = v

  dest

ko.extend = (dest, sources...) ->
  [src, sources...] = sources

  ko.extendMapped dest, src

  if sources.length > 0
    ko.extend dest, sources...
  else
    dest

ko.booleanBinding = (observable) ->
  ko.computed
    read: -> String(!!observable())
    write: (v) -> observable(ko.booleanBinding.truths.indexOf(v) >= 0)

ko.booleanBinding.truths = [
  true,
  1, "1",
  "TRUE", "T", "true", "t",
  "YES", "yes", "Y", "y"
]

ko.setter = (observable, value) -> -> observable(value)
ko.caller = (func, args...) -> -> func args...
ko.negate = (o) -> -1 * ko.unwrapObservable(o)
ko.not =    (o) -> not ko.unwrapObservable(o)
ko.eq  = (a, b) -> ko.unwrapObservable(a) is ko.unwrapObservable(b)
ko.ne  = (a, b) -> not ko.eq(a, b)
ko.gt  = (a, b) -> ko.unwrapObservable(a) > ko.unwrapObservable(b)
ko.gte = (a, b) -> ko.unwrapObservable(a) >= ko.unwrapObservable(b)
ko.lt  = (a, b) -> ko.unwrapObservable(a) < ko.unwrapObservable(b)
ko.lte = (a, b) -> ko.unwrapObservable(a) <= ko.unwrapObservable(b)

ko.length = (o) -> ko.unwrapObservable(o)?.length
ko.empty  = (o) -> (ko.unwrapObservable(o)?.length ? 0) is 0
ko.first  = (o) -> ko.unwrapObservable(o)?[0]
ko.last   = (o) -> ko.unwrapObservable(o)?.slice?(-1)[0]

ko.all = (args...) ->
  all = true
  all and= ko.unwrapObservable(arg) for arg in args
  all

ko.any = (args...) ->
  for arg in args
    v = ko.unwrapObservable arg
    return v if v

  false

ko.join = (args...) ->
  (ko.unwrapObservable(arg) for arg in args).join("-")

ko.include = ko.includes = (collection, value) ->
  collection = ko.unwrapObservable collection
  value = ko.unwrapObservable value
  collection.indexOf(value) >= 0

ko.includer = (observable, item) ->
  ko.computed
    read: -> ko.includes observable, item
    write: (shouldInclude) ->
      includes = ko.includes observable, item
      return if includes is shouldInclude

      unwrapped = ko.finalObservable(observable)

      if shouldInclude
        unwrapped.push item
      else
        unwrapped.remove item

ko.toggler = (observable) ->
  ->
    current = observable()
    observable not current

ko.get = (root, path) ->
  if arguments.length < 2
    path = root
    root = @

  steps = path.split(".")
  root = ko.unwrapObservable(root)

  for step in steps
    break unless root
    root = root[step]
    root = ko.unwrapObservable(root)

  root

ko.ifElse = (condition, ifTrue, ifFalse) ->
  condition = ko.unwrapObservable condition
  ko.unwrapObservable(if condition then ifTrue else ifFalse)

class ko.ViewModel
  constructor: ->
    later = @constructor.later
    item.call @ for item in later if later

  bind: (target) ->
    if target and target instanceof Element
      ko.applyBindings @, target
    else if target
      target = $(target)[0]
      ko.applyBindings @, target
    else
      ko.applyBindings @

  get: (path) ->
    ko.get @, path

  @prepareLater: ->
    return if @later and @later.owner == @

    later = []
    later.owner = @
    later.push item for item in @later if @later
    @later = later

  @property: (name, value) ->
    @prepareLater()
    @later.push ->
      if value instanceof Array
        array = []
        array.push item for item in value
        @[name] = ko.observableArray array
      else
        @[name] = ko.observable value

  @accessor: (name, f) ->
    @prepareLater()
    @later.push ->
      self = @

      if f instanceof Function
        @[name] = ko.computed
          read: -> f.apply self, arguments
          deferEvaluation: true
      else
        @[name] = ko.computed
          deferEvaluation: true
          read: ->
            throw new Error "read not supported" unless f.read
            f.read.apply self, arguments
          write: ->
            throw new Error "write not supported" unless f.write
            f.write.apply self, arguments

  @alias: (name, otherName) ->
    @accessor name,
      read: -> @[otherName]()
      write: -> @[otherName].apply @, arguments

  @hasMany: (name, backer, collection, identifier = _.identity) ->
    @accessor name,
      read: ->
        ids = ko.unwrapObservable @[backer]
        items = ko.unwrapObservable @[collection]

        _(ids).chain()
          .map((id) -> _(items).detect((item) -> String(identifier item) == String(id)))
          .compact()
          .value()

      write: (values = []) ->
        @[backer].removeAll()

        oldIds = ko.unwrapObservable @[backer]
        ids = _.map values, identifier

        @[backer].splice 0, oldIds.length, ids...


  @hasOne: (name, backer, collection, identifier = _.identity, exactlyOne = false) ->
    @accessor name,
      read: ->
        id = ko.unwrapObservable @[backer]
        items = ko.unwrapObservable @[collection]

        if id?
          result = _.detect items, (item) -> String(identifier item) == String(id)

        if not result and exactlyOne
          result = _.first items
          @[backer] identifier result if result

        result

      write: (value) ->
        return @[backer] null unless value?

        unless _.isObject value
          console?.log? "Setting #{name} (hasOne) to non-object. Did you mean to set #{backer} instead?", value

        @[backer](String(identifier(value)))

  @filter: (name, backer, collection, selector) ->
    @accessor name, ->
      all = []
      value = @[backer]()

      for item in ko.unwrapObservable(@[collection])
        all.push item if value == selector(item)

      all

  @unique: (name, collection, selector) ->
    @accessor name, ->
      all = []

      for item in ko.unwrapObservable(@[collection])
        value = selector(item)
        all.push(value) unless _(all).include(value)

      all.sort()

  @dateAccessor: (name, backer) ->
    @accessor name,
      read: ->
        value = @[backer]()
        return "" unless value
        $.datepicker.formatDate CONFIG.datpickerSettings.dateFormat, value
      write: (value) ->
        parsed = $.datepicker.parseDate CONFIG.datpickerSettings.dateFormat, value
        @[backer] parsed

  @enum: (name, collection, value) ->
    backer = "_#{name}"

    @property backer, value

    @accessor name,
      read: -> @[backer]()
      write: (value) ->
        all = collection
        all = ko.unwrapObservable(@[collection]) unless _.isArray collection

        if _.contains all, value
          @[backer] value
        else
          console?.log? "The value '#{value}' is invalid for enum property '#{name}'.", value, all


ko.tryBind = (query, viewModelClass) ->
  view = $(query)

  if view.length > 0
    viewModel = new viewModelClass()
    ko.applyBindings viewModel, view.get(0)
