# cutting away from 2D grid with step that is the same for x and y
# consistent way to render grids with "holes" for links
#
# kind of web?
# adding strings, cutting holes
#
class SmartGrid
  def initialize xs, ys #min_point, max_point #, step
    @xs = MyRange.from xs
    @ys = MyRange.from ys
    # could do general but why going math for this
    @verticals = []
    @horizontals = []
  end
  attr_accessor :verticals, :horizontals, :xs, :ys

  def dup
    grid = SmartGrid.new xs, ys
    grid.verticals = verticals.dup
    grid.horizontals = horizontals.dup
    grid
  end

  def add_verticals step, x_range=@xs
    x_range.step(step) { |x|
      @verticals << Line.from([x, @ys.min, x, @ys.max])
    }
  end

  def add_horizontals step, y_range=@ys
    y_range.step(step) { |y|
      @horizontals << Line.from([@xs.min, y, @xs.max, y])
    }
  end

  def not_just_border_touch area, line
    delta = 0.1
    xs = [area.xs.min + delta, area.xs.max - delta]
    ys = [area.ys.min + delta, area.ys.max - delta]
    area = Area.from [xs, ys]

    return area.xs.overlap?(line.xs) && area.ys.overlap?(line.ys)
  end
  private :not_just_border_touch

  # def cut_around area  # to also cut framing touching area
  #                      # so can reconstruct own thing on top

  # border is kept, cuts only inside
  def cut_hole area
    area = Area.from area
    updated = []
    @horizontals.each { |line|
      if not_just_border_touch(area, line)
        candidates = []
        y = line.y
        candidates.push Line.from [line.x, y, area.xs.min, y] if line.x < area.xs.min
        candidates.push Line.from [area.xs.max, y, line.x2, y] if line.x2 > area.xs.max
        updated.push *candidates
      else
        updated << line
      end
    }
    @horizontals = updated

    updated = []
    @verticals.each { |line|
      if not_just_border_touch(area, line)
        candidates = []
        x = line.x
        candidates.push Line.from [x, line.y, x, area.ys.min] if line.y < area.ys.min
        candidates.push Line.from [x, area.ys.max, x, line.y2] if line.y2 > area.ys.max
        updated.push *candidates
      else
        updated << line
      end
    }
    @verticals = updated
  end

  def drop_lines point
    point = Point.from point
    if point.x.nil?
      @horizontals.reject! { |x| x.y == point.y }
    elsif point.y.nil?
      @verticals.reject! { |x| x.x == point.x }
    else
      throw "drop line point? #{point}"
    end
  end

  def each &block
    @horizontals.each &block
    @verticals.each &block
  end

  class Area < Struct.new :xs, :ys
    def self.from given
      if given.kind_of? Array
        throw unless given.size == 2
        Area.new *given.map { |x| MyRange.from x }
      else
        throw "area? #{given}"
      end
    end
  end

  # ensures that x <= x2, same for y
  class Line < Struct.new :x, :y, :x2, :y2
    def self.from given
      if given.kind_of? Array
        throw unless given.size == 4
        given = given.dup
        if given[0] > given[2]
          (given[0], given[2]) = [given[2], given[0]]
        end
        if given[1] > given[3]
          (given[1], given[3]) = [given[3], given[1]]
        end
        Line.new *given
      else
        throw "line? #{given}"
      end
    end

    def xs
      MyRange.from [x, x2]
    end

    def ys
      MyRange.from [y, y2]
    end

    def at grid
      Line.new grid.xs.at(x), grid.ys.at(y), grid.xs.at(x2), grid.ys.at(y2)
    end
  end

  module MyRange
    def self.from given
      case given
      when Range
        given
      when Array
        throw unless given.size == 2
        Range.new *given.sort
      else
        throw "range? #{given}"
      end
    end
  end

  Point = Struct.new :x, :y do
    def self.from given
      if given.kind_of? Array
        throw unless given.size == 2
        Point.new *given
      else
        given
      end
    end
  end
end

# could control direction of rendering with direction of range, need to use own class then

if __FILE__ == $0
  p SmartGrid.new([0, 5], [0, 5])
  x = SmartGrid.new [0, 5], [0, 5]
  x.add_verticals 2
  x.add_horizontals 2
  x.cut_hole [[0, 1], [0, 1]]
  x.each { |y| p y } #...
end
