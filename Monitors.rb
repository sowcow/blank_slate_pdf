require 'date'
require_relative 'bs/all'
END { Monitors.make name: 'Monitors' } if __FILE__ == $0

module Monitors
  YEAR = 2024

  def self.make name:
#####

path = File.join __dir__, 'output'

BS.setup name: name, path: path, description: <<END
  Monitors.pdf

  PDF to monitor weather, habits or whatever else.
  One page has a table of four columns for every day of month.
  PDF has 12 pages of that for every month of the year.
  Because of the volume it is meant for mostly less essential experimental columns/variables to record and see.
  Contrasting to that Days.pdf has only a single such page per month.
  Anyway the volume could open interesting uses like a habit per page plus three columns for some related controls/variables.

  Horizontal lines are week divisions (Monday-starting weeks).

  Author: Alexander K.
  Project: https://github.com/sowcow/blank_slate_pdf
END
BS.grid 16

last_page_marks = -> {
  a = $bs
  if a.page[:page_index] == a.page[:page_count] - 1
    g = a.g
    x = a.g.xs.at a.g.w
    y0 = a.g.ys.at 0
    y1 = a.g.ys.at g.h
    a.color 8 do
    a.line_width 5 do
      a.pdf.stroke_line x, y0, x, y1
    end
    end
  end
}

months_grid = BS::CellsGrid.new x: 0, y: 0, w: 3, h: 4, scale: 4

BS.page :root do
  page.tag = 'Monitors.pdf'
  line_width 0.5 do
    color ?a do
      months_grid.draw_grid
    end
  end
end

root = BS.pages.first
root.visit do
  months_grid.cells.each_with_index { |pos, i|
    d = Date.new YEAR, i+1, 1
    month = BS::Month[:"m_#{i}"].setup year: d.year, month: d.month, parent: nil, dy: -3

    child = root.child_page :month, month: d do
      BS::Pagination.generate page do
        link_back

        BS::Habits.generate2 nil, month, here: page do
          color ?8 do
          text_at Pos[1, 15], d.strftime('%Y %B monitors')
          end
        end
        last_page_marks.call
      end
    end

    link_pos = if pos[1] == 12
      pos.expand(3, 2) # I don't like having links near the top of the page, the link may get black on exit
    else
      pos.expand(3, 3)
    end
    link link_pos, child

    text = d.strftime('%B')
    text = YEAR.to_s if i == 0
    color ?8 do
    text_at pos.right(3), text, align: :right
    end
  }
end

BS::Info.generate

BS.generate # PDF file

  end
end
