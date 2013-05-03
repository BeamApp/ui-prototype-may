(function() {
  var BEAM_BY_LONGPRESS, TOUCH, defer, log,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  TOUCH = ('ontouchstart' in window) || ('onmsgesturechange' in window);

  BEAM_BY_LONGPRESS = true;

  defer = function(f) {
    var scheduler;

    scheduler = typeof webkitRequestAnimationFrame !== "undefined" && webkitRequestAnimationFrame !== null ? webkitRequestAnimationFrame : setTimeout;
    return scheduler(f, 0);
  };

  log = function(msg) {
    console.log.apply(console, arguments);
    return true;
  };

  $(function() {
    var $c, $d, beginDrag, checkDrag, copyCoords, dragIndicator, dragIntent, dragging, endDrag, moveDragIndicator, touchEntered, _beginDrag;

    $c = $("#container");
    $c.on("scrollstart", function() {
      e.preventDefault();
      return false;
    });
    $d = $(document);
    dragIndicator = null;
    dragging = false;
    dragIntent = null;
    moveDragIndicator = function(e) {
      if (!((e != null) && (dragIndicator != null))) {
        return;
      }
      dragIndicator.css({
        left: e.pageX,
        top: e.pageY
      });
      return true;
    };
    beginDrag = function(e) {
      var chain;

      chain = $(e.target).parents().andSelf();
      chain.filter(".draggable").addClass("dragHover");
      dragIntent = new DragIntent(e);
      dragIntent.isMaybeDrag = chain.is(".draggable");
      dragIntent.isMaybeSwipe = chain.is(".swipeable");
      if (BEAM_BY_LONGPRESS) {
        return dragIntent.timeout = setTimeout(_beginDrag, 250);
      }
    };
    checkDrag = function(e) {
      var dx;

      if (!dragIntent) {
        return;
      }
      dragIntent.update(e);
      if (!dragIntent.detected) {
        if (dragIntent.isStationary()) {
          return;
        }
        if (dragIntent.isVertical()) {
          dragIntent.detected = "scroll";
          dragIntent.isMaybeTap = dragIntent.isMaybeDrag = dragIntent.isMaybeSwipe = false;
        }
      }
      if (dragIntent.detected === "scroll") {
        return;
      }
      dx = dragIntent.diff().dx;
      e.preventDefault();
      if (dragIntent.isMaybeTap && dragIntent.isMaybeDrag && dx > 0) {
        dragIntent.detected = "drag";
        return _beginDrag();
      } else if (dragIntent.isMaybeSwipe) {
        dragIntent.detected = "swipe";
        dragIntent.isMaybeTap = dragIntent.isMaybeDrag = false;
        $(".pages").removeClass('animated');
        window.vm.swiping(true);
        return window.vm._left(dx);
      }
    };
    _beginDrag = function() {
      var $t, dest, h, lh, o, ow, w, _ref;

      if (!(dragIntent != null ? dragIntent.isMaybeDrag : void 0)) {
        return;
      }
      if (dragIntent.timeout) {
        clearTimeout(dragIntent.timeout);
      }
      dragging = dragIntent;
      window.vm.dragging(true);
      $c.addClass("dragging");
      dragIndicator = $("<span></span>").addClass("drag").appendTo("#container");
      $t = $(dragIntent.target).closest(".draggable");
      o = $t.offset();
      dragIndicator.text((_ref = $t.attr('title')) != null ? _ref : $t.text());
      w = dragIndicator.width();
      ow = dragIndicator.outerWidth();
      h = dragIndicator.outerHeight();
      lh = dragIndicator.css("line-height");
      dragIndicator.css({
        marginLeft: o.left - dragIntent.pageX,
        marginTop: o.top - dragIntent.pageY,
        width: $t.outerWidth(),
        lineHeight: "" + ($t.outerHeight()) + "px",
        "-webkit-transform": "rotate(-5deg)"
      });
      dest = {
        marginLeft: -ow / 2,
        marginRight: 0,
        marginTop: -h - 10,
        width: w,
        opacity: 1,
        lineHeight: lh,
        color: "rgba(0,0,0,1)"
      };
      dragIndicator.animate(dest, 200, "swing");
      moveDragIndicator(dragIntent);
      dragIntent = null;
      return true;
    };
    endDrag = function(e) {
      var oldIndicator;

      if (dragIntent != null) {
        clearTimeout(dragIntent.timeout);
        dragIntent = null;
      }
      if (e != null) {
        e.preventDefault();
      }
      dragging = false;
      window.vm.dragging(false);
      $c.removeClass("dragging");
      $(".dragHover").removeClass("dragHover");
      window.vm._left(0);
      window.vm.swiping(false);
      $(".pages").addClass('animated');
      if (dragIndicator) {
        oldIndicator = dragIndicator;
        oldIndicator.fadeOut(250, function() {
          return oldIndicator.remove();
        });
      }
      dragIndicator = null;
      return true;
    };
    $d.on("mouseenter", ".portals li", function(e) {
      if (dragging) {
        $(this).addClass("dragHover");
      }
      return true;
    });
    $d.on("mouseleave", ".portals li", function(e) {
      $(this).removeClass("dragHover");
      return true;
    });
    $d.on("mousemove", function(e) {
      if (dragging) {
        e.preventDefault();
        return moveDragIndicator(e);
      } else {
        return checkDrag(e);
      }
    });
    $d.on("mouseup", function(e) {
      var $t, afterEvent, defaultPrevented, dx, eventType, _i, _len, _ref;

      $t = $(e.target);
      if (dragging) {

      } else if (!dragIntent || dragIntent.isTap()) {
        defaultPrevented = false;
        _ref = ['tap', 'click'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          eventType = _ref[_i];
          if (!defaultPrevented) {
            afterEvent = $.Event(eventType);
            $t.trigger(afterEvent);
            defaultPrevented || (defaultPrevented = afterEvent.isDefaultPrevented());
          }
        }
        if ($t.is("textarea")) {
          return;
        }
        if ($t.is("input[type=submit]:enabled" && !defaultPrevented)) {
          $t.closest("form").trigger("submit");
        }
      } else if (dragIntent != null ? dragIntent.isSwipe() : void 0) {
        dx = dragIntent.diff().dx;
        if (dx < 0) {
          window.vm.onNext();
        } else if (dx > 0) {
          window.vm.onPrevious();
        }
      }
      endDrag(e);
      e.preventDefault();
    });
    $d.on("mousedown", ".page", function(e) {
      if (!$(e.target).is(":input, a")) {
        beginDrag(e);
      }
    });
    $d.on("mouseup", ".portals li", function() {
      if (dragging) {
        window.vm.onBeam();
      }
    });
    touchEntered = $([]);
    copyCoords = function(touchEvent, mouseEvent) {
      var x, y, _ref, _ref1;

      if (mouseEvent == null) {
        mouseEvent = {};
      }
      x = y = 0;
      if (((_ref = touchEvent.touches) != null ? _ref.length : void 0) > 0) {
        x = touchEvent.touches[0].pageX;
        y = touchEvent.touches[0].pageY;
      } else if (((_ref1 = touchEvent.changedTouches) != null ? _ref1.length : void 0) > 0) {
        x = touchEvent.changedTouches[0].pageX;
        y = touchEvent.changedTouches[0].pageY;
      } else {
        x = touchEvent.pageX;
        y = touchEvent.pageY;
      }
      mouseEvent.pageX = x;
      mouseEvent.pageY = y;
      return mouseEvent;
    };
    $d.on("touchstart", function(e) {
      var down;

      log("touchStart");
      down = $.Event('mousedown');
      copyCoords(e.originalEvent, down);
      $(e.target).trigger(down);
      if (down.isDefaultPrevented()) {
        e.preventDefault();
      }
      return true;
    });
    $d.on("touchmove", function(e) {
      var el, enter, fakeEvent, leave, newTouchEntered, pageX, pageY, _i, _j, _len, _len1, _ref;

      if (dragging) {
        e.preventDefault();
      }
      _ref = copyCoords(e.originalEvent), pageX = _ref.pageX, pageY = _ref.pageY;
      el = document.elementFromPoint(pageX, pageY);
      if (el == null) {
        return;
      }
      newTouchEntered = $(el).parents().andSelf();
      for (_i = 0, _len = touchEntered.length; _i < _len; _i++) {
        el = touchEntered[_i];
        if (__indexOf.call(newTouchEntered, el) < 0) {
          leave = $.Event('mouseout');
          leave.pageX = pageX;
          leave.pageY = pageY;
          leave.target = el;
          leave.relatedTarget = newTouchEntered.get(-1);
          $(el).trigger(leave);
        }
      }
      for (_j = 0, _len1 = newTouchEntered.length; _j < _len1; _j++) {
        el = newTouchEntered[_j];
        if (__indexOf.call(touchEntered, el) < 0) {
          enter = $.Event('mouseover');
          enter.pageX = pageX;
          enter.pageY = pageY;
          enter.target = el;
          enter.relatedTarget = touchEntered.get(-1);
          $(el).trigger(enter);
        }
      }
      touchEntered = newTouchEntered;
      fakeEvent = $.Event('mousemove');
      fakeEvent.pageX = pageX;
      fakeEvent.pageY = pageY;
      $(el).trigger(fakeEvent);
      if (fakeEvent.isDefaultPrevented()) {
        e.preventDefault();
      }
    });
    return $d.on("touchend touchcancel", function(e) {
      var el, up;

      log("touchEnd");
      touchEntered = $([]);
      up = $.Event('mouseup');
      copyCoords(e.originalEvent, up);
      el = document.elementFromPoint(up.pageX, up.pageY);
      $(el).trigger(up);
      if (up.isDefaultPrevented()) {
        e.preventDefault();
      }
      return true;
    });
  });

}).call(this);
