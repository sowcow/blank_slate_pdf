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
    end

    def xs *x
      @xs.push *x
    end

    def ys *x
      @ys.push *x
    end

    def x_range a, b
      @x_range = [a, b].sort
    end

    def y_range a, b
      @y_range = [a, b].sort
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
      public_send(which).each { |coords|
        $bs.color ?a do
          $bs.line_width 0.5 do
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
