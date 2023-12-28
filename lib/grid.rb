require_relative 'dimension'

# name is overreach here

class Grid
  attr_reader :x, :y, :dx, :dy, :name, :frame
  alias w x
  alias h y

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

  attr_reader :xs, :ys

  def apply width, height
    frame = @frame ? @frame[width, height] : nil
    dx = frame ? frame.x : 0
    dy = frame ? frame.y : 0
    width = frame ? frame.width : width
    height = frame ? frame.height : height

    @xs = Dimension.new width, @x, delta: dx
    @ys = Dimension.new height, @y, delta: dy
    self
  end

  def at pos_or_x, maybe_y=nil, corner: 0
    x = nil
    y = nil
    if maybe_y
      x = pos_or_x
      y = maybe_y
    else
      (x, y) = pos_or_x.to_a
    end
    [
      @xs.at(x, corner: corner),
      @ys.at(y, corner: corner),
    ]
  end

  # x, y - smaller ones
  def rect x, y, x2, y2
    Rect[*at(x, y), *at(x2, y2, corner: 1)]
  end

  # top-left
  def tl
    Pos[0, @y - 1]
  end
  def tr
    Pos[@x - 1, @y - 1]
  end
  def bl
    Pos[0, 0]
  end
  def br
    Pos[@x - 1, 0]
  end
  alias lt tl
  alias rt tr
  alias lb bl
  alias rb br
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
