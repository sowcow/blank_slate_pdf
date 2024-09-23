# this file is written more python-like, less ruby-like (or is it my biased view on python)
#
# random facts:
# - on previous iteraiton center of day was having crosshair implying aim of the day area
#   I still like just having plain grid there as in later version
# - this PDF moust have been influenced by: Seven Inch Soul, lots of coffee and none cigarettes
# - not shading weekends is principal

$have_extra_pages = true # those plan-review pages in the corner

module Q
  DESCRIPTION = <<~END
    Q.pdf

    Flexible quarter calendar PDF with write-friendly minimalistic UI.

    Main pages: Quarter > Month > Week > Day > Hour

    Main experimental feature is having extra page per any calendar page - it can be used for plan/review for example.
    Since those extra/review pages have own parallel navigation between them, they can be seen as parallel second calendar with bigger single area for writing.
    Second experimental feature is the presence of own hour pages (covering 12 hours per day).

    Must know is the use of hidden links, there are two types:
    - moving up/back in main calendar is done by the wide link area in the upper-right corner (also exits extra page into corresponding calendar page)
    - entering extra page is done by the square link in the bottom-left corner (this corner toggles between extra and main page)

    Also on month overview page the last square/day of each column/week will open the week overview.

    Also there is best practice to mark used links before entering them.

    Also turning pages opens the next month/week/day/hour.
    From turning pages perspective start of the day is assumed at 7, and end at 6, so if you open 6 and turn to the next page, it gives 7 of the next day (header shows that).

    Day pages have predefined background with clock face for hours blocks and the central square can be used as:
    - Focus of the day
    - Eisenhower matrix in four parts
    - Sketch built over the day
    - Mix of these

    Flat habit grids are not part of the PDF but there is plenty of more hierarchical plan/review type of space.

    This info is also on the last page of the PDF.

    Author: Alexander K.
    Project: https://github.com/sowcow/blank_slate_pdf
  END

  FORMAT = 16  # 12x16 standard grid fitting RM screen fully
  LINK_BACK_AREA = There.at [9, 15, 3, 1]
end

BEGIN {
  require_relative 'bs/all'
}

END {
  $week_format = WeekFormat.new ?M
  Q.make year: 2024, quarter: 3  # 1..4
} if __FILE__ == $0

def month_to_days date
  (1..date.next_month.prev_day.day).map { |day|
    Date.new date.year, date.month, day
  }
end

# belongs to WeekFormat?
def month_to_weeks date
  month_to_days(date).group_by { |day|
    $week_format.week_number(day)
  }.map { |k,vs|
    vs.first
  }
end

# data to render PDF is generated separately
# data is going to be tree of Date objects at it's core
# not doing OOP seems like a nice clean way with it

def Q.day_data date
  {
    date: date,
    entry_type: :day,
  }
end

def Q.week_data date
  days = 7.times.map { |i| date + i }
    .select { |x| $week_format.week_number(x) == $week_format.week_number(date) }
    .select { |x| x.month == date.month }
  {
    date: date,
    days: days.map { |x| Q.day_data x },
    entry_type: :week,
  }
end

def Q.month_data date
  {
    date: date,
    weeks: month_to_weeks(date).map { |x| Q.week_data x },
    days: month_to_days(date).map { |x| Q.day_data x },
    entry_type: :month,
  }
end

def Q.calendar_data year:, quarter:
  months = 3.times.map { |i| Date.new(year, (quarter - 1) * 3 + 1 + i, 1) }
  {
    q: quarter,
    months: months.map { |x| Q.month_data x },
    entry_type: :quarter,
  }
end

