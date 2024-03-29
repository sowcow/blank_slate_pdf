module BS
  class Group
    def initialize
      @xs = []
    end

    def push *xs
      @xs.push *xs
    end

    def method_missing *a, &b
      @xs.flat_map { |x|
        x.public_send *a, &b
      }
    end
  end
  
  class LinesGrid
    def initialize
      @xs = []
      @ys = []
      @x_range = nil
      @y_range = nil
      @color = ?a
      @width = 0.5
    end

    attr_accessor :color
    attr_accessor :width

    def xs *x
      @xs.push *x
      self
    end

    def ys *x
      @ys.push *x
      self
    end

    def x_range a, b
      @x_range = [a, b].sort
      self
    end

    def y_range a, b
      @y_range = [a, b].sort
      self
    end

    def vlines
      @xs.map { |x|
        [Pos[x, y_min], Pos[x, y_max]]
      }
    end

    def hlines
      @ys.map { |y|
        [Pos[x_min, y], Pos[x_max, y]]
      }
    end

    def lines
      vlines + hlines
    end

    def dots
      @xs.flat_map { |x|
        @ys.map { |y|
          Pos[x, y]
        }
      }
    end

    def render_dots &block
      dots.each { |at|
        next if block && !block[at]
        $bs.dot at
      }
    end

    def render_lines which=:lines
      x = self
      public_send(which).each { |coords|
        $bs.color x.color do
          $bs.line_width x.width do
            $bs.poly *coords.map { |x| $bs.g.at *x }
          end
        end
      }
    end

    def rects
      result = []
      @ys.each_cons(2) { |y, y2|
        @xs.each_cons(2) { |x, x2|
          xx = [x, x2].sort
          yy = [y, y2].sort
          result << [Pos[xx.first, yy.first], Pos[xx.last, yy.last]]
        }
      }
      result
    end

    def link_rects
      rects.map { |(a, b)|
        [a, b.left.down] # non raw links do that move by themselves...
      }
      .sort_by { |p| [-p[0].y, p[0].x] } # up-down, left-right
    end

    def y_min
      return @ys.min unless @y_range
      @y_range[0]
    end
    def y_max
      return @ys.max unless @y_range
      @y_range[1]
    end
    def x_min
      return @xs.min unless @x_range
      @x_range[0]
    end
    def x_max
      return @xs.max unless @x_range
      @x_range[1]
    end
  end
end
