require_relative 'base'
require_relative '../_old/v2_configs/lib/calendar'
require_relative '../_old/v2_configs/lib/contour'

# TODO: reuse around generate returning self and Base
# (do I need to store a data variable in bs/items at all?
# (data of pages could be enough?)
# (store in parent some?)
# (the merging I use could be less powerful then dynamic resolution)

# can split configure more and generate
# to have own order of week pages since I'll use items anyway

module BS
  class Month < Base
    KEY = :month

    attr_reader :month

    def setup year: , month: , parent: nil, dy: nil, font_color: nil
      @year = year
      @month = month
      @parent = parent
      @dy = dy if dy
      @font_color = font_color if font_color
      self
    end

    def squares
      @squares ||= get_squares @year, @month
    end

    # cold be generate_days/weeks or weeks: param if needed
    def generate year: @year, month: @month, parent: @parent, &block
      raise unless year
      raise unless month
      setup year: year, month: month, parent: parent

      parent = parent || BS.pages.get(:root)

      parent.data.merge! key(:squares) => squares

      squares.each { |x|
        parent.child_page key(:day), key(:square) => x do
          link_back
          instance_eval &block if block
        end
      }

      self
    end

    def week_squares
      week_count = squares.last.week + 1 # from 0
      week_count.times.map { |week|
        squares.reverse.find { |x| x.week == week }
          .pos.down
      }
    end

    def get_squares year, month
      calendar = MonthCalendar.for_date year, month
      step = 0
      calendar.to_a.map { |d|
        (week, weekday, day) = d.fetch_values :week, :weekday, :day
        x = week * 2
        y = 18 - weekday * 2 - 2 # cell size
        if @dy
          y += @dy
        end
        at = $bs.g.at x, y, corner: 0
        at2 = $bs.g.at x + 2, y + 2, corner: 0
        size = at2[0] - at[0]
        step = size
        square = Square.sized at[0], at[1], size
        square.define_singleton_method :day do day end
        square.define_singleton_method :pos do Pos[x, y] end
        square.define_singleton_method :week do week end
        square.define_singleton_method :weekday do weekday end
        square
      }
    end

    def draw_all_squares squares
      squares.each { |x|
        draw_square x
      }
    end

    def draw_square square
      $bs.instance_eval do
        # day cell size
        step = g.xs.at(2, corner: 1) - g.xs.at(1, corner: 0)

          polygon *square.points.map { |x| [x.x, x.y] }
          day = square.day.to_s
          (x, y) = square.pos.to_a
          text_at = grid.at x, y+2, corner: 0 # text needs that shift up the cell

          color @font_color || ?8 do
          font $roboto_light do
            font_size step * 0.25 do
              text = day.to_s
              pad_x = step * 0.05
              pad_y = step * 0.025
              pdf.text_box text, at: text_at, width: step-pad_x, height: step-pad_y, align: :right, valign: :bottom
            end
          end
          end
      end
    end

    def breadcrumb pages
      up = self
      pages.each { |page|
        square = page[key :square]
        page.visit do
          up.draw_square square
        end
      }
    end

    # goes across pages, adds visuals and links
    def integrate pages=BS.pages, bread: false  #, this: false
      #return $bs.data[key].integrate pages, this: true unless this
      days = pages.xs(key :day)

      already_linked = {}
      up = self

      breadcrumb days if bread

      days.each { |page|
        square = page[key :square]
        pos = square.pos
        #pos = pos.up(@dy)

        next if already_linked[[square, page.parent]]
        page.parent.visit do
          link pos.expand(1, 1), page
        end
        already_linked[[square, page.parent]] = true
      }

      days.first.parent.visit do
        up.draw_all_squares page[up.key :squares]
      end
    end
  end
end
