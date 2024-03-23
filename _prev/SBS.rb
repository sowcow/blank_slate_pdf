require_relative 'bs/all'
END { SBS.make name: 'SBS_STARS', grid: ?S } if __FILE__ == $0

# so simple that there is no need for colored version to understand it

module SBS
  def self.make name:, grid: 
#####

path = File.join __dir__, 'output'

BS.setup name: name, path: path, description: <<END
  SBS: Square BS.
  Most minimalistic PDF in the set.
  It has linked but still very flat set of pages for scratchpad or notes.
  Probably index-card inspired me somewhere on the way.

  On the main page PDF has a square with 144 links to note pages inside.
  When entered, note page has back link in the top corner and "pagination" marker at the top side of the grid that shows current column in the square.
  Turning pages moves right, then to the start of the next line.

  For usability used links need to be marked as such manually right inside the square on the main page.
  Different rows or sections can be given a topic by writing it inside the square too.

  Author: Alexander K.
  Project: https://github.com/sowcow/blank_slate_pdf
END
BS.grid 18

# kind of area
size = 12
square = BS::CellsGrid.new x: 12-size, y: 18-size, w: size, h: size

BS.page :root do
  page.tag = 'SBS.pdf'
  line_width 0.5 do
    color ?a do
      square.draw_grid
    end
  end
end

bg = BS::Bg.new grid

root = BS.pages.last
root.visit do
  square.cells.each { |pos|
    child = root.child_page :note do
      link_back
      marker_pos = pos.dup
      marker_pos.y = 18 - 0.5
      mark2 marker_pos, corner: 0.5
      draw_grid bg.take
    end
    link pos, child
  }
end

BS::Info.generate

BS.generate

#####
  end
end
