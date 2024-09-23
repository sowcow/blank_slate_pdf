require_relative 'bs/all'
END {
  Lists.make name: 'Lists', grid: ?B, title: nil, format: nil
} if __FILE__ == $0

# write that general use is to move to next page form front-page TOC
# write that can render titles per project (position assumes hidden round RM menu toggle that rm-hacks can remove)
# - write hidden home page button instead
# name ~ process/*lists*/project/items/todos/features/wip
# omg leave square on leaf pages to see inputs link square or render it with filled squares

module Lists
def self.make name:, grid: ?B, title: nil, format: 16
###

path = File.join __dir__, 'output'

$render_id = -> a, b, text {
  a = At[*a].up
  b = At[*b].up
  a = Pos[*$bs.g.at(a)]
  b = Pos[*$bs.g.at(b)]
  width = b.x - a.x
  font_size = width * 0.33
  width -= font_size * 0.15
  $bs.font $roboto_light do
    $bs.font_size font_size do
      $bs.color 8 do
        $bs.pdf.text_box text, at: a.to_a, width: width, height: b.y - a.y,
          align: :right, valign: :bottom
      end
    end
  end
}

reformat_page format
BS.setup name: name, path: path, description: <<END
  Lists.pdf

  This can be seen as advanced todo lists PDF.
  It supports a type of todo items that need further decomposition because every item has 12 pages inside.
  Also it supports catchall for relevant ideas/inputs that can be processed later.
  Adding titles and marking used links is a good idea to navigate within the PDF.

  First page (root) is a table of contents:
  - First row of links goes to 12 ideas/inputs pages.
  - Then two rows link to 12 lists pages, these links are bigger so there is space to give them name when needed.
  - Other links below link to items of lists in case that is needed at some point

  Lists:
  - Lists can be accessed just by turning to the next page from the root
  - Every list has 7 items, linked by squares at the left

  Items:
  - Items have 12 consecutive pages each
  - Also all pages have links to ideas/inputs pages (in the upper-right corner)

  Ideas:
  - linked from every page to be very accessible for addition
  - Overall 12 pages with navigation between them at the top or by turning pages

  Also title can be rendered on every page by setting `title: 'ABC'` in `Lists.rb`.
  It should be useful if separate PDF file is used per project.

  Author: Alexander K.
  Project: https://github.com/sowcow/blank_slate_pdf
END
BS.grid format

bg = BS::Bg.new grid

root = nil

render_title = -> {
  $bs.text_at $bs.g.tl, title, align: :left if title
  # $bs.link $bs.g.tl, root if root && $bs.page != root
}

BS.page :root do
  page.tag = 'Lists.pdf'
  render_title.call
end

root = BS.pages.first

