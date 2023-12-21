module Contour
  # neat algorithm worked from the first run (except for floating point comparison and some omission)
  def self.sequence squares, step
    epsilon = step / 10.0

    points = squares.flat_map { |x|
      x.points
    }

    by_count = {}
    compare = -> a, b {
      dx = (a.x - b.x).abs
      dy = (a.y - b.y).abs
      dx + dy < epsilon
    }
    points.each { |x|
      found_key = nil
      by_count.keys.each { |k|
        found_key = k if compare[k, x]
      }
      if found_key
        by_count[found_key] << x
      else
        by_count[x] = [x]
      end
    }

    boundary = by_count.select { |k, v| v.count < 4 }.keys

    sequence = []
    sequence << boundary.shift

    # compass-going I call it
    while boundary.any?
      current = sequence.last

      at_right = boundary.select { |p| p.x > current.x && p.y == current.y }.min_by { |p| (current.x - p.x).abs }
      candidate = at_right
      if candidate && (current.x - candidate.x).abs - step < epsilon
        sequence << candidate
        boundary.reject! { |x| x == candidate }
        next
      end

      below = boundary.select { |p| p.y < current.y && p.x == current.x }.min_by { |p| (current.y - p.y).abs }
      candidate = below
      if candidate && (current.y - candidate.y).abs - step < epsilon
        sequence << candidate
        boundary.reject! { |x| x == candidate }
        next
      end

      at_left = boundary.select { |p| p.x < current.x && p.y == current.y }.min_by { |p| (current.x - p.x).abs }
      candidate = at_left
      if candidate && (current.x - candidate.x).abs - step < epsilon
        sequence << candidate
        boundary.reject! { |x| x == candidate }
        next
      end

      above = boundary.select { |p| p.y > current.y && p.x == current.x }.min_by { |p| (current.y - p.y).abs }
      candidate = above
      if candidate && (current.y - candidate.y).abs - step < epsilon
        sequence << candidate
        boundary.reject! { |x| x == candidate }
        next
      end
    end

    sequence
  end
end

class Square < Struct.new :x, :y, :x2, :y2
  def self.sized x, y, size=1
    Square.new x, y, x+size, y+size
  end

  def points
    [
      Point[x, y],
      Point[x2, y],
      Point[x2, y2],
      Point[x, y2],
    ]
  end

  class Point < Struct.new :x, :y
    def to_s
      to_a.map(&:round) * ?,
    end
  end
end

if __FILE__ == $0
  xs = []
  xs << Square.sized(0, 0)
  xs << Square.sized(1, 0)
  xs << Square.sized(1, 1)
  xs << Square.sized(0, 1)
  r = Contour.sequence xs, 1
  p r.map &:to_s
end
