BEGIN {
  require_relative 'bs/all'
}

END {
  Hex.make
} if __FILE__ == $0

$mark_color = 'ff8800'

module Hex
  module_function

  FORMAT = 16  # 12x16 standard grid fitting RM screen fully
  DESCRIPTION = <<~END
    Hex.pdf

    PDF to play around with hexagon-like background.
    
    The main page has a grid of 32 links to item pages.
    Every item page has 17 consecutive pages and wide link back in the top-right corner.

    The interesting part is backgounds used on main or item pages.
    I'm thinking about mind-map-like uses.

    Main disclaimer when using these abstract PDFs must do is to mark or name links on the main page before entering them and possibly also writing the same name into the item page header after entered the link.

    This info is also on the last page of the PDF.

    Author: Alexander K.
    Project: https://github.com/sowcow/blank_slate_pdf
  END

  # it feels good so I keep it this way (1/4 screen width)
  # not having an arrow seem fine by me, as abstract as it can get
  LINK_BACK_AREA = There.at [9, 15, 3, 1]
end


def Hex.make!
  # rounds pages are defined by "door"/link area on the main/root page
  rounds = []

  # hexagonal grid fundamentally
  row_count = 7
  index = 0
  row_count.times { |i|
    w = 2
    h = 2
    x = 1
    y = (15 - h) - i*h # '15 - h' since 15 is upper corner y-coordinate
    # while expected is 0,0 at bottom left
    x += 1 if i.odd?
    col_count = i.odd?? 4 : 5
    col_count.times { |j|
      rounds.push << { x: x + j*w, y: y, w: w, h: h }
      rounds.last[:index] = index
      index += 1
    }
  }

  up = self # :visit and such methods change into page context

  # root page generation
  BS.page :root do
    page.tag = 'Hex.pdf'
  end
  root = BS.pages.first

  # rounds pages generation
  parent = root
  rounds.each { |d|
    child = parent.child_page :item, d do
      BS::Pagination.generate page, count: 17, step: 0.5 do
        up.link_back
        up.draw_footer "#{d[:index] + 1}"
        up.draw_small_hexagons
      end
    end

    parent.visit do
      link d, child
      up.draw_list_door There.at d
    end
  }
end


module Hex
  module_function

  # boilerplate

  def make name: 'Hex'
    format = FORMAT

    path = File.join __dir__, 'output'

    reformat_page format
    BS.setup name: name, path: path, description: DESCRIPTION
    BS.grid format

    make!

    BS::Info.generate
    BS.generate
  end

  # rendering helpers

  def ui_style &block
    $bs.line_width 0.5 do
      $bs.color 'ff8800', &block
    end
  end

  def draw_list_door d
    ui_style do
      coords = d.to_poly.map { |x| $bs.grid.at x }
      $bs.poly coords

      # hexagon-ish / round-ish decoration

      max_x = coords.max_by { |xy| xy[0] }[0]
      max_y = coords.max_by { |xy| xy[1] }[1]

      min_x = coords.min_by { |xy| xy[0] }[0]
      min_y = coords.min_by { |xy| xy[1] }[1]

      dx = max_x - min_x
      dy = max_y - min_y

      # saner than lots of move/line-to's I think
      $bs.polyline [
        [max_x - dx / 8.0, min_y],
        [max_x + dx / 8.0, min_y + dy / 2.0],
        [max_x - dx / 8.0, max_y],
      ]
      $bs.polyline [
        [min_x + dx / 8.0, min_y],
        [min_x - dx / 8.0, min_y + dy / 2.0],
        [min_x + dx / 8.0, max_y],
      ]

      $bs.polyline [
        [min_x, max_y - dy / 8.0],
        [min_x + dx / 2.0, max_y + dy / 8.0],
        [max_x, max_y - dy / 8.0],
      ]
      $bs.polyline [
        [min_x, min_y + dy / 8.0],
        [min_x + dx / 2.0, min_y - dy / 8.0],
        [max_x, min_y + dy / 8.0],
      ]
    end
  end

  def link_back
    ui_style do
      link LINK_BACK_AREA, $bs.page.parent
    end
  end

  def draw_grid grid
    grid.each { |line|
      line = line.at $bs.grid
      ui_style do
        $bs.pdf.line [line.x, line.y], [line.x2, line.y2]
        $bs.pdf.stroke
      end
    }
  end

  def draw_footer text
    text = text.to_s

    # even though 0,0 coordinate here is at the bottom-left
    # text rendering box is defined by it's top-left corner
    # so there are two deltas +-1
    at = There.at([$bs.grid.x-1, 0+1]).at($bs.grid)

    ui_style do
    $bs.font $roboto_light do
      $bs.pdf.text_box text,
        at: at, width: at.w, height: at.h,
        align: :right, valign: :bottom
      end
    end
  end

  def draw_small_hexagons
    [
      Hexagon.new.rotate.transition([4, 5]),
      Hexagon.new.transition([12, 5]),
      Hexagon.new.rotate.transition([20, 5]),

      Hexagon.new.transition([4, 13]),
      Hexagon.new.rotate.transition([12, 13]),
      Hexagon.new.transition([20, 13]),

      Hexagon.new.rotate.transition([4, 21]),
      Hexagon.new.transition([12, 21]),
      Hexagon.new.rotate.transition([20, 21]),

      Hexagon.new.transition([4, 29]),
      Hexagon.new.rotate.transition([12, 29]),
      Hexagon.new.transition([20, 29]),
    ].each { |hex|
      hex.diagonals.each { |xs|
        xs = xs.map { |x, y| [x / 2.0, (y - 1) / 2.0] }
        xs = xs.map { |x| $bs.grid.at x }
        $bs.pdf.move_to xs[0]
        $bs.pdf.line_to xs[1]
      }
    }
    ui_style { $bs.pdf.stroke }
  end
end
