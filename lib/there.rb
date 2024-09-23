# good defaults class
#
# corner by default... (not center)
class There < Struct.new :x, :y, :ww, :hh, :center, :absolute
  # there around at
  def self.at given
    case given
    when There
      given
    when Numeric
      new given, given
    when Array
      throw "3D array??? #{given}" unless given.size == 2 || given.size == 4
      new *given
    when Hash
      xs = []
      xs.push given.fetch :x
      xs.push given.fetch :y
      if given[:w] && given[:h]
        xs.push given.fetch :w
        xs.push given.fetch :h
      end
      new *xs
    else
      throw "Where is that??? #{given}"
    end
  end

  def w
    ww || default_size
  end

  def h
    hh || default_size
  end

  def corner
    !center
  end

  def default_size
    corner ? 1 : 0
  end

  def x2
    x + w
  end

  def y2
    y + h
  end

  # name conflicting...
  def to_area
    [x, y, x2, y2]
  end

  # ground to absolute grid, currently
  def at grid
    throw if absolute

    (x, y) = grid.at [self.x, self.y]
    (x2, y2) = grid.at [self.x2, self.y2]
    ww = x2 - x
    hh = y2 - y
    absolute = true
    There.new x, y, ww, hh, center, absolute
  end

  def to_poly
    [
      [x, y],
      [x2, y],
      [x2, y2],
      [x, y2],
    ]
  end

  def to_ranges_area
    [[x, x2], [y, y2]]
  end

  # moves down too since this is what is done for holes in grid
  def expand dx=0, dy=0
    There.new x, y-dy, w + dx, h + dy, center, absolute
  end
end

if __FILE__ == $0
  raise unless There.at([5, 5]).w == 1
end
