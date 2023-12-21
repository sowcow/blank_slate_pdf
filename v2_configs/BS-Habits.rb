require_relative 'lib/calendar'
require_relative 'lib/contour'

# ~ single imagemagick replicated 48 times - very optional optimization...

# BS-habits is a fun name
# mirror analogy would be interesting but it pre-supposes some relation I'm not sure is wanted

this_name = File.basename(__FILE__).sub /\..*/, ''

frame = -> w, h { Grid.new.apply(w,h).rect 1, 0, -2, -2 }

WEEK_MON = %w[monday tuesday wednesday thursday friday saturday sunday]
WEEK_SUN = %w[sunday monday tuesday wednesday thursday friday saturday]

def configure_calendar days:, month_start:, week:
  month_start_weekday = week.index(month_start) or raise 'wrong :month_start given for the :week'
  calendar = MonthCalendar.new days: days, month_start_weekday: month_start_weekday
end

BS_Habits = BlankSlatePDF.new(this_name) do
  configure $setup
  configure({ grid: Grid.new(x: 12, y: 18, name: :stars, frame: frame).apply(PAGE_WIDTH, PAGE_HEIGHT) })

  description <<-END
    # BS-habits

    Abstract and flexible keywords stand here as well.
    The idea is to have habits calendar per month in own file.
    Yet also abstract from month and year - usable at any matching by shape month.
  END

  calendar = configure_calendar days: day_count, month_start: start_weekday, week: week

  step = 0
  squares = calendar.to_a.map { |d|
    (week, weekday, day) = d.fetch_values :week, :weekday, :day
    x = week * 2
    y = 18 - weekday * 2 - 2 # cell size
    at = grid.at x, y, corner: 0
    at2 = grid.at x + 2, y + 2, corner: 0
    size = at2[0] - at[0]
    step = size
    square = Square.sized at[0], at[1], size
    square.define_singleton_method :day do day end
    square.define_singleton_method :pos do [x, y] end
    square
  }
  contour_points = Contour.sequence squares, step

  draw_month_contour = -> _ {
    color 8 do
      pdf.stroke_polygon *contour_points.map { |x| [x.x, x.y] }
    end
  }

  draw_days_squares = -> _ {
    color 8 do
      squares.each { |square|
        pdf.stroke_polygon *square.points.map { |x| [x.x, x.y] }
        day = square.day.to_s
        (x, y) = square.pos
        text_at = grid.at x, y+2, corner: 0 # text needs that shift up the cell
        font $roboto do
          font_size step * 0.25 do
            text = day.to_s
            pad_x = step * 0.05
            pad_y = step * 0.025
            pdf.text_box text, at: text_at, width: step-pad_x, height: step-pad_y, align: :right, valign: :bottom
          end
        end
      }
    end
  }

  draw_grid = -> _ {
    public_send @context.set_grid_name
    #draw_stars
  }

  pages = []
  item_cell_to_page = {}

  item_cells = []
  18.times { |i|
    item_cells << [-1.0, 18 - 1 - i] # at the left of the grid
  }
  12.times { |i|
    item_cells << [i, 18] # above the grid
  }
  18.times { |i|
    item_cells << [12, 18 - 1 - i] # at the right of the grid
    # pages are often turned + RM seem to have improved accidental hand recognition so no point in avoiding
    # at least to test how it goes
    # could cover RTL or left hand if it works-out well
  }

  page do
    pages << page_stack.last
    instance_eval &draw_month_contour
    instance_eval &draw_grid

    item_cells.each { |item_cell|
      page do
        pages << page_stack.last
        item_cell_to_page[item_cell] = pages.last

        instance_eval &draw_days_squares
        instance_eval &draw_grid
        double_back_arrow

        diamond item_cell, corner: 0.5
      end
    }
  end

  pages.each { |page|
    revisit_page page do
      item_cells.each { |item_cell|
        that_page = item_cell_to_page[item_cell]
        link! item_cell, that_page
      }
    end
  }

  render_file
end

have_grid_versions = -> given_bs {
  result = []

  bs = given_bs.dup
  bs.name = "BG-SAND_#{bs.name}"
  bs.configure({set_grid_name: :draw_sand}, deep: false)
  result << bs

  bs = given_bs.dup
  bs.name = "BG-STARS_#{bs.name}"
  bs.configure({set_grid_name: :draw_stars}, deep: false)
  result << bs

  result
}

have_week_variations = -> given_bs {
  result = []

  bs = given_bs.dup
  bs.name = "MON_#{bs.name}"
  bs.configure({ week: WEEK_MON }, deep: false)
  result << bs

  bs = given_bs.dup
  bs.name = "SUN_#{bs.name}"
  bs.configure({ week: WEEK_SUN }, deep: false)
  result << bs

  result
}

have_start_day_variations = -> given_bs {
  result = []

  WEEK_MON.each { |weekday|
    bs = given_bs.dup
    bs.name = "from_#{weekday.upcase}_#{bs.name}"
    bs.configure({ start_weekday: weekday }, deep: false)
    result << bs
  }

  result
}

have_day_count_variations = -> given_bs {
  result = []

  [28,29,30,31].each { |day_count|
    bs = given_bs.dup
    bs.name = "#{day_count}_days_#{bs.name}"
    bs.configure({ day_count: day_count }, deep: false)
    result << bs
  }

  result
}

result = [BS_Habits.dup]
result = result.flat_map(&have_grid_versions)
result = result.flat_map(&have_week_variations)
result = result.flat_map(&have_start_day_variations)
result = result.flat_map(&have_day_count_variations)

$configs_loaded = result
