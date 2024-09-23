BEGIN {
  require_relative 'bs/all'
}

END {
  Rounds32.make
} if __FILE__ == $0

module Rounds32
  module_function

  FORMAT = 16  # 12x16 standard grid fitting RM screen fully
  DESCRIPTION = <<~END
    32.pdf

    Random abstract PDF.
    The main page may be the most interesting by itself.
    Otherwise it simple set of 32 5-item lists with 17 consecutive pages per item.

    - main page has a hexagon grid of roundish links,
      so it can have experimental uses like mind mapping
    - inside such links there is a single page of content space and a list of five items with links per item to go down further
    - every such item has 17 consecutive pages with pagination marker on top
    - turning pages outside those paginated items just moves between those list pages
    - link for going back/up is in the top right corner
    - must do with such PDFs is to mark or name links before entering them and then to write the same name into the page header after entered the link

    Catchall is not part of the PDF, I assume it should be just flat.

    This info is also on the last page of the PDF.

    Author: Alexander K.
    Project: https://github.com/sowcow/blank_slate_pdf
  END

  # it feels good so I keep it this way (1/4 screen width)
  # not having an arrow seem fine by me, as abstract as it can get
  LINK_BACK_AREA = There.at [9, 15, 3, 1]
end


def Rounds32.make!
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

      # setting data for internal list items here too
      size = 1.5
      rounds.last[:items] = 5.times.reverse_each.map.with_index { |i, item_index|
        value = { x: 0, y: i*size, w: size, h: size }
        value[:round_index] = index
        value[:item_index] = item_index
        value
      }
      rounds.last[:index] = index
      index += 1
    }
  }

  up = self # :visit and such methods change into page context

  # root page generation
  BS.page :root do
    page.tag = '32.pdf'
  end
  root = BS.pages.first

  # grid for ui
  grid = SmartGrid.new([0, 12], [0, 16])
  grid.add_verticals 0.5
  grid.add_horizontals 0.5

  # bordering lines:
  grid.drop_lines [0, nil]
  grid.drop_lines [12, nil]
  grid.drop_lines [nil, 0]
  grid.drop_lines [nil, 16]

  # header areas:
  grid.cut_hole [
    [0, 12 - Rounds32::LINK_BACK_AREA.w], [15, 16]
  ]
  grid.cut_hole [
    [12 - Rounds32::LINK_BACK_AREA.w, 12], [15, 16]
  ]
  used_grid = grid

  # rounds pages generation
  parent = root
  rounds.each { |d|
    child = parent.child_page :round, d do
      grid = used_grid.dup
      d[:items].each { |x|
        at = There.at x
        grid.cut_hole [
          [at.x, at.x2], [at.y, at.y2]
        ]
      }

      up.link_back
      up.draw_grid grid
      up.draw_footer d[:index] + 1
    end

    parent.visit do
      link d, child
      up.draw_list_door There.at d
    end
  }

  # items of rounds generation
  BS.xs(:round).each do |parent|
    parent[:items].each { |d|
      child = parent.child_page :item, d do
        BS::Pagination.generate page, count: 17, step: 0.5 do
          # BS::Pagination.generate page, count: 9, step: 1 do
          up.link_back
          up.draw_grid used_grid
          up.draw_footer "#{d[:round_index] + 1}.#{d[:item_index] + 1}"
        end
      end

      parent.visit do
        link d, child
      end
    }
  end
end


module Rounds32
  module_function

  # boilerplate

  def make name: '32'
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
      # $bs.color '008080', &block
      $bs.color 8, &block
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
end