# add UI areas to calendar data
def Q.add_areas data
  month_areas = [
    # still odd api with .expand since 14 is bottom corner...
    # while expansion happens in more understandable coordinates (top-left)
    # also there was another api with page corners from grid...
    There.at([0, 15]).expand(5, 7),
    There.at([6, 15]).expand(5, 7),
    There.at([6, 15-1-7]).expand(5, 7),
  ]
  data[:months].zip(month_areas).each { |month, area|
    month[:door] = area
  }

  week_days_areas = {}
  # .wday 0..6, sun~0
  wday_order = $week_format.ordering

  cell_size = 2
  data[:months].each { |month|
    month[:day_door] = day_areas = {} # days may be in weeks or months so putting day number => area mapping here and not as property
    month[:weeks].each_with_index { |week, week_index|
      last_area = nil
      week[:days].each { |day|
        next unless day[:date].month == month[:date].month
        date = day[:date]
        wday_index = wday_order.index(date.wday)
        area = There.at([week_index * cell_size, 14 - wday_index * cell_size, cell_size, cell_size])
        day_areas[date.day] = area
        last_area = area
      }
      def last_area.last_in_column  # oh, no!
        true
      end
      week[:door] = last_area or throw
    }
  }

  data
end

# PDF generation core
def Q.make! name:, year:, quarter:
  data = Q.add_areas Q.calendar_data year: year, quarter: quarter

  # root page generation
  #
  BS.page :root, data do
    page.tag = 'Q.pdf'
  end
  root = BS.pages.first

  root.visit do
    grid = SmartGrid.new([0, 12], [0, 16])
    grid.add_verticals 0.5
    grid.add_horizontals 0.5

    # month areas:
    data[:months].each { |x|
      grid.cut_hole x[:door].to_ranges_area
    }

    Q.draw_grid grid

    data[:months].each { |month|
      Q.text_bottom_right month[:date].strftime('%B'), month[:door]
    }
  end

  # month pages generation
  #
  parent = root
  data[:months].each { |d|
    child = parent.child_page :month, d do
      grid = SmartGrid.new([0, 12], [0, 16])
      grid.add_verticals 0.5
      grid.add_horizontals 0.5

      d[:day_door].each { |day, area|
        grid.cut_hole area.to_ranges_area
        Q.text_bottom_right day.to_s, area
      }

      Q.draw_grid grid

      Q.header d, year: year, quarter: quarter
      Q.link_back
    end

    parent.visit do
      link d[:door], child
    end
  }

  week_days_door = {}
  $week_format.ordering.each_with_index { |wday, i|
    last = i == 7-1
    i += 1 if last # keeping empty space there
    x = (i % 2) * 6
    y = 16 - (i / 2) * 4 - 4 # -4 for stupid coordinate system; need to abstract away ideally
    week_days_door[wday] = There.at([x, y, 6, 4])
  }

  # week pages generation
  #
  BS.xs(:month).visit {
    parent = page
    page[:weeks].each { |d|
      child = parent.child_page :week, d do
        Q.header d, year: year, quarter: quarter
        Q.link_back

        grid = SmartGrid.new([0, 12], [0, 16])
        grid.add_verticals 0.5
        grid.add_horizontals 0.5

        d[:days].each { |day|
          door = week_days_door[day[:date].wday]
          grid.cut_hole door.to_ranges_area
          Q.text_bottom_right day[:date].day, door
        }

        Q.draw_grid grid
      end

      parent.visit do
        link d[:door], child
      end
    }
  }

  # day pages generation
  # parent is week page
  # I've gotten to like week view on previous iteration, I also do good defaults way
  #
  BS.xs(:week).visit {
    parent = page
    page[:days].each { |d|
      child = parent.child_page :day, d do
        Q.header d, year: year, quarter: quarter
        Q.link_back

        grid = SmartGrid.new([0, 12], [0, 16])
        grid.add_verticals 0.5
        grid.add_horizontals 0.5

        ClockFace.positions.each { |x|
          grid.cut_hole x[:area].to_ranges_area
        }

        Q.draw_grid grid
        Q.ui_style do
          ClockFace.render_clock_face
        end
      end

      # link from week
      parent.visit do
        door = week_days_door[d[:date].wday]
        link door, child
      end

      month = BS.xs(:month).find { |x| x[:date].month == d[:date].month }
      door = month[:day_door][d[:date].day]
      skip = door.respond_to?(:last_in_column) && door.last_in_column
      skip or month.visit do
        link door, child
      end
    }
  }

  # hour pages generation
  #
  BS.xs(:day).visit {
    parent = page
    ClockFace.positions.each { |position|
      hour = position[:hour]
      area = position[:area]

      child = parent.child_page :hour, { hour: hour, entry_type: :hour } do
        text = ClockFace.numeration[hour]
        ::Q.text_center text, There.at([11, 15, 1, 1]), font: $ao
        if [6, 7].include? hour
          Q.header parent.data, year: year, quarter: quarter
        end
        grid = SmartGrid.new([0, 12], [0, 16])
        grid.add_verticals 0.5
        grid.add_horizontals 0.5
        Q.draw_grid grid
        Q.link_back
      end

      parent.visit do
        link area, child
      end
    }
  }

  return unless $have_extra_pages

  extra_door = There.at([0, 0, 1.5, 1.5])

  [
    BS.xs(:root),
    BS.xs(:month),
    BS.xs(:week),
    BS.xs(:day),
    BS.xs(:hour),
  ].reverse_each.with_index { |xs, i| # moving forward scope goes up, review thing
    xs.each { |parent|
      child = parent.child_page :extra, extra_for: parent.data do
        page.tag = "(extra-#{i})"
        Q.header parent.data, year: year, quarter: quarter
        Q.link_back
      end

      parent.visit do
        link extra_door, child
      end
    }
  }

  BS.xs(:extra).visit do
    Q.render_extra_page page
  end
