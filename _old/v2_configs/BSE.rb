require 'date'
require_relative 'lib/calendar'
require_relative 'lib/contour'
require 'yaml'

personalize = File.join __dir__, '../../BSE.yml'
$personalize = nil
$personalize = YAML.load_file personalize if File.exist? personalize

# - [ ] 6-square week view, weekend has links to both days
# - [ ] iteration notes at the top

# I could split into two BSE, one for current and another for end of the day processing
# because big volume of pages makes on of them slow
# left and right as separate files?
# (free planner vs specific controls)
# (agility support to replan less vs stability support to see patterns and be informed of right statuses)
# (time use over time with plans vs outcomes and level visibility in time)

# ~shrunk version? - last thing to have

# root page using waves background, it is the point of it anyway

# ~blue hue possibly for exports sake (should check them first)
# (no idea if current pdf size favors exporting at all omg)

# [x] week planning views
# [x] pngs make it slow to turn pages (regardless of alpha, image size matters but quality goes down visibly fast for no value)
# [-] svgs? - nope
# [-] A5 that I use is fine | line thickness can be lower than what I'm used to use, any value?
# [-] images economize space a bit but make for slow click ux if big otherwise have shitty image quality

# for analysis/impression sequence of detail pages is day by day, but if analysis would be done in exported/processed data then 

# experimental (not-totally-intuitive) but has potential
# Big Salad - naming
# Advanced (habit?) tracker
# Lenses Calendar
# mirror is somewhat implied
# (not having BS in name is better here)
# those diamons like light sources and popups are like what is went through prism

# ? actually "popup" - kind of optional, adding that prism design reference though (should the popup get another grid inside of it? too assuming, just design decision)
# aren't those design decision are stimulating in own way - then having them is not like an arbitrary whim

this_name = File.basename(__FILE__).sub /\..*/, ''

frame = -> w, h { Grid.new.apply(w,h).rect 1, 0, -2, -2 }

def configure_calendar days:, month_start:, week:
  month_start_weekday = week.index(month_start) or raise 'wrong :month_start given for the :week'
  calendar = MonthCalendar.new days: days, month_start_weekday: month_start_weekday
end

