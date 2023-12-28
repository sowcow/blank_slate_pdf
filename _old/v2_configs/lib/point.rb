class Point < Struct.new :x, :y
  def self.from given
    case given
    when Point
      given
    when Array
      Point[*given]
    else
      raise "can't convert to Point: #{given.inspect}"
    end
  end

  # into square for bigger links
  def expand w=0, h=0
    [x, y, x+w, y+h]
  end

  def to_s
    to_a.map(&:round) * ?,
  end

  # allow array input?
  def + other
    other = Point.from other
    Point[x + other.x, y + other.y]
  end

  def select count, direction: nil
    count.times.map { |i|
      public_send direction, i
    }
  end
  %i[ up down left right ].each { |name|
    define_method "select_#{name}" do |count|
      select count, direction: name
    end
  }

  def up count=1
    self + Point[0, count]
  end
  def down count=1
    self + Point[0, -count]
  end
  def left count=1
    self + Point[-count, 0]
  end
  def right count=1
    self + Point[count, 0]
  end
end

# in the grid implication grid.pos() then?
class Pos < Point
end

class At < Point
end

if __FILE__ == $0
  p Point[1, 2].to_a
  p Point[1, 2].to_h
  p Point[1, 2] + Point[3, 4]
end