end

module Q
  module_function

  # boilerplate

  def make name: 'Q', year:, quarter:
    format = FORMAT

    path = File.join __dir__, 'output'

    reformat_page format
    BS.setup name: name, path: path, description: DESCRIPTION
    BS.grid format

    make! name: name, year: year, quarter: quarter

    BS::Info.generate
    BS.generate
  end

  # rendering helpers

  def ui_style &block
    $bs.line_width 0.5 do
      # $bs.color '008080', &block
      $bs.color 8, &block
    end
  end

  def draw_grid grid
    grid = grid.dup

    # no value in page border lines:
    grid.drop_lines [0, nil]
    grid.drop_lines [12, nil]
    grid.drop_lines [nil, 0]
    grid.drop_lines [nil, 16]

    grid.each { |line|
      line = line.at $bs.grid
      ui_style do
        $bs.pdf.line [line.x, line.y], [line.x2, line.y2]
        $bs.pdf.stroke
      end
    }
  end

  # bottom-right is the default blank-slate alignment for most things except headers and some buttons
  def text_bottom_right text, at
    text = text.to_s + ' ' # unbreakable space - padding

    at = at.dup
    # omg text using top-left corner as zero for shit, while everything
    # else uses bottom as 0,0
    # should fucking handle that on grid level?
    at.y += at.h
    at = at.at($bs.grid)

    ui_style do
    $bs.font $roboto_light do
      $bs.pdf.text_box text,
        at: at, width: at.w, height: at.h,
        align: :right, valign: :bottom
      end
    end
  end

  def text_center text, at, font: $roboto_light
    if text.is_a?(Hash)
      font = text[:font] if text[:font]
      text = text[:text]
    end
    text = text.to_s

    at = at.dup

    # expand from that point
    at.x -= 5
    at.ww = at.w + 10

    # omg text using top-left corner as zero for shit, while everything
    # else uses bottom as 0,0
    # should fucking handle that on grid level?
    at.y += at.h
    at = at.at($bs.grid)

    ui_style do
    $bs.font font do
      $bs.pdf.text_box text,
        at: at, width: at.w, height: at.h,
        align: :center, valign: :center
      end
    end
  end

  def link_back
    $bs.link LINK_BACK_AREA, $bs.page.parent
  end

  def header d, year:, quarter:
    case d[:entry_type]
    when :month
      text_center d[:date].strftime('%B'), There.at([5.5, 15, 1, 1])
    when :week
      week_number = $week_format.week_number d[:date]
      text_center "w#{week_number}", There.at([5.5, 15, 1, 1])
    when :day
      text = d[:date].strftime '%a. %Y-%m-%d'
      text_center text, There.at([5.5, 15, 1, 1])
    when :hour
      text = ClockFace.numeration[d[:hour]]
      ::Q.text_center text, There.at([5.5, 15, 1, 1]), font: $ao
    when :quarter
      text_center "Q#{quarter}-#{year}", There.at([5.5, 15, 1, 1])
    else
      raise "header for? #{d}"
    end
  end

  def render_extra_page page
    data = page.data
    type = data[:extra_for][:entry_type]

    # toggle extra-main corner
    extra_door = There.at([0, 0, 1.5, 1.5])
    $bs.link extra_door, page.parent

    case type
    when :quarter
      up_link = nil
      links = BS.xs(:extra)
        .select { |x| x[:entry_type] == :month }
        .map { |page|
          {
            text: short_name(page),
            page: page
          }
        }

      do_render_extra_page up_link: up_link, links: links
    when :month
      up_link = BS.xs(:extra)
        .find { |x| x[:entry_type] == :quarter }

      links = BS.xs(:extra)
        .select { |x| x[:entry_type] == :week }
        .select { |x| data[:weeks].map { |y| y[:date] }.include? x[:date] }
        .map { |page|
          {
            text: short_name(page),
            page: page
          }
        }

      do_render_extra_page up_link: up_link, links: links
    when :week
      up_link = BS.xs(:extra)
        .select { |x| x[:entry_type] == :month }
        .find { |x| x[:weeks].map { |x| x[:date] }.include? data[:date] }

      links = BS.xs(:extra)
        .select { |x| x[:entry_type] == :day }
        .select { |x|
          week_page = x.parent.parent
          week_page[:date] == data[:date]
        }
        .map { |page|
          {
            text: short_name(page),
            page: page
          }
        }

      do_render_extra_page up_link: up_link, links: links
    when :day
      up_link = BS.xs(:extra)
        .select { |x| x[:entry_type] == :week }
        .find { |x| x[:days].map { |x| x[:date] }.include? data[:date] }

      links = BS.xs(:extra)
        .select { |x| x[:entry_type] == :hour }
        .select { |x|
          day_page = x.parent.parent
          day_page[:date] == data[:date]
        }
        .map { |page|
          {
            text: short_name(page),
            page: page
          }
        }

      do_render_extra_page up_link: up_link, links: links
    when :hour
      up_link = BS.xs(:extra)
        .select { |x| x[:entry_type] == :day }
        .find { |x|
          day_page1 = x.parent
          day_page2 = page.parent.parent
          day_page1 == day_page2
        }

      links = [] # no point in neighboring hours in this view, duplicating grids is loosing information drawn on top of them

      do_render_extra_page up_link: up_link, links: links
    else
      throw "what extra page type? #{data}"
    end
  end

  def do_render_extra_page up_link:, links:
    add_areas = -> links {
      if links.count == 12
        links.take(6).reverse_each.with_index { |x, i|
          x[:area] = There.at [11-i, 14]
        }
        links.drop(6).reverse_each.with_index { |x, i|
          x[:area] = There.at [11-i, 14 - 1]
        }
      else
        links.reverse_each.with_index { |x, i|
          x[:area] = There.at [11-i, 14]
        }
      end
    }
    add_areas.call links

    grid = SmartGrid.new([0, 12], [0, 16])
    grid.add_verticals 0.5
    grid.add_horizontals 0.5

    # header area since upper part is developed on those pages
    #
    header_area = LINK_BACK_AREA.dup
    header_area.x = 0
    header_area.ww = LINK_BACK_AREA.x - (up_link ? 1 : 0)

    grid.cut_hole LINK_BACK_AREA.to_ranges_area
    grid.cut_hole header_area.to_ranges_area
    links.each { |x|
      grid.cut_hole x[:area].to_ranges_area
      $bs.link x[:area], x[:page]
      ::Q.text_center x[:text], x[:area] #, font: $ao
    }

    if up_link
      up_btn_area = LINK_BACK_AREA.dup
      up_btn_area.x -= 1
      up_btn_area.ww = 1

      grid.cut_hole up_btn_area.to_ranges_area
      $bs.link up_btn_area, up_link
      ::Q.text_center ::Q.short_name(up_link), up_btn_area
    end
    ::Q.draw_grid grid
  end

  def short_name page
    case page[:entry_type]
    when :quarter
      "Q#{Q}"
    when :month
      page[:date].strftime('%b')
    when :week
      "w#{$week_format.week_number(page[:date])}"
    when :day
      page[:date].day.to_s
    when :hour
      { font: $ao, text: ClockFace.numeration[page[:hour]] }
    else
      throw "page for short name? #{page[:entry_type]}"
    end
  end
end