last_page_marks = -> {
  next
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

input_link_bg = BS::LinesGrid.new  # input/idea
input_link_bg.ys 14, 15
input_link_bg.xs 11, 12

inputs_nav_bg = BS::LinesGrid.new
inputs_nav_bg.ys 14, 15
inputs_nav_bg.xs *(0..12).flat_map { |x| [x] }

root_bg = BS::Group.new
root_bg.push inputs_nav_bg
one = BS::LinesGrid.new
one.ys 12, 13
one.y_range 12, 14
one.xs 0, 2, 4, 6, 8, 10, 12
root_bg.push one
one = BS::LinesGrid.new
one.ys *11.times.map { |x| x + 1 }
one.y_range 0, 12
one.xs 0, 2, 4, 6, 8, 10, 11
one.x_range 0, 12
root_bg.push one


inputs_bg = BS::Group.new
one = BS::LinesGrid.new
one.ys *(0..14).flat_map { |x| [x, x-0.5] }
one.x_range 0, 12
inputs_bg.push one
one = BS::LinesGrid.new
one.ys 14, 15
one.xs *(0..12).flat_map { |x| [x] }
inputs_bg.push one

leaf_page_bg = BS::Group.new
one = BS::LinesGrid.new
one.xs *(0..12).flat_map { |x| [x, x+0.5] }
one.ys *(0..14).flat_map { |x| [x, x-0.5] }
leaf_page_bg.push one
one = BS::LinesGrid.new
one.xs *(0..10).flat_map { |x| [x, x+0.5] }
one.x_range 0, 11
one.ys *(14..15).flat_map { |x| [x, x-0.5] }
leaf_page_bg.push one

decomposition_page_bg = BS::Group.new
one = BS::LinesGrid.new
# one.xs 1
one.ys *8.times.map { |x| 15 - x*2 }
# one.ys *15.times.map { |x| 15 - x }
one.x_range 0, 12
one.y_range 0, 15
decomposition_page_bg.push one

7.times { |i|
  one = BS::LinesGrid.new
  delta = 0.5 #25
  multi = 2
  # delta = 0
  one.xs 0+delta, 1+delta
  one.ys 15 - i*multi-delta, 15 - i*multi - 1-delta
  # one.x_range 0, 12
  # one.y_range 0, 15
  decomposition_page_bg.push one

  # one = BS::LinesGrid.new
  # one.ys 15 - i*2 - 1
  # one.x_range 0, 2
  # decomposition_page_bg.push one
}

# root.visit do
#   projects.render_lines
#   projects_bg.render_dots { |at|
#     x = at.x
#     y = at.y
#     next false if projects.rects.find { |(at1, at2)|
#       x1 = at1.x
#       y1 = at1.y
#       x2 = at2.x
#       y2 = at2.y
#       (x1..x2) === x && (y1..y2) === y
#     }
#     true
#   }
# end

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


# root.visit do
root.child_page :list do
  this_bg = bg.take
  link_back
  BS::Pagination.generate page do
    render_title.call
    draw_grid.call this_bg
    last_page_marks.call

    i = page[:page_index]
    at = At[11, 0]
    $render_id.call at, at.up.right, "#{i + 1}"
  end
end
# root.visit do
#   projects.rects.each { |(pos, pos2)|
#     this_bg = bg.take
#     child = page.child_page :project, pos: pos do
#       BS::Pagination.generate page do
#         link_back
#         draw_grid.call this_bg
#         last_page_marks.call
#       end
#     end
#     root.visit do
#       link [*pos, *pos2.left.down], child
#     end
#   }
# end

# decomposition_page_bg.xs 0 # adding that line for rects to exist between available lines

# so I have both pagination and list, and limited number of projects as needed
# four projects to rotate file fast and to not have long-running stuff
# main space between projects for creative activity logging

# BS.xs(:project).each { |parent|
# BS.xs(:project)
# [root].each { |parent|

# BS.pages.take(12).each { |parent|
BS.xs(:list).each_with_index { |parent, i|
  pos = parent[:page_pos]
  decomposition_page_bg.rects.each_with_index { |rect, j|
    child = parent.child_page :item do
  BS::Pagination.generate page do
      render_title.call
      # leaf_page_bg.render_dots
      leaf_page_bg.render_lines
      link_back
      $bs.line_width 1 do
        diamond rect.first, corner: 0.5, use_color: [?f, ?a], fill: true
      end
      $bs.line_width 1 do
        mark2 pos.down(0.5), corner: 0.5
      end

      at = At[11, 0]
      $render_id.call at, at.up.right, "#{i + 1}.#{j + 1}"
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

root.visit do
  page.child_page :ideas do
    BS::Pagination.generate page do
      render_title.call
      link_back
      inputs_bg.render_lines

      i = page[:page_index]
      at = At[i, 14]
      $render_id.call at, at.up.right, "#{i + 1}i"
    end
  end
end

# input_pos = At[11, 14]
# input_rect = []
# input_rect.push input_pos
# input_rect.push input_pos.right
# input_rect.push input_pos.right.down
# input_rect.push input_pos.down

input = BS.xs(:ideas).last
link_pos = At[11, 14]
(BS.pages - BS.xs(:ideas) - [root]).each { |pg|
  pg.visit do
    link link_pos, input
    # color ?f, 8 do
    #   fill_poly *input_rect.map { |x| $bs.g.at x }
    #   # a.line_width 1 do
    #     # a.pdf.stroke_polygon x, y0, x, y1
    #   # end
    # end
    input_link_bg.render_lines
  end
}
root.visit do
  root_bg.render_lines
  inputs_nav_bg.rects.each_with_index { |(a, b), i|
    $render_id.call a, b, "#{i + 1}i"
  }
  12.times { |i|
    y = 13 - i / 6
    x = 2 * (i % 6) + 1
    at = At[x, y]
    $render_id.call at, at.up.right, "#{i + 1}"
  }
  12.times { |i|
    7.times { |j|
      y = 11 - i
      x = 2 * j + 1
      x = 10 if j == 5
      x = 11 if j == 6
      at = At[x, y]
      $render_id.call at, at.up.right, "#{i + 1}.#{j + 1}"
    }
  }
  BS.xs(:list).each_with_index do |pg, i|
    x = i % 6
    y = i / 6
    y = 15 - 2 - y

    rect = [x*2, y, x*2 + 1, y]
    link rect, pg
  end
  BS.xs(:item)
    .select { |x| x[:page_index] == 0 }
    .each_with_index do |pg, i|
    x = i % 7
    y = i / 7
    y = 15 - 4 - y

    rect = [x*2, y, x*2 + 1, y]
    case x
    when 5 then rect = [10, y, 10, y]
    when 6 then rect = [11, y, 11, y]
    end
    link rect, pg
  end
end
([root] + BS.xs(:ideas)).each { |pg|
  pg.visit do
    12.times { |i|
      link_pos = At[i, 14]
      input = BS.xs(:ideas)[i]
      link link_pos, input unless input == pg
    }
  end
}

# BS.xs(:list).visit do
#   jjj
# end
  # .each { |pg|
  # pg.visit do
  # end
# }

BS::Info.generate

BS.generate
end
end
