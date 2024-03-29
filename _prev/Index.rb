require_relative 'bs/all'
END { Index.make name: 'Index_12x12_DOT', grid: ?D, scale: 1 } if __FILE__ == $0

module Index
  def self.make name:, grid: ,scale: 1.5
#####

path = File.join __dir__, 'output'

BS.setup name: name, path: path, description: <<END
  Index.pdf

  There is a grid of square entries that are links to note pages.
  Having single page inside any entry so grouping is imposed from the
  grid page instead.
  More likely to be used for more random content that still can be grouped into topics.
  It is more organizable than plain index cards but less powerfull then physical/digital board of them.
  It can be seen as grid view where you make own preview or just mark page as used.
  It can be seen as less powerful verision of tagged pages but more experimental instead.

  Usage pattern:
  - mark any square as being used
  - enter it, use any number of pages for any content (marker above shows current column in the square)
  - use back button, mark used pages anyhow
  - divide the grid into parts and write topics to have this type grouping on creation of new notes

  Author: Alexander K.
  Project: https://github.com/sowcow/blank_slate_pdf
END
BS.grid 16

# kind of area
size = (12 / scale).to_i
square = BS::CellsGrid.new x: 0, y: 16-1-12, w: size, h: size, scale: scale

BS.page :root do
  page.tag = 'Index.pdf'
  line_width 0.5 do
    color ?a do
      square.draw_grid
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
  square.cells.each { |pos|
    child = root.child_page :card do
      link_back
      marker_pos = pos.dup
      marker_pos.y = g.h - 0.5
      mark2 marker_pos, corner: 0.5
      draw_grid.call bg.take
    end
    delta = scale - 1
    pos = pos.expand delta, delta
    link pos, child
  }
end

BS::Info.generate

BS.generate

#####
  end
end