BSE = BlankSlatePDF.new(this_name) do
  configure $setup
  configure({ grid: Grid.new(x: 12, y: 18, name: :stars, frame: frame).apply(PAGE_WIDTH, PAGE_HEIGHT) })

  description <<-END
    # Lenses Calendar

    Monthly calendar to track habits or optionally longer data.
    Abstract, flexible, clear.

    A file per month:
    - root page with "table of contents" of any aspects (lenses) to track
    - nested status/overview page of month calendar per lense
    - nested details page per day
    - nested week page hidden below the last day of the week
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
    square.define_singleton_method :week do week end
    square.define_singleton_method :weekday do weekday end
    square
  }
  contour_points = Contour.sequence squares, step

  # better naming may be around
  # root page - has item names
  # item pages - monthly calendar
  # details pages - day details/notes
  # weekly pages - week likely planning page
  root_page = nil
  item_pages = []
  item_details_pages = []
  week_pages = []
  focused_week_pages = []
  pageset_pages = []

  item_cell_to_page = {}

  draw_month_contour = -> _=nil {
    color 8 do
      pdf_stroke_polygon *contour_points.map { |x| [x.x, x.y] }
    end
  }

  draw_square = -> square {
    pdf_stroke_polygon *square.points.map { |x| [x.x, x.y] }
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

  draw_days_squares = -> _=nil {
    color 8 do
      squares.each { |square|
        draw_square[square]
      }
    end
  }

  draw_grid = -> _=nil {
    name = _.nil? ? set_grid_name : @context.set_grid_name
    public_send name
  }

  draw_week = -> _ {
    day_squares = squares.select { |x| x.week == data[:week] }
    color 8 do
      dy = 3
      rects = []
      5.times { |weekday|
        dx = 12
        pos = [0, 18-dy*weekday]
        (x, y) = grid.at pos[0], pos[1], corner: 0
        w = grid.by_x.at(dx) - grid.by_x.at(0)
        h = grid.by_y.at dy
        rects << { at: [x, y], width: w, height: h, pos: pos, dx: dx, dy: dy }
      }
      2.times { |i|
        dx = 6
        row = 5
        pos = [dx*i, 18-dy*(row)]
        (x, y) = grid.at pos[0], pos[1], corner: 0
        w = grid.by_x.at(dx) - grid.by_x.at(0)
        h = grid.by_y.at dy
        rects << { at: [x, y], width: w, height: h, pos: pos, dx: dx, dy: dy }
      }
      day_squares.each { |square|
        day = square.day
        weekday = square.weekday

        (at, w, h, pos, dx, dy) = rects[weekday].fetch_values :at, :width, :height, :pos, :dx, :dy
        pdf_stroke_rectangle at, w, h

        font $roboto do  # in this file can be deduplicated (the block)
          font_size step * 0.25 do
            text = day.to_s
            pad_x = step * 0.05
            pad_y = step * 0.025
            pdf.text_box text, at: at, width: w-pad_x, height: h-pad_y, align: :right, valign: :bottom
          end
        end

        cell = pos.dup
        cell[0] += dx - 1 # right side
        cell[1] -= dy # ... some abstractions opportunity
        that_page = item_details_pages.find { |x| x.data[:item_cell] == data[:item_cell] && x.data[:day] == day }
        link! cell, that_page
      }
    end
  }

  week_to_cell = -> week {
    square = squares.reverse.find { |x| x.week == week }
    pos = square.pos
    week_cell = [*pos]
    week_cell[1] -= 1
    week_cell
  }

  # text line, print?
  draw_line = -> cell, text, **props {
    # Definetly squares abstraction need a look for more using it
    text_at = grid.at cell[0], cell[1]+1, corner: 0 # text needs that shift up the cell
    size = grid.by_x.step
    color 8 do
      font $roboto_light do
        font_size size * 0.8 do
          pad_x = 0
          pad_y = size * 0.1
          dy = size * -0.2
          text_at[1] += dy
          width = size * 12
          pdf.text_box text, at: text_at, width: width-pad_x, height: size-pad_y, align: :left, valign: :bottom, **props
        end
      end
    end
  }

  config_per_cell = {}
  item_cells = []
  to_the_right = []
  18.times { |i|
    cell = [-1.0, 18 - 1 - i] # at the left of the grid
    item_cells << cell

    config = ($personalize ? $personalize['left'][i] : {}) || {}
    config['left'] = true
    config_per_cell[cell] = config
  }
  #12.times { |i|
  #  item_cells << [i, 18] # above the grid
  #}
  3.times { |i|
    cell = [12, 18 - 1 - i] # at the right of the grid
    item_cells << cell
    to_the_right << cell
    # pages are often turned + RM seem to have improved accidental hand recognition so no point in avoiding
    # at least to test how it goes
    # could cover RTL or left hand if it works-out well

    config = ($personalize ? $personalize['right'][i] : {}) || {}
    config['right'] = true
    config_per_cell[cell] = config
  }

  #item_cells = item_cells.take 1 # XXX

  # main pages
  page do
    current_page.data = { root: true }
    root_page = current_page

    instance_eval &draw_month_contour
    instance_eval &draw_grid

    item_cells.each { |item_cell|
      page do
        item_pages << current_page
        current_page.data = { item_cell: item_cell } # ? unify map vs data vs context-addup (oop-ish)
        item_cell_to_page[item_cell] = current_page

        instance_eval &draw_days_squares
        instance_eval &draw_grid
        double_back_arrow

        diamond item_cell, corner: 0.5
      end
    }
  end

  # Mixing page ordering and ui rendering, separation could make sense

  # menu on main/overview pages
  ([root_page] + item_pages).each { |page|
    revisit_page page do
      item_cells.each { |item_cell|
        that_page = item_cell_to_page[item_cell]
        link! item_cell, that_page
      }
    end
  }

  # generating detials pages per days and item pages
  day_count = @config[:day_count]
  item_pages.each { |item_page|
    with_parent item_page do
      day_count.times { |i|
        day = i + 1
        square = squares.find { |x| x.day == day }

        page do
          item_details_pages << current_page
          current_page.data = item_page.data.merge(day: day)

          draw_month_contour.call # no point in eval?

          color(8) { draw_square[square] }
          draw_grid.call
          double_back_arrow

          diamond item_page.data[:item_cell], corner: 0.5
        end
      }
    end
  }

  # details page has menu
  item_details_pages.each { |page|
    revisit_page page do
      item_cells.each { |item_cell|
        that_page = item_details_pages.find { |x| x.data[:item_cell] == item_cell && x.data[:day] == page.data[:day] }
        link! item_cell, that_page
      }
    end
  }

  # linking day details pages from parents
  item_pages.each { |page|
    revisit_page page do
      item_cell = page.data[:item_cell]

      day_count.times { |i|
        day = i + 1
        square = squares.find { |x| x.day == day }
        pos = square.pos
        day_cell = pos
        day_cell = [*pos, *pos.map { |x| x + 1 }]

        that_page = item_details_pages.find { |x| x.data[:item_cell] == item_cell && x.data[:day] == day }
        link! day_cell, that_page
      }
    end
  }

  # generating week view pages
  week_count = squares.last.week + 1 # from 0
  item_pages.each { |item_page|
    with_parent item_page do
      week_count.times { |week|
        bottom_square = squares.reverse.find { |x| x.week == week }

        page do
          week_pages << current_page
          current_page.data = item_page.data.merge(week: week)

          instance_eval &draw_week
          draw_grid.call
          double_back_arrow

          diamond item_page.data[:item_cell], corner: 0.5
        end
      }
    end
  }

  # also but separately grouped
  # generating focused week on month view pages
  week_count = squares.last.week + 1 # from 0
  item_pages.each { |item_page|
    with_parent item_page do
      week_count.times { |week|
        bottom_square = squares.reverse.find { |x| x.week == week }

        # dsl thing vs MyPage.add :tag do, dsl flateness seem nice though (explicitness and simplicity of insides therefore)
        page do
          focused_week_pages << current_page
          current_page.data = item_page.data.merge(week: week, focus: true)

          instance_eval &draw_days_squares

          at = week_to_cell.call current_page.data[:week]
          at = [*at]
          at[0] += 0.5 # centered between two smaller cells

          # Definetly squares abstraction need a look for more using it
          text_at = grid.at at[0], at[1]+1, corner: 0 # text needs that shift up the cell
          size = grid.by_x.step
          color 8 do
            font $roboto do
              font_size size * 0.9 do
                text = ?^
                pad_x = 0
                pad_y = 0
                dy = size * -0.2
                text_at[1] += dy
                pdf.text_box text, at: text_at, width: size-pad_x, height: size-pad_y, align: :center, valign: :bottom
              end
            end
          end
          draw_grid.call
          double_back_arrow

          diamond item_page.data[:item_cell], corner: 0.5
        end
      }
    end
  }

  # linking week pages from parents
  week_pages.each { |page|
    revisit_page page.parent do
      week_cell = week_to_cell.call page.data[:week]
      #link! [*week_cell, week_cell[0]+1, week_cell[1]], page
      link! week_cell, page
    end
  }

  # linking focused week pages from parents
  focused_week_pages.each { |page|
    linked_pages = [page.parent] + focused_week_pages.select { |x| x.id != page.id && x[:item_cell] == page[:item_cell] }
    linked_pages.each { |linked_page|
      revisit_page linked_page do
        week_cell = week_to_cell.call page.data[:week]
        week_cell[0] += 1
        link! week_cell, page
      end
    }
  }
  # ++ do render items links, week links, day square links

  # menu on week pages
  week_pages.each { |page|
    revisit_page page do
      item_cells.each { |item_cell|
        that_page = week_pages.find { |x| x.data[:item_cell] == item_cell && x.data[:week] == page.data[:week] }
        link! item_cell, that_page
      }
    end
  }

  # day pages also link to week pages
  item_details_pages.each { |page|
    revisit_page page do
      square = squares.find { |x| x.day == page.data[:day] }

      cell = square.pos.dup
      cell[1] -= 1
      that_page = week_pages.find { |x| x.data[:item_cell] == page.data[:item_cell] && x.data[:week] == square.week }
      link! [*cell, cell[0]+1, cell[1]], that_page
    end
  }

  ### page-sets feature

  page_set_layout = -> set_cell {
    #at = week_to_cell.call current_page.data[:week]
    at = set_cell.dup

    text_at = grid.at at[0], at[1]+1, corner: 0 # text needs that shift up the cell
    size = grid.by_x.step
    color 8 do
      font $roboto do
        font_size size * 0.9 do
          text = ?*
          pad_x = 0
          pad_y = 0
          dy = size * -0.2
          text_at[1] += dy
          pdf.text_box text, at: text_at, width: size-pad_x, height: size-pad_y, align: :center, valign: :bottom
        end
      end
    end
  }

  # generating
  ([root_page] + item_pages + item_details_pages + week_pages).each { |parent|
    next unless parent.data[:root] || to_the_right.include?(parent[:item_cell])

    with_parent parent do
      3.times { |set_index|
        set_cell = [12-1 - 2 + set_index, 18]

        9.times { |page_index|
          page_cell = [page_index, 18]

          page do
            pageset_pages << current_page
            current_page.data = parent.data.merge(set_cell: set_cell, page_cell: page_cell, page_index: page_index)

            marker = current_page[:page_cell].dup
            marker[1] -= 0.5 # between grid top row dots, not interactive and header may be above
            mark2 marker, corner: 0.5

            page_set_layout.call set_cell
            double_back_arrow

            draw_dots only: [{ y: 18 }]
            draw_crosses
            # ++ new grid instead

            # between subsets menu
            # (nothing else should be there since it is a separate and distanced/non-integrated into cross-navigation feature)
            # vs just having same navigation as the parent page that just looses subset context?
          end
        }
      }
    end
  }

  # linking
  pageset_pages.select { |x| x[:page_index] == 0 }.each { |page|
    revisit_page page.parent do
      link! page[:set_cell], page
    end
  }

  ### feature: headers if given

  # at root for item links
  revisit_page root_page do
    item_cells.each { |item_cell|
      config = config_per_cell[item_cell]
      header = config['header']
      text_cell = item_cell.dup
      text_cell[0] = 0
      if config['left']
        #text_cell[0] += 1
        #text_cell[0] = 0
        draw_line.call text_cell, header if header
      end
      if config['right']
        #text_cell[0] = 0
        draw_line.call text_cell, header, align: :right if header
      end
    }
  end

  # at any page as header
  (item_pages + item_details_pages + week_pages + focused_week_pages + pageset_pages).each { |page|
    next unless page.data[:item_cell]
    item_cell = page[:item_cell]
    config = config_per_cell[item_cell]
    header = config['header']
    revisit_page page do
      draw_line.call [0, 18], header if header
    end
  }

  render_file
end

have_grid_versions = -> given_bs {
  result = []

  bs = given_bs.dup
  bs.name = "SAND_#{bs.name}"
  bs.configure({set_grid_name: :draw_sand}, deep: false)
  result << bs

  bs = given_bs.dup
  bs.name = "STARS_#{bs.name}"
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

result = [BSE.dup]

have_month_versions = -> *months {
  -> given_bs {
    months.map { |date|
      day_count = date.next_month.prev_day.day
      week = WEEK_MON; wday = date.wday == 0 ? 7 : date.wday - 1; start_weekday = week[wday]

      bs = given_bs.dup
      bs.name = "#{bs.name}_#{date.strftime '%B' }_#{date.year}"
      bs.configure({ day_count: day_count }, deep: false)
      bs.configure({ start_weekday: start_weekday }, deep: false)
      bs.configure({ week: week }, deep: false)
      #bs.configure({ set_grid_name: :draw_stars}, deep: false)
      bs.configure({ set_grid_name: :draw_dots}, deep: false)
      # + additional note into metadata on date?
      bs
    }
  }
}

# first day of the needed month dates
result = result.flat_map(&have_month_versions[
  Date.new(2024, 1, 1),
  #Date.new(2024, 2, 1),
  #Date.new(2024, 3, 1),
])

#result = result.flat_map(&have_grid_versions)
#result = result.flat_map(&have_week_variations)
#result = result.flat_map(&have_start_day_variations)
#result = result.flat_map(&have_day_count_variations)

$configs_loaded = result
