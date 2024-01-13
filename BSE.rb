require_relative 'bs/all'
BS.will_generate if __FILE__ == $0

# - do I stick corner-notes on week change?
# - double-run day pagination?
# - contour is noisy so no point now in it (file with algorithm I'll keep)

year = 2024
month = 1

path = File.join __dir__, 'output'
BS.setup name: 'BSE', path: path, description: <<END
  Blank Slate Exec PDF.
  Builds upon existing Blank Slate PDF patterns and adds time dimension explicitly.
  Root page - month view with an option to go into day details notes.
  Day details notes are paginated.
  Weeks pages are linked from squares right below days squares.
  Week pages are the main habits/whatever view with no further depth.
  There is 18 pages per week for that per week.
  In the project language weeks are items on the left and habits/whatever are subitems on the right.
  There are corner-notes per week.
  ---
  UI patterns:
  - RM user should have toolbar closed
  - file-scoped notes are above the grid
  - items can be found outside the grid at sides
  - item-scoped corner notes are in the upper-right corner of the grid
  - pagination is not UI-interactive, only page turning is meant
END
BS.grid 18

draw_grid = -> _ { draw_dots } # want to postpone with smart dots avoiding lines collision noise

BS.page :root do
  instance_eval &draw_grid
end

month = BS::Month.new.setup year: year, month: month, parent: BS.page(:root)

BS::Items.generate left: month.week_squares.count do
  page.tag = :week
  BS::Items[:subitem].generate parent: page, right: 18, include_parent: true do
    page.tag = :week_aspect if page.tag == :subitem
    instance_eval &draw_grid
  end
end

month.generate do
  BS::Pagination.generate page do
    page.tag = :day_note
    instance_eval &draw_grid
  end
end

BS::CornerNotes.generate BS.pages.xs(:item) do
  page.tag = :week_note
  instance_eval &draw_grid
end

BS::TopNotes.generate do
  instance_eval &draw_grid
end

BS::Items.integrate stick: [ :subitem_pos ]
BS::Items[:subitem].integrate stick: [ :item_pos ]
BS::TopNotes.integrate
month.integrate

# corner notes are accessible from sub-items too
BS.pages.xs(:subitem).each { |subitem|
  corner_note = BS.pages.xs(:corner_note).find { |x|
    x.parent == subitem.parent
  }
  subitem.visit do
    BS::CornerNotes.link corner_note
  end
}
# manually integrating since I used items manually
BS.pages.xs(:item).each { |week_page|
  index = week_page[:item_index]
  pos = month.week_squares[index]
  week_page.parent.visit do
    link pos.expand(1, 0), week_page
  end
}
BS.pages.xs(:month_day).each { |day_page|
  square = day_page[:month_square] # day square it is
  week_page = BS.pages.xs(:item).find { |x| x[:item_index] == square.week }
  day_page.visit do
    link square.pos.down.expand(1, 0), week_page
  end
}
# rendering week pages + linking
(BS.pages.xs(:item) + BS.pages.xs(:subitem)).each { |week_page|
  week_days = month.squares.select { |x| x.week == week_page[:item_index] }
  week_page.visit do
    size = g.w / 2
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
      x *= size
      y = 18 - y * size
      pos = Pos[x, y]
      (x, y) = g.at [x, y]
      gsize = g.xs.step * size
      square = Square.sized(x, y, gsize, -gsize)

      unless is_sunday && had_saturday
        color 8 do
          polygon *square.points.map(&:to_a)
        end
      end

      color 8 do
        day = day_square.day.to_s
        pos.x -= 1 if is_saturday
        text_at = grid.at pos.x, pos.y, corner: 0

        day_page = BS.pages.xs(:month_day).find { |x| x[:month_square] == day_square }
        link_pos = pos.down(6).right(5) # shift is here instead of at text...
        link link_pos, day_page

        # assumes day cell size, scaling of text is the same
        step = g.xs.at(2, corner: 1) - g.xs.at(1, corner: 0)
        big_step = g.xs.at(6, corner: 1) - g.xs.at(1, corner: 0)

        font $roboto do
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
