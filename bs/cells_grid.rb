module BS
  # grid is already initialized for this to work
  #
  class CellsGrid
    attr_reader :cells
    attr_reader :line_points

    def initialize x:, y:, w:, h:, scale: 1
      pos = Pos[x, y]

      lines = (w+1).times.map { |i|
        [Pos[0, i * scale], Pos[w * scale, i * scale]]
      } + (h+1).times.map { |i|
        [Pos[i * scale, 0], Pos[i * scale, h * scale]]
      }

      @line_points = lines.map { |points|
        points.map { |x| x + pos }.map { |x| $bs.g.at *x }
      }

      @cells = h.times.reverse_each.flat_map { |y|
        w.times.map { |x|
          Pos[pos.x + x * scale, pos.y + y * scale]
        }
      }

      @scale = scale
    end

    def draw_grid
      @line_points.each { |xs|
        $bs.pdf.stroke_line *xs
      }
    end
  end
end
