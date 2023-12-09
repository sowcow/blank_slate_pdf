require_relative 'dimension'

class Grid
  attr_reader :x, :y, :dx, :dy, :name, :frame

  def initialize x: 12, y: 16, dx: 0, dy: 0, name: 'dots', frame: nil
    @x = x
    @y = y
    @dx = dx
    @dy = dy
    @name = name
    @attr_names = %i[x y dx dy name]
    @frame = frame
  end

  def configure context
    that = self
    @attr_names.each { |name|
      params = { :"grid_#{name}" => public_send(name) }
      context.configure params, deep: false
      # non-dynamic..., passing lambdas would provide that (+handling)
      # anyway dynamic grid.abc is there anyway
      # so it is more like a temporary legacy glue, so no point to overcommit there
    }
  end

  attr_reader :by_x, :by_y

  def apply width, height
    frame = @frame ? @frame[width, height] : nil
    dx = frame ? frame.x : 0
    dy = frame ? frame.y : 0
    width = frame ? frame.width : width
    height = frame ? frame.height : height

    @by_x = Dimension.new width, @x, delta: dx
    @by_y = Dimension.new height, @y, delta: dy
    self
  end

  def at x, y, corner: 0
    [
      @by_x.at(x, corner: corner),
      @by_y.at(y, corner: corner),
    ]
  end

  # x, y - smaller ones
  def rect x, y, x2, y2
    Rect[*at(x, y), *at(x2, y2, corner: 1)]
  end
end

class Rect < Struct.new :x, :y, :x2, :y2
  def width
    x2 - x
  end

  def height
    y2 - y
  end

  def to_a
    [x, y, x2, y2]
  end

  def margin *a
    to_a.margin *a
  end
end
