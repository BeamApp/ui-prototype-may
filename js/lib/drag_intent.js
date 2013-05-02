(function() {
  this.DragIntent = (function() {
    function DragIntent(e) {
      this.startedAt = Date.now();
      this.pageX = e.pageX;
      this.pageY = e.pageY;
      this.startX = e.pageX;
      this.startY = e.pageY;
      this.target = e.target;
    }

    DragIntent.prototype.update = function(e) {
      this.pageX = e.pageX;
      return this.pageY = e.pageY;
    };

    DragIntent.prototype.isTap = function() {
      return this.isStationary() && !this.isQuickTap() && !this.isLongTap();
    };

    DragIntent.prototype.isQuickTap = function() {
      return false;
    };

    DragIntent.prototype.isLongTap = function() {
      return this.isStationary() && Date.now() > this.startedAt + 750;
    };

    DragIntent.prototype.diff = function() {
      return {
        dx: this.pageX - this.startX,
        dy: this.pageY - this.startY
      };
    };

    DragIntent.prototype.absDiff = function() {
      var dx, dy, _ref;

      _ref = this.diff(), dx = _ref.dx, dy = _ref.dy;
      return {
        dx: Math.abs(dx),
        dy: Math.abs(dy)
      };
    };

    DragIntent.prototype.distance2 = function() {
      var dx, dy, _ref;

      _ref = this.absDiff(), dx = _ref.dx, dy = _ref.dy;
      return dx + dy;
    };

    DragIntent.prototype.isStationary = function() {
      return this.distance2() <= 10;
    };

    DragIntent.prototype.isVertical = function() {
      var dx, dy, _ref;

      _ref = this.absDiff(), dx = _ref.dx, dy = _ref.dy;
      return dy > 0 && dy > dx;
    };

    DragIntent.prototype.isHorizontal = function() {
      var dx, dy, _ref;

      _ref = this.absDiff(), dx = _ref.dx, dy = _ref.dy;
      return dx > 0 && dx > dy;
    };

    DragIntent.prototype.isSwipe = function() {
      return !this.isTap() && !this.isStationary() && this.isHorizontal();
    };

    DragIntent.prototype.isScroll = function() {
      return !this.isTap() && !this.isStationary() && this.isVertical();
    };

    DragIntent.prototype.isMaybeTap = true;

    DragIntent.prototype.isMaybeSwipe = true;

    return DragIntent;

  })();

}).call(this);
