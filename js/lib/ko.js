(function() {
  var NO_CSS_TRANSITIONS,
    __hasProp = {}.hasOwnProperty,
    __slice = [].slice;

  NO_CSS_TRANSITIONS = true;

  ko.bindingHandlers.classes = {
    init: function(element, valueAccessor, allBindingsAccessor) {},
    update: function(element, valueAccessor) {
      var $el, binding, className, val, _ref, _results;

      $el = $(element);
      _ref = valueAccessor();
      _results = [];
      for (className in _ref) {
        binding = _ref[className];
        val = ko.utils.unwrapObservable(binding);
        if (val) {
          _results.push($el.addClass(className));
        } else {
          _results.push($el.removeClass(className));
        }
      }
      return _results;
    }
  };

  ko.bindingHandlers.error = {
    init: function() {
      var _ref;

      return (_ref = ko.bindingHandlers.error).update.apply(_ref, arguments);
    },
    update: function(element, valueAccessor) {
      var $el, icon, value;

      value = ko.unwrapObservable(valueAccessor());
      $el = $(element);
      if (value) {
        $el.addClass("invalid");
        icon = $el.find(".invalid-icon");
        if (icon.length === 0) {
          icon = $("<div>").addClass("invalid-icon");
          $el.append(icon);
        }
        return icon.attr("title", value);
      } else {
        return $el.removeClass("invalid");
      }
    }
  };

  ko.bindingHandlers.date = {
    init: function() {
      var _ref;

      return (_ref = ko.bindingHandlers.date).update.apply(_ref, arguments);
    },
    update: function(element, valueAccessor) {
      var value;

      value = ko.unwrapObservable(valueAccessor());
      if (value != null) {
        value = value.toString("d.M.yyyy");
      }
      return $(element).text(value);
    }
  };

  ko.bindingHandlers.price = {
    update: function(element, valueAccessor) {
      var value;

      value = ko.unwrapObservable(valueAccessor());
      if (value == null) {
        return $(element).text("");
      }
      value = parseFloat(value).toFixed(2);
      return $(element).text("" + value + "€");
    }
  };

  ko.bindingHandlers.width = {
    update: function(element, valueAccessor) {
      var width;

      width = ko.utils.unwrapObservable(valueAccessor());
      if (width && isFinite(width)) {
        width = Math.max(0, Math.min(1, width)) * 100;
        return $(element).css({
          width: "" + width + "%"
        });
      } else {
        return $(element).css({
          width: ''
        });
      }
    }
  };

  ko.bindingHandlers.left = {
    update: function(element, valueAccessor) {
      var left;

      left = ko.unwrapObservable(valueAccessor());
      if (left && isFinite(left)) {
        return $(element).css({
          left: left
        });
      } else {
        return $(element).css({
          left: ''
        });
      }
    }
  };

  ko.bindingHandlers.visibility = {
    init: function() {
      var _ref;

      return (_ref = ko.bindingHandlers.visibility).update.apply(_ref, arguments);
    },
    update: function(element, valueAccessor) {
      var visibility, visible;

      visible = ko.utils.unwrapObservable(valueAccessor());
      visibility = visible ? "visible" : "hidden";
      return element.style.visibility = visibility;
    }
  };

  ko.bindingHandlers.fadeVisible = {
    init: ko.bindingHandlers.visible.update,
    update: function(element, valueAccessor) {
      var el, visible;

      visible = ko.utils.unwrapObservable(valueAccessor());
      el = $(element).stop(true, true);
      return el[visible ? "fadeIn" : "fadeOut"](200);
    }
  };

  ko.bindingHandlers.slideVisible = {
    init: ko.bindingHandlers.visible.update,
    update: function(element, valueAccessor) {
      var el, visible;

      visible = ko.utils.unwrapObservable(valueAccessor());
      el = $(element).stop(true, true);
      return el[visible ? "slideDown" : "slideUp"](200);
    }
  };

  ko.bindingHandlers.hasFocusOneWay = {
    init: ko.bindingHandlers.hasfocus.init
  };

  ko.bindingHandlers.scroll = {
    init: function(element, valueAccessor) {
      ko.bindingHandlers.scroll._update(element, valueAccessor, false);
      if (Modernizr.csstransitions && !NO_CSS_TRANSITIONS) {
        return $(element).css({
          "-webkit-transition": "left 250ms ease-out"
        }, {
          "-moz-transition": "left 250ms ease-out"
        }, {
          "-o-transition": "left 250ms ease-out"
        }, {
          "transition": "left 250ms ease-out"
        });
      }
    },
    update: function(element, valueAccessor) {
      return ko.bindingHandlers.scroll._update(element, valueAccessor, true);
    },
    _update: function(element, valueAccessor, animate) {
      var $el, css, index, target, _ref;

      $el = $(element);
      index = valueAccessor()();
      target = (_ref = $el.children().slice(index, index + 1).position()) != null ? _ref.left : void 0;
      if (target == null) {
        return;
      }
      css = {
        left: -1 * target
      };
      if (Modernizr.csstransitions && !NO_CSS_TRANSITIONS) {
        return $el.css("left", css);
      } else if (animate) {
        return _.defer(function() {
          return $el.stop(true, true).animate(css, {
            duration: 250,
            easing: "easeOutCubic"
          });
        });
      }
    }
  };

  ko.bindingHandlers.autocomplete = {
    init: function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var $el, allBindings, options, _ref, _ref1, _ref2;

      $el = $(element);
      options = valueAccessor() || {};
      if ((_ref = options.valueProperty) == null) {
        options.valueProperty = "name";
      }
      if ((_ref1 = options.labelProperty) == null) {
        options.labelProperty = "name";
      }
      if ((_ref2 = options.value) == null) {
        options.value = ko.observable();
      }
      $el.data('ko-autocomplete-options', options);
      allBindings = allBindingsAccessor();
      options.mapItem = function(item) {
        return _.tap({}, function(mappedItem) {
          var _ref3;

          if (item != null) {
            mappedItem.value = mappedItem.actualValue = item;
            mappedItem.value = ko.unwrapObservable(item[options.valueProperty]);
            return mappedItem.label = ko.unwrapObservable((_ref3 = item[options.labelProperty]) != null ? _ref3 : String(item));
          } else {
            mappedItem.actualValue = null;
            return mappedItem.value = mappedItem.label = "";
          }
        });
      };
      options.mapList = function(source) {
        return _.map(source, options.mapItem);
      };
      $el.val(options.mapItem(ko.unwrapObservable(options.value)).value);
      return $el.autocomplete({
        delay: 150,
        minLength: 1,
        select: function(event, ui) {
          if (ui.item != null) {
            $el.val(ui.item.value);
            options.value(ui.item.actualValue);
          } else {
            $el.val("");
            options.value(null);
          }
        },
        source: function(query, callback) {
          options.callback.call(viewModel, query.term, function(results) {
            return callback(options.mapList(results));
          });
        }
      });
    },
    update: function(element, valueAccessor, allBindingsAccessor, viewModel) {
      var $el, currentValue, options;

      $el = $(element);
      if ($el.is(":focus")) {
        return;
      }
      options = $el.data('ko-autocomplete-options');
      if (currentValue = ko.unwrapObservable(options.value)) {
        currentValue = currentValue.name;
        if ($el.val() !== currentValue) {
          return $el.val(currentValue);
        }
      }
    }
  };

  ko.subscribeAndDo = function(observable, handler) {
    observable.subscribe(handler);
    return handler(observable());
  };

  ko.unwrapOneObservable = function(value) {
    if (ko.isObservable(value)) {
      return value();
    } else {
      return value;
    }
  };

  ko.unwrapObservable = function(value) {
    while (ko.isObservable(value)) {
      value = value();
    }
    return value;
  };

  ko.finalObservable = function(value) {
    var last;

    last = value;
    while (ko.isObservable(value)) {
      last = value;
      value = value();
    }
    return last;
  };

  ko.isDependentObservable = function(value) {
    return value && value.__ko_proto__ === ko.dependentObservable;
  };

  ko.unwrapDependentObservable = function(value) {
    while (ko.isDependentObservable(value)) {
      value = value();
    }
    return value;
  };

  ko.extendMapped = function(dest, src, map, onlyMapped) {
    var destKey, destKeys, k, srcKey, v, _i, _len;

    if (map == null) {
      map = null;
    }
    if (onlyMapped == null) {
      onlyMapped = false;
    }
    for (srcKey in src) {
      if (!__hasProp.call(src, srcKey)) continue;
      v = src[srcKey];
      v = ko.unwrapObservable(v);
      destKey = srcKey;
      if ((map != null) && _(map).has(srcKey)) {
        if (map[srcKey] !== true) {
          destKey = map[srcKey];
        }
      } else if (onlyMapped) {
        continue;
      }
      destKeys = (_.isArray(destKey) ? destKey : [destKey]);
      for (_i = 0, _len = destKeys.length; _i < _len; _i++) {
        k = destKeys[_i];
        if (ko.isObservable(dest[k])) {
          dest[k](v);
        } else {
          dest[k] = v;
        }
      }
    }
    return dest;
  };

  ko.extend = function() {
    var dest, sources, src, _ref;

    dest = arguments[0], sources = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    _ref = sources, src = _ref[0], sources = 2 <= _ref.length ? __slice.call(_ref, 1) : [];
    ko.extendMapped(dest, src);
    if (sources.length > 0) {
      return ko.extend.apply(ko, [dest].concat(__slice.call(sources)));
    } else {
      return dest;
    }
  };

  ko.booleanBinding = function(observable) {
    return ko.computed({
      read: function() {
        return String(!!observable());
      },
      write: function(v) {
        return observable(ko.booleanBinding.truths.indexOf(v) >= 0);
      }
    });
  };

  ko.booleanBinding.truths = [true, 1, "1", "TRUE", "T", "true", "t", "YES", "yes", "Y", "y"];

  ko.setter = function(observable, value) {
    return function() {
      return observable(value);
    };
  };

  ko.caller = function() {
    var args, func;

    func = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    return function() {
      return func.apply(null, args);
    };
  };

  ko.negate = function(o) {
    return -1 * ko.unwrapObservable(o);
  };

  ko.not = function(o) {
    return !ko.unwrapObservable(o);
  };

  ko.eq = function(a, b) {
    return ko.unwrapObservable(a) === ko.unwrapObservable(b);
  };

  ko.ne = function(a, b) {
    return !ko.eq(a, b);
  };

  ko.gt = function(a, b) {
    return ko.unwrapObservable(a) > ko.unwrapObservable(b);
  };

  ko.gte = function(a, b) {
    return ko.unwrapObservable(a) >= ko.unwrapObservable(b);
  };

  ko.lt = function(a, b) {
    return ko.unwrapObservable(a) < ko.unwrapObservable(b);
  };

  ko.lte = function(a, b) {
    return ko.unwrapObservable(a) <= ko.unwrapObservable(b);
  };

  ko.length = function(o) {
    var _ref;

    return (_ref = ko.unwrapObservable(o)) != null ? _ref.length : void 0;
  };

  ko.empty = function(o) {
    var _ref, _ref1;

    return ((_ref = (_ref1 = ko.unwrapObservable(o)) != null ? _ref1.length : void 0) != null ? _ref : 0) === 0;
  };

  ko.first = function(o) {
    var _ref;

    return (_ref = ko.unwrapObservable(o)) != null ? _ref[0] : void 0;
  };

  ko.last = function(o) {
    var _ref;

    return (_ref = ko.unwrapObservable(o)) != null ? typeof _ref.slice === "function" ? _ref.slice(-1)[0] : void 0 : void 0;
  };

  ko.all = function() {
    var all, arg, args, _i, _len;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    all = true;
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      arg = args[_i];
      all && (all = ko.unwrapObservable(arg));
    }
    return all;
  };

  ko.any = function() {
    var arg, args, v, _i, _len;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    for (_i = 0, _len = args.length; _i < _len; _i++) {
      arg = args[_i];
      v = ko.unwrapObservable(arg);
      if (v) {
        return v;
      }
    }
    return false;
  };

  ko.join = function() {
    var arg, args;

    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return ((function() {
      var _i, _len, _results;

      _results = [];
      for (_i = 0, _len = args.length; _i < _len; _i++) {
        arg = args[_i];
        _results.push(ko.unwrapObservable(arg));
      }
      return _results;
    })()).join("-");
  };

  ko.include = ko.includes = function(collection, value) {
    collection = ko.unwrapObservable(collection);
    value = ko.unwrapObservable(value);
    return collection.indexOf(value) >= 0;
  };

  ko.includer = function(observable, item) {
    return ko.computed({
      read: function() {
        return ko.includes(observable, item);
      },
      write: function(shouldInclude) {
        var includes, unwrapped;

        includes = ko.includes(observable, item);
        if (includes === shouldInclude) {
          return;
        }
        unwrapped = ko.finalObservable(observable);
        if (shouldInclude) {
          return unwrapped.push(item);
        } else {
          return unwrapped.remove(item);
        }
      }
    });
  };

  ko.toggler = function(observable) {
    return function() {
      var current;

      current = observable();
      return observable(!current);
    };
  };

  ko.get = function(root, path) {
    var step, steps, _i, _len;

    if (arguments.length < 2) {
      path = root;
      root = this;
    }
    steps = path.split(".");
    root = ko.unwrapObservable(root);
    for (_i = 0, _len = steps.length; _i < _len; _i++) {
      step = steps[_i];
      if (!root) {
        break;
      }
      root = root[step];
      root = ko.unwrapObservable(root);
    }
    return root;
  };

  ko.ifElse = function(condition, ifTrue, ifFalse) {
    condition = ko.unwrapObservable(condition);
    return ko.unwrapObservable(condition ? ifTrue : ifFalse);
  };

  ko.ViewModel = (function() {
    function ViewModel() {
      var item, later, _i, _len;

      later = this.constructor.later;
      if (later) {
        for (_i = 0, _len = later.length; _i < _len; _i++) {
          item = later[_i];
          item.call(this);
        }
      }
    }

    ViewModel.prototype.bind = function(target) {
      if (target && target instanceof Element) {
        return ko.applyBindings(this, target);
      } else if (target) {
        target = $(target)[0];
        return ko.applyBindings(this, target);
      } else {
        return ko.applyBindings(this);
      }
    };

    ViewModel.prototype.get = function(path) {
      return ko.get(this, path);
    };

    ViewModel.prepareLater = function() {
      var item, later, _i, _len, _ref;

      if (this.later && this.later.owner === this) {
        return;
      }
      later = [];
      later.owner = this;
      if (this.later) {
        _ref = this.later;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          later.push(item);
        }
      }
      return this.later = later;
    };

    ViewModel.property = function(name, value) {
      this.prepareLater();
      return this.later.push(function() {
        var array, item, _i, _len;

        if (value instanceof Array) {
          array = [];
          for (_i = 0, _len = value.length; _i < _len; _i++) {
            item = value[_i];
            array.push(item);
          }
          return this[name] = ko.observableArray(array);
        } else {
          return this[name] = ko.observable(value);
        }
      });
    };

    ViewModel.accessor = function(name, f) {
      this.prepareLater();
      return this.later.push(function() {
        var self;

        self = this;
        if (f instanceof Function) {
          return this[name] = ko.computed({
            read: function() {
              return f.apply(self, arguments);
            },
            deferEvaluation: true
          });
        } else {
          return this[name] = ko.computed({
            deferEvaluation: true,
            read: function() {
              if (!f.read) {
                throw new Error("read not supported");
              }
              return f.read.apply(self, arguments);
            },
            write: function() {
              if (!f.write) {
                throw new Error("write not supported");
              }
              return f.write.apply(self, arguments);
            }
          });
        }
      });
    };

    ViewModel.alias = function(name, otherName) {
      return this.accessor(name, {
        read: function() {
          return this[otherName]();
        },
        write: function() {
          return this[otherName].apply(this, arguments);
        }
      });
    };

    ViewModel.hasMany = function(name, backer, collection, identifier) {
      if (identifier == null) {
        identifier = _.identity;
      }
      return this.accessor(name, {
        read: function() {
          var ids, items;

          ids = ko.unwrapObservable(this[backer]);
          items = ko.unwrapObservable(this[collection]);
          return _(ids).chain().map(function(id) {
            return _(items).detect(function(item) {
              return String(identifier(item)) === String(id);
            });
          }).compact().value();
        },
        write: function(values) {
          var ids, oldIds, _ref;

          if (values == null) {
            values = [];
          }
          this[backer].removeAll();
          oldIds = ko.unwrapObservable(this[backer]);
          ids = _.map(values, identifier);
          return (_ref = this[backer]).splice.apply(_ref, [0, oldIds.length].concat(__slice.call(ids)));
        }
      });
    };

    ViewModel.hasOne = function(name, backer, collection, identifier, exactlyOne) {
      if (identifier == null) {
        identifier = _.identity;
      }
      if (exactlyOne == null) {
        exactlyOne = false;
      }
      return this.accessor(name, {
        read: function() {
          var id, items, result;

          id = ko.unwrapObservable(this[backer]);
          items = ko.unwrapObservable(this[collection]);
          if (id != null) {
            result = _.detect(items, function(item) {
              return String(identifier(item)) === String(id);
            });
          }
          if (!result && exactlyOne) {
            result = _.first(items);
            if (result) {
              this[backer](identifier(result));
            }
          }
          return result;
        },
        write: function(value) {
          if (value == null) {
            return this[backer](null);
          }
          if (!_.isObject(value)) {
            if (typeof console !== "undefined" && console !== null) {
              if (typeof console.log === "function") {
                console.log("Setting " + name + " (hasOne) to non-object. Did you mean to set " + backer + " instead?", value);
              }
            }
          }
          return this[backer](String(identifier(value)));
        }
      });
    };

    ViewModel.filter = function(name, backer, collection, selector) {
      return this.accessor(name, function() {
        var all, item, value, _i, _len, _ref;

        all = [];
        value = this[backer]();
        _ref = ko.unwrapObservable(this[collection]);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          if (value === selector(item)) {
            all.push(item);
          }
        }
        return all;
      });
    };

    ViewModel.unique = function(name, collection, selector) {
      return this.accessor(name, function() {
        var all, item, value, _i, _len, _ref;

        all = [];
        _ref = ko.unwrapObservable(this[collection]);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          value = selector(item);
          if (!_(all).include(value)) {
            all.push(value);
          }
        }
        return all.sort();
      });
    };

    ViewModel.dateAccessor = function(name, backer) {
      return this.accessor(name, {
        read: function() {
          var value;

          value = this[backer]();
          if (!value) {
            return "";
          }
          return $.datepicker.formatDate(CONFIG.datpickerSettings.dateFormat, value);
        },
        write: function(value) {
          var parsed;

          parsed = $.datepicker.parseDate(CONFIG.datpickerSettings.dateFormat, value);
          return this[backer](parsed);
        }
      });
    };

    ViewModel["enum"] = function(name, collection, value) {
      var backer;

      backer = "_" + name;
      this.property(backer, value);
      return this.accessor(name, {
        read: function() {
          return this[backer]();
        },
        write: function(value) {
          var all;

          all = collection;
          if (!_.isArray(collection)) {
            all = ko.unwrapObservable(this[collection]);
          }
          if (_.contains(all, value)) {
            return this[backer](value);
          } else {
            return typeof console !== "undefined" && console !== null ? typeof console.log === "function" ? console.log("The value '" + value + "' is invalid for enum property '" + name + "'.", value, all) : void 0 : void 0;
          }
        }
      });
    };

    return ViewModel;

  })();

  ko.tryBind = function(query, viewModelClass) {
    var view, viewModel;

    view = $(query);
    if (view.length > 0) {
      viewModel = new viewModelClass();
      return ko.applyBindings(viewModel, view.get(0));
    }
  };

}).call(this);
