require_relative 'bs/all'
END { Projects.make name: 'Projects', grid: ?B, rows: 3, timeline: true } if __FILE__ == $0

module Projects
def self.make name:, grid: ?B, timeline: false, rows: 3
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
      a.line_width 10 do
        a.pdf.stroke_line x, y0, x, y1
      end
    end
  end
}

projects = BS::Group.new

one = BS::LinesGrid.new
one.xs 0, 1
one.ys *2.times.map { |i| 15 - i }
projects.push one

one = BS::LinesGrid.new
one.xs 11, 12
one.ys *2.times.map { |i| 15 - i }
projects.push one

one = BS::LinesGrid.new
one.xs 0, 1
one.ys *2.times.map { |i| 15 - i - 11 }
projects.push one

one = BS::LinesGrid.new
one.xs 11, 12
one.ys *2.times.map { |i| 15 - i - 11 }
projects.push one

projects_bg = BS::Group.new
one = BS::LinesGrid.new
one.xs *13.times.flat_map { |x| [x, x -0.5] }
one.ys *13.times.flat_map { |i| [15 - i, 15-i-0.5] }.reject { |i| i < 3 }

projects_bg.push one

# margin = 3
# bgg = BS::LinesGrid.new
# bgg.xs *(0..12-margin)
# bgg.ys *(0..15)

# bgg2 = BS::LinesGrid.new
# bgg2.xs *(12-margin..12).flat_map { |x| [x, x+0.5] }
# bgg2.ys *(0..15).flat_map { |x| [x, x-0.5] }

leaf_page_bg = BS::LinesGrid.new
leaf_page_bg.xs *(0..12).flat_map { |x| [x, x+0.5] }
leaf_page_bg.ys *(0..15).flat_map { |x| [x, x-0.5] }

decomposition_page_bg = BS::Group.new
one = BS::LinesGrid.new
one.xs 1
one.ys *15.times.map { |x| x + 1 }
one.x_range 0, 12
one.y_range 0, 15
decomposition_page_bg.push one

root = BS.pages.first
root.visit do
  projects.render_lines
  projects_bg.render_dots { |at|
    x = at.x
    y = at.y
    next false if projects.rects.find { |(at1, at2)|
      x1 = at1.x
      y1 = at1.y
      x2 = at2.x
      y2 = at2.y
      (x1..x2) === x && (y1..y2) === y
    }
    true
  }
end

draw_grid = -> key {
  # bgg.render_lines :hlines
  decomposition_page_bg.render_lines

  false and case key
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
  projects.rects.each { |(pos, pos2)|
    this_bg = bg.take
    child = page.child_page :project, pos: pos do
      BS::Pagination.generate page do
        link_back
        draw_grid.call this_bg
        last_page_marks.call
      end
    end
    root.visit do
      link [*pos, *pos2.left.down], child
    end
  }
end

decomposition_page_bg.xs 0 # adding that line for rects to exist between available lines

# so I have both pagination and list, and limited number of projects as needed
# four projects to rotate file fast and to not have long-running stuff
# main space between projects for creative activity logging

BS.xs(:project).each { |parent|
  pos = parent[:page_pos]
  decomposition_page_bg.rects.reverse_each { |rect|
    child = parent.child_page :leaf do
      # leaf_page_bg.render_dots
      leaf_page_bg.render_lines
      link_back
      $bs.line_width 1 do
        diamond rect.first, corner: 0.5, use_color: [?f, ?a], fill: true
      end
      $bs.line_width 1 do
        mark2 pos.down(0.5), corner: 0.5
      end
    end
    parent.visit do
      link rect.first, child
    end
  }
}

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
