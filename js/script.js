(function() {
  var Counter, SubjectGroup, ViewModel, next, _ref, _ref1,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  $(window).keydown(function(e) {
    if (e.keyCode === 32) {
      debugger;
    }
  });

  ko.bindingHandlers.tap = {
    update: function(element, valueAccessor) {
      var callback;

      callback = ko.unwrapObservable(valueAccessor());
      return $(element).on("tap", function(e) {
        if (e != null) {
          if (typeof e.preventDefault === "function") {
            e.preventDefault();
          }
        }
        return callback();
      });
    }
  };

  ko.bindingHandlers.click = {
    update: function(element, valueAccessor) {
      var callback;

      callback = ko.unwrapObservable(valueAccessor());
      return $(element).on("click", function(e) {
        if ($(this).is("a")) {
          if (e != null) {
            if (typeof e.preventDefault === "function") {
              e.preventDefault();
            }
          }
        }
        if (e != null) {
          e.stopPropagation();
        }
        if (window.vm.swiping() || window.vm.dragging()) {
          return;
        }
        return callback();
      });
    }
  };

  Counter = function() {
    var i;

    i = 0;
    return function() {
      return i++;
    };
  };

  if ((_ref = Math.clamp) == null) {
    Math.clamp = function(min, max, v) {
      var t;

      if (max < min) {
        t = min;
        min = max;
        max = t;
      }
      return Math.min(max, Math.max(min, v));
    };
  }

  if ((_ref1 = Math.sinh) == null) {
    Math.sinh = function(arg) {
      return (Math.exp(arg) - Math.exp(-arg)) / 2;
    };
  }

  next = new Counter;

  SubjectGroup = (function(_super) {
    __extends(SubjectGroup, _super);

    SubjectGroup.property("title");

    SubjectGroup.property("items", []);

    function SubjectGroup(t) {
      var i, _i, _len, _ref2;

      if (t == null) {
        t = "untitled";
      }
      SubjectGroup.__super__.constructor.apply(this, arguments);
      this.title(t);
      _ref2 = [1, 2, 3, 4];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        i = _ref2[_i];
        this.items.push("Subject " + (next() + 1));
      }
    }

    return SubjectGroup;

  })(ko.ViewModel);

  ViewModel = (function(_super) {
    __extends(ViewModel, _super);

    function ViewModel() {
      this.onSubmitDetail = __bind(this.onSubmitDetail, this);
      this.onCancelDetail = __bind(this.onCancelDetail, this);
      this.onBeam = __bind(this.onBeam, this);
      this.onPortalClicked = __bind(this.onPortalClicked, this);
      this.onTap = __bind(this.onTap, this);
      this.onPrevious = __bind(this.onPrevious, this);
      this.onNext = __bind(this.onNext, this);      ViewModel.__super__.constructor.apply(this, arguments);
      this.left = this.left.extend({
        throttle: 1
      });
    }

    ViewModel.property("groupedSubjects", [new SubjectGroup("Safari"), new SubjectGroup("Clipboard"), new SubjectGroup("Guru")]);

    ViewModel.property("portals", ["MacBook", "MacBook Pro", "Windows PC", "iPhone", "iPod", "iMac", "Car", "TV", "Windows Phone", "Nexus 7"]);

    ViewModel.property("dragging", false);

    ViewModel.property("swiping", false);

    ViewModel.property("viewportWidth", document.width);

    ViewModel.property("selectedSubject", null);

    ViewModel.property("detailedSubject", null);

    ViewModel.property("draggedSubject", null);

    ViewModel.accessor("hasNext", function() {
      return !this.dragging() && !this.swiping() && this.page() === 0 && !this.detailedSubject();
    });

    ViewModel.accessor("hasPrevious", function() {
      return this.page() > 0;
    });

    ViewModel.property("_left", 0);

    ViewModel.accessor("left", function() {
      var l, regular, x;

      regular = -1 * this.page() * this.viewportWidth();
      if (this.swiping()) {
        regular += this._left();
      }
      l = 10;
      if (regular > 0) {
        x = regular;
        regular = Math.atan(x / l) * l;
      } else if (regular < -this.viewportWidth()) {
        x = -1 * (regular + this.viewportWidth());
        x = Math.atan(x / l) * l;
        regular = -1 * (x + this.viewportWidth());
      }
      return regular;
    });

    ViewModel.accessor("iconLeft", function() {
      var progress;

      if (this.detailedSubject()) {
        return 0;
      }
      progress = -1 * this.left() / this.viewportWidth();
      return -1 * (5 + 1 + 10 + 24 / 2 + 20) * (1 - progress);
    });

    ViewModel.property("_page", 0);

    ViewModel.accessor("page", function() {
      if (this.dragging()) {
        return 1;
      } else if (this.selectedSubject()) {
        return 1;
      } else {
        return this._page();
      }
    });

    ViewModel.prototype.onNext = function() {
      return this._page(1);
    };

    ViewModel.prototype.onPrevious = function() {
      this._page(0);
      return this.selectedSubject(null);
    };

    ViewModel.prototype.onTap = function(item) {
      return this.detailedSubject(item);
    };

    ViewModel.prototype.onPortalClicked = function(item) {
      if (this.selectedSubject()) {
        return this.onBeam();
      }
    };

    ViewModel.prototype.onBeam = function(item) {
      var self;

      this.selectedSubject(null);
      return self = $("<div>").text("Beamed!").addClass("message").appendTo("#container").css({
        opacity: 0
      }).fadeTo(100, 1).delay(500).fadeOut(100, function() {
        return self.remove();
      });
    };

    ViewModel.prototype.onCancelDetail = function() {
      return this.detailedSubject(null);
    };

    ViewModel.prototype.onSubmitDetail = function() {
      $(":focus").blur();
      this.selectedSubject(this.detailedSubject());
      return this.detailedSubject(null);
    };

    ViewModel.accessor("secondPageTitle", function() {
      if (this.dragging() || this.selectedSubject()) {
        return "...to...";
      } else {
        return "Your Portals";
      }
    });

    return ViewModel;

  })(ko.ViewModel);

  $(function() {
    var vm;

    window.vm = vm = new ViewModel;
    ko.applyBindings(vm);
    return $(window).on("resize", function() {
      return vm.viewportWidth(document.width);
    });
  });

}).call(this);
