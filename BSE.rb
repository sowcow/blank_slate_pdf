require_relative 'bs/all'
BS.will_generate if __FILE__ == $0

# +render day/week square in corner notes there too

# - no corner notes needed with subitems everywhere?

# - do I stick corner-notes on week change?
# - double-run day pagination?
# - contour is noisy so no point now in it (file with algorithm I'll keep)

year = 2024
month = 1

path = File.join __dir__, 'output'
BS.setup name: 'BSE', path: path, description: <<END
  TODO: update
  ...
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
  TODO: update
  ...
  UI patterns:
  - RM user should have toolbar closed
  - file-scoped notes are above the grid
  - items can be found outside the grid at sides
  - item-scoped corner notes are in the upper-right corner of the grid
  - pagination is not UI-interactive, only page turning is meant
END

draw_grid = -> { $bs.draw_dots } # want to postpone with smart dots avoiding lines collision noise

BS.page :root do
  draw_grid.call
end

month = BS::Month.new.setup year: year, month: month, parent: BS.page(:root)

# habits special page, 2x density
BS.pages.last.child_page :habits do
  days_count = month.squares.count

  limit_y = g.ys.at(days_count) / 2.0

  # bar
  h = limit_y
  w = g.xs.step / 2.0

  (12).times { |ax|
    axx = ax + 0.5
    x = g.xs.at ax
    xx = g.xs.at axx
    y0 = g.ys.at 0
    y1 = g.ys.at g.h

    if ax.even?
      c = (ax / 12.0 * 255).to_i.to_s(16).rjust(2, ?0) * 3
      color c do
        pdf.fill_rectangle [xx, h], w, h
      end
    end
    color 8 do
      pdf.line x, y0, x, y1
      pdf.line xx, y0, xx, limit_y
      pdf.stroke
    end
  }
  month.squares.reverse.each_with_index { |square, ay|
    ay += 1
    ay = ay / 2.0
    y = g.ys.at ay
    xs = []
    12.times { |i|
      xs << [i, i + 0.5]
    }
    xs.each { |(from, to)|
      x0 = g.xs.at from
      x1 = g.xs.at to
      color 8 do
        pdf.line x0, y, x1, y
        pdf.stroke
      end
    }

    if square.weekday == 0 # Monday
      x0 = g.xs.at 0
      x1 = g.xs.at g.w
      line_width 1.5 do
        color 8 do
          pdf.line x0, y, x1, y
          pdf.stroke
        end
      end
    end
  }
end

item_count = 18 - 6 # more space for fingers, squareness++

item_generation = -> key { proc do
  BS::Pagination.generate page do
    draw_grid.call
  end
  BS::Items[key].generate grid_left: item_count, parent: page do
    draw_grid.call
    if page[:"#{key}_index"] == item_count - 1
      x = g.xs.at 12
      y0 = g.ys.at 0
      y1 = g.ys.at g.h
      color 8 do
        pdf.line x, y0, x, y1
      end
    end
  end
end
}

BS::Items[:week].generate area: $bs.g.bl.down.select_right(month.week_squares.count) do
  # unreachable items, custom integration anyway
  draw_grid.call
end

# wtf pages reoredering?
month.generate do
  page.tag = :day_overview
  draw_grid.call
end

#BS::CornerNotes.generate BS.pages.xs(:month_day) do
#  draw_grid.call
#end
#BS::CornerNotes.generate BS.pages.xs(:week) do
#  draw_grid.call
#end


# no subitems per day?
# no subitems per week?

# no idea if I'll have it after the habits part
# +-have one exceptional not linked item (:hidden/hide data flag) if space/performance allows
BS::Items.generate left: 4, space_y: 1, &item_generation[:subitem]
BS::Items.generate top: 4, space_x: 1, &item_generation[:subitem]
BS::Items.generate right: 1, space_y: 1, &item_generation[:subitem]

have_corner_items = -> parent, key {
  BS::Items[key].generate area: [$bs.g.tr], parent: parent do
    BS::Pagination.generate page do
      draw_grid.call
    end
  end
}

BS.pages.xs(:month_day).each { |parent| # naming it page => obscure behavior (overrides method name)
  have_corner_items.call parent, :day_note
  #BS::Items[:day_note].generate area: [$bs.g.tr], parent: parent do
  #  BS::Pagination.generate page do
  #    draw_grid.call
  #  end
  #end
    #, &item_generation[:day_subitem]
 # do
 #   BS::Pagination.generate page do
 #     draw_grid.call
 #   end
 # end
  #BS::Items.generate right: 1, space_y: 1, &item_generation[:day_subitem], parent: page
}
BS.pages.xs(:week).each { |parent|
  have_corner_items.call parent, :week_note
}




BS::Items[:day_note].integrate (BS.xs(:month_day)+BS.xs(:day_note)).to_sa, stick: [:month_square]
BS::Items[:week_note].integrate (BS.xs(:week)+BS.xs(:week_note)).to_sa, stick: [:week_index]

#p BS.pages.last.data #xs(:day_subitem).count
#exit 0
#BS::Items[:day_note].integrate BS.pages.xs(:day_subitem)
#BS::Items[:day_subitem].integrate (BS.pages.xs(:day_note) + BS.pages.xs(:day_subitem)).to_sa
BS::Items.integrate BS.pages.reject { |x| x[:type] == :habits }.to_sa
xs = BS.pages.select { |x| %i[ item subitem ].include? x[:type] }
BS::Items[:subitem].integrate xs.to_sa, stick: [
  :item_pos
]
#xs = BS.pages.select { |x| %i[ day_note day_subitem ].include? x[:type] }
##BS::Items[:day_subitem].integrate xs.to_sa, stick: [
#  :month_square # means day
#]
month.integrate
month.breadcrumb BS.xs(:day_note)
# custom integration of weeks
BS.pages.xs(:week).each { |week_page|
  index = week_page[:week_index]
  pos = month.week_squares[index]
  week_page.parent.visit do
    link pos.expand(1, 0), week_page
  end
}
(BS.xs(:month_day) + BS.xs(:day_note)).each { |day_page|
  square = day_page[:month_square] # day square it is
  week_page = BS.pages.xs(:week).find { |x| x[:week_index] == square.week }
  day_page.visit do
    link square.pos.down.expand(1, 0), week_page
  end
}
# rendering week pages + linking
BS.pages.xs(:week).each { |week_page|
  week_days = month.squares.select { |x| x.week == week_page[:week_index] }
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

__END__

BS::CornerNotes.generate BS.pages.xs(:item) do
  page.tag = :week_note
  instance_eval &draw_grid
end

###BS::Items.integrate stick: [ :subitem_pos ]
###BS::Items[:subitem].integrate stick: [ :item_pos ]

# corner notes are accessible from sub-items too
BS.pages.xs(:subitem).each { |subitem|
  corner_note = BS.pages.xs(:corner_note).find { |x|
    x.parent == subitem.parent
  }
  subitem.visit do
    BS::CornerNotes.link corner_note
  end
}
