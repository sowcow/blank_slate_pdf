# for use on
# 12-squares width grid where each cell being subdivided into 4 more
# coordinates are in terms of 12 grid so there are .5 at times
# it aligns to the grid but very close in shape to true hexagon
#
class Hexagon
  def initialize
    points = []
    points << [0, 2 + 4]
    points << [3.5, 2 + 4 + 2]
    points << [3.5*2, 2 + 4]
    points << [0, 2]
    points << [3.5, 0]
    points << [3.5*2, 2]

    center_at = [3.5, 2 + 2]
    points.map! { |xy|
      [
        xy[0] - center_at[0],
        xy[1] - center_at[1],
      ]
    }

    @points = points
  end

  def rotate
    @points = @points.map { |x, y|
      [y, x]
    }
    self
  end

  def diagonals
    @points.combination(2).select { |a, b|
      a[0] != b[0] && a[1] != b[1]
    }
  end

  def transition dxdy
    @points = @points.map { |xy|
      [xy[0] + dxdy[0], xy[1] + dxdy[1]]
    }
    self
  end
end

if __FILE__ == $0
  p Hexagon.new.diagonals.count
end
