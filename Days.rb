require 'date'
require_relative 'bs/all'
END { Days.make name: 'Days_focus', grid: ?g, focus: true } if __FILE__ == $0

# - [ ] link back from habits back at the same invisible position
#       could be another use somewhere else

# Month names alignment may feel a bit chaotic but I use the principle of blank slate upper-left corner for writing

# I like big letters in the header though, << big grid

# clear date header with year too may have aspect of completeness/relevance/uniqueness of the page but not "yet another" one

module Days
  YEAR = 2024

  def self.make name:, grid: , focus: false
#####

path = File.join __dir__, 'output'

BS.setup name: name, path: path, description: <<END
  Days.pdf

  It is a year calendar (using Monday weeks) having only a single page for everything.
  Day pages only have a grid of choice with no dashboard or anything.
  Also there is a habits grid per month that can be used for word input or for checkmarks.

  Single page is a feature because it makes the calendar more single-purpose.
  So it is on the reviewability side of things.

  There are some hidden features:
  - hidden links below upper corners (second row) that lead from Month view to Habits page
  - hidden links below upper corners that lead from Day view to Week view
  - also less intuitive links from Month view to Week view are positioned right below every column of days

  Author: Alexander K.
  Project: https://github.com/sowcow/blank_slate_pdf
END
BS.grid 16

# area + subdivide actually?!
months_grid = BS::CellsGrid.new x: 0, y: 0, w: 3, h: 4, scale: 4

BS.page :root do
  page.tag = 'Days.pdf'
  line_width 0.5 do
    color ?a do
      months_grid.draw_grid
    end
  end
end

bg = BS::Bg.new grid
draw_grid = -> key {
  case key
  when ?D then $bs.draw_dots max_y: 15
  when ?S then $bs.draw_stars max_y: 15
  when ?L then $bs.draw_lines max_y: 15
  when ?G then $bs.draw_lines cross: true, max_y: 15
  when ?B then :noop
  when ?d then $bs.draw_dots_compact max_y: 15
  when ?l then $bs.draw_lines_compact max_y: 15
  when ?g then $bs.draw_lines_compact cross: true, max_y: 15
  else
    raise "Unexpected grid to draw: #{key}"
  end
}

root = BS.pages.first
root.visit do
  months_grid.cells.each_with_index { |pos, i|
    d = Date.new YEAR, i+1, 1

    child = root.child_page :month, month: d do
      link_back
      #draw_grid.call bg.take

      # since single pages per everything, nested rendering is fine (almost as early pdf's did it, also using early grid, nice looping)
      # but no actually, ordering of pages is different here
      color ?8 do
      text_at Pos[1, 15], d.strftime('%Y %B')
      end
    end
    link_pos = if pos[1] == 12
      pos.expand(3, 2) # I don't like having links near the top of the page, the link may get black on exit
    else
      pos.expand(3, 3)
    end
    link link_pos, child

    text = d.strftime('%B')
    text = '2024' if i == 0
    color ?8 do
    text_at pos.right(3), text, align: :right
    end
  }
end

number_mapping = {
}
num_i = 1
'Ⅰ	Ⅱ 	Ⅲ 	Ⅳ 	Ⅴ 	Ⅵ 	Ⅶ 	Ⅷ 	Ⅸ 	Ⅹ 	Ⅺ 	Ⅻ'.chars.each { |c|
  next if c =~ /\s/
  p [num_i, c]
  number_mapping[num_i.to_s] = c
  num_i += 1
}
have = -> x, y, text {
  text = number_mapping[text] || text

  x *= 0.5
  y *= 0.5

  at = Pos[x, y].up 0.5
  pos = $bs.g.at at

  size = $bs.g.xs.step*0.5

  $bs.omg_text_at pos, text, centering: 0.25, size: size, align: :center,
    font_is: $ao, size2: size * 0.6
}
have_numbers = -> {
  have.call 11+7, 11, '4'
  have.call 11+1, 11, '5'
  have.call 11, 11, '6'
  have.call 11-6, 11, '7'

  have.call 11+7, 24, '1'
  have.call 11+1, 24, '12'
  have.call 11, 24, '11'
  have.call 11-6, 24, '10'

  have.call 11-6, 11+6, '8'
  have.call 11-6, 11+7, '9'

  have.call 11+7, 11+7, '2'
  have.call 11+7, 11+6, '3'
}


focus_bg = BS::Group.new
w = 1 #0.5
c = 0

one = BS::LinesGrid.new
one.xs 0, 3
one.ys *5.times.map { |i| 15 - i * 3 }
one.width = w
one.color = c
focus_bg.push one

one = BS::LinesGrid.new
one.xs 12-0, 12-3
one.ys *5.times.map { |i| 15 - i * 3 }
one.width = w
one.color = c
focus_bg.push one

one = BS::LinesGrid.new
one.xs 6
one.x_range 3, 9
one.ys 12, 15
one.width = w
one.color = c
focus_bg.push one

one = BS::LinesGrid.new
one.xs 6
one.x_range 3, 9
one.ys 3, 6
one.width = w
one.color = c
focus_bg.push one

one = BS::LinesGrid.new
one.xs 6
one.x_range 6-0.5, 6+0.5
one.ys 9
one.y_range 9-0.5, 9+0.5
one.width = w
one.color = c
focus_bg.push one


months = {}

