require_relative 'bs/all'
#END { Projects.make name: 'Projects', grid: ?g } if __FILE__ == $0

module Projects
def self.make name:, grid:
###

path = File.join __dir__, 'output'

BS.setup name: name, path: path, description: <<END
  Project.pdf

  There is a grid of entries, every one having 12 consecutive pages inside.
  So it can be seen as a folder of fixed-size files with the difference that you don't use file-system UI, write names by hand, and have trace of dones accumulated while in file system-way they are moved to archives.

  Usage:
  - write a project name into any cell
  - enter it, use any number of pages
  - use back button at the top to return to the grid

  Author: Alexander K.
  Project: https://github.com/sowcow/blank_slate_pdf
END
=begin
  The single experimental feature in the PDF is that inside the project there is also the header that has on sides four invisible links to all projects in the same row as the one that was entered.
  This leaves the possibility of the whole row being used as one project consisting of four parts and navigation without leaving it.
  One side effect of that is also ability to jump from any page to the first page of the project by using the corresponding link.
=end

BS.grid 16

bg = BS::Bg.new grid

BS.page :root do
  page.tag = 'Projects.pdf'
end

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

rects = []
12.times { |ay|
  4.times { |ax|
    rects << Pos[ax * 3, 14 - ay]
  }
}

root = BS.pages.first
root.visit do
  rects.each { |pos|
    coords = []
    coords << pos
    coords << pos.right(3)
    coords << pos.right(3).up(1)
    coords << pos.up(1)

    color ?a do
      line_width 0.5 do
        poly coords.map { |x| g.at x }
      end
    end
  }
end

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

root.visit do
  rects.each { |pos|
    this_bg = bg.take
    child = page.child_page :project, pos: pos do
      BS::Pagination.generate page do
        link_back
        draw_grid.call this_bg
        last_page_marks.call
      end
    end
    root.visit do
      pos = [*pos, *pos]
      pos[2] += 2
      link pos, child
    end
  }
end

=begin
BS.pages.each { |pg|
  next unless pg[:pos]
  row = BS.pages.select { |x| x[:pos] }
    .select { |x| x[:pos].y == pg[:pos].y && x[:page_index] == 0 }.sort_by { |x| x[:pos].x }

  pg.visit do
    link Pos[1, 15], row[0] unless row[0] == pg
    link Pos[2, 15], row[1] unless row[1] == pg
    link Pos[9, 15], row[2] unless row[2] == pg
    link Pos[10, 15], row[3] unless row[3] == pg
  end
  #pg.visit do
  #  link Pos[1, 15].expand(1), row[0] unless row[0] == pg
  #  link Pos[1+2, 15].expand(2), row[1] unless row[1] == pg
  #  link Pos[1+2+3, 15].expand(2), row[2] unless row[2] == pg
  #  link Pos[1+2+3+3, 15].expand(1), row[3] unless row[3] == pg
  #end
}
=end

BS::Info.generate

BS.generate
end
end