BS.xs(:month).each_with_index { |pg, i|
  d = pg[:month]
  month = BS::Month[:"m_#{i}"].setup year: d.year, month: d.month, parent: pg, dy: -3 # both header and 18 grid ~dependence
  months[i] = month
  month.generate do
    page.tag = :day
    draw_grid.call bg.take
    focus_bg.render_lines
    have_numbers.call

    if focus
    end

    omg = page[:"m_#{i}_square"]
    day_d = Date.new YEAR, d.month, omg.day

    color ?8 do
    #text_at Pos[1, 15], day_d.strftime("%a%e %B %Y")
    text_at Pos[1, 15], day_d.strftime("%Y %B %e %a")
    end
  end

  pg.visit do
    coords = []
    coords << Pos[0, 15]
    coords << Pos[12, 15]
    line_width 0.5 do
      color ?a do
        poly *coords.map { |x| g.at x } # stupid * thing, still needed there
        month.integrate
      end
    end
  end
}
#months.each { |x| x.integrate }
#month.breadcrumb BS.xs(:day_note)

BS.xs(:month).each_with_index { |pg, i|
  month = months[i]
  #d = pg[:month]
  # unreachable items, custom integration anyway
  BS::Items[:week].generate area: $bs.g.bl.down.select_right(month.week_squares.count), parent: pg do
    page.data.merge! month: month
    index = page[:week_index]
    square = month.squares.find { |x| x.week == index }
    d = Date.new YEAR, month.month, square.day

    color ?8 do
    text_at Pos[1, 15], d.strftime("%Y %B w%W")
    end
  end
}

# habits
BS.xs(:month).each_with_index { |pg, i|
  month = months[i]
  d = Date.new YEAR, month.month, 1
  #first_page = BS::Habits.generate pg, month do
  #  color ?8 do
  #  text_at Pos[1, 15], d.strftime('%Y %B habits')
  #  end
  #end
  first_page = BS::Habits.generate2 pg, month do
    color ?8 do
    text_at Pos[1, 15], d.strftime('%Y %B habits')
    end
  end
  pg.visit do
    at = g.tr.down.expand(0,0)
    link at, first_page
    link g.tl.down, first_page
    #coords = []
    #coords << Pos[at[0], at[1]]
    #coords << Pos[at[2]+1, at[1]]
    #coords << Pos[at[2]+1, at[3]+1]
    #coords << Pos[at[0], at[3]+1]
    #line_width 0.5 do
    #color ?a do
    #  poly *coords.map { |x| g.at x }
    #end
    #end
  end
}

BS::Info.generate

# integrating

BS.pages.xs(:week).each { |week_page|
  index = week_page[:week_index]
  pos = week_page[:month].week_squares[index]
  week_page.parent.visit do
    at = pos.expand 1, 0
    link at, week_page
    coords = []
    coords << Pos[at[0], at[1]]
    coords << Pos[at[2]+1, at[1]]
    coords << Pos[at[2]+1, at[3]+1]
    coords << Pos[at[0], at[3]+1]
    line_width 0.5 do
    color ?a do
      poly *coords.map { |x| g.at x }
    end
    end
  end
}

# linking days -> weeks
day_pages = BS.pages.select { |x| x[:type].to_s =~ /_day$/ }
day_pages.each { |day_page|
  omg_key = day_page[:type].to_s.sub /_day$/, ''
  square = day_page.data[:"#{omg_key}_square"]
  week_page = BS.pages.xs(:week).find { |x| x[:week_index] == square.week &&
                                        day_page[:month].month == x[:month].month
  }
  day_page.visit do
    link g.tr.down, week_page
    link g.tl.down, week_page
  end
}

# rendering week pages + linking
BS.pages.xs(:week).each { |week_page|
  month = week_page[:month]
  week_days = month.squares.select { |x| x.week == week_page[:week_index] }
  week_page.visit do
    size_x = g.w / 2
    size_y = g.h / 3.0
    had_saturday = false
    week_days.each { |day_square|
      i = day_square.weekday
      if i == 5
        had_saturday = true
      end
      is_saturday = i == 5
      is_sunday = i == 6
      # with this layout week has to start on Monday
      if i == 6
        i = 5 # same square position
      end
      x = i % 2
      y = i / 2
      x *= size_x
      y = g.h - y * size_y
      pos = Pos[x, y]
      (x, y) = g.at [x, y]
      #gsize = g.xs.step * size
      square = Square.sized(x, y, g.xs.step*size_x, -g.ys.step*size_y)

      unless is_sunday && had_saturday
        line_width 0.5 do
        color ?a do
          polygon *square.points.map(&:to_a)
        end
        end
      end

      color 8 do
        day = day_square.day.to_s
        pos.x -= 1 if is_saturday

        month_index = month.month - 1
        key = "m_#{month_index}"
        day_page = BS.pages.xs(:"#{key}_day").find { |x| x[:"#{key}_square"] == day_square }

        # omg just having it somehow...
        link_pos = pos.down(5.333).right(5)
        text_at = g.at pos.up(1 - 0.333)

        link link_pos, day_page

        # assumes day cell size, scaling of text is the same
        step = g.xs.at(2, corner: 1) - g.xs.at(1, corner: 0)
        big_step = g.xs.at(6, corner: 1) - g.xs.at(1, corner: 0)

        font $roboto_light do
          font_size step * 0.25 do
            text = day.to_s
            pad_x = step * 0.05
            pad_y = step * 0.025
            pdf.text_box text, at: text_at, width: big_step-pad_x, height: big_step-pad_y, align: :right, valign: :bottom
          end
        end
        # movable into month module +-, still abstractions around numbers update is of interest
      end
    }
  end
}

BS.generate # PDF file

  end
end
