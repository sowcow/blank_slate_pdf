BEGIN {
  require_relative 'bs/all'
}

END {
  Rubicks.make
} if __FILE__ == $0

module Rubicks
  module_function

  FORMAT = 16  # 12x16 standard grid fitting RM screen fully
  DESCRIPTION = <<~END
    Rubiks.pdf

    Experimental PDF for those who starve for color in PDFs on their RM Pro device.
    Even though it is experimental it has structure, plenty of pages, grids on pages, so it should be usable in theory.

    Main page has nine big square links to different child pages with preview of used color scheme.
    Child pages have big 12x16 grids where each cell has own color on the spectrum of the colorscheme.
    Then by turning pages there are overall eight different layouts/rotations of the same color scheme on the page.
    This way every page is unique even though only 9 main color schemes are used.

    Every child page has wide link back to root/main page in the top right corner.

    Technically speaking upper three color schemes use one of red, green, blue components to maximum and two axes make a square grid.
    Second row explores grids where two of components (r, g, b) always have equal value.
    Third row explores grids where two of components (r, g, b) are put into inverse relation.

    Author: Alexander K.
    Project: https://github.com/sowcow/blank_slate_pdf
  END

  # it feels good so I keep it this way (1/4 screen width)
  # not having an arrow seem fine by me, as abstract as it can get
  LINK_BACK_AREA = There.at [9, 15, 3, 1]
end


def Rubicks.make!
  # root page generation
  BS.page :root do
    page.tag = 'Rubicks.pdf'
  end
  root = BS.pages.first

  main_grid = 3 # 3x3
  main_cell = 4
  (main_grid ** 2).times { |i|
    x = i % main_grid
    y = i / main_grid
    y = 3 - y # no idea why 3

    table = ColorTable.new(&ColorTable.setup_options[i])

    child = nil
    space = nil
    4.times do |page_i|
      this_space = make_color_space table: table do |cells|
        page_i.times {
          cells = rotate cells
        }
        cells
      end
      this_child = root.child_page :scheme, &this_space
      this_child.visit do
        Rubicks.link_back
      end
      child = this_child unless child
      space = this_space unless space
    end
    4.times do |page_i|
      this_space = make_color_space table: table do |cells|
        cells = swap_axes cells
        page_i.times {
          cells = rotate cells
        }
        cells
      end
      this_child = root.child_page :scheme, &this_space
      this_child.visit do
        Rubicks.link_back
      end
    end

    child_x = x*main_cell
    child_y = y*main_cell
    child_area = There.at [child_x, child_y, main_cell, main_cell]
    root.visit do
      link child_area, child

      cells = space.cells
      interest = [0, 4, 7, 11]
      subset = cells.select { |c|
        interest.include?(c[:x]) &&
          interest.include?(c[:y])
      }.map &:dup

      subset.each { |c|
        c[:x] = interest.index(c[:x])
        c[:y] = interest.index(c[:y])
      }

      convert = -> x { $resolution.px_to_pt x }
      # at vs pt - but pt is obscure pdf name I'd try to avoid
      at = -> *xy {
        return convert[xy.first] if xy.count == 1
        xy.map &convert
      }
      cell_size = $resolution.small_side / 12

      subset.each do |cell|
        xx = child_x * cell_size + cell[:x] * cell_size
        yy = child_y * cell_size - cell[:y] * cell_size + 4 * cell_size # no idea what is 4

        padding = 1
        square_size = cell_size - padding
        pdf.fill_color cell[:color]
        pdf.fill_rectangle at[xx, yy], at[square_size], at[square_size]
      end
    end
  }
end

# assumes square
def rotate xs
  max = xs.max_by { |x| x[:x] }[:x]
  xs.map { |c|
    c.merge x: max - c[:y], y: c[:x]
  }
end

def swap_axes xs
  xs.map { |c|
    c.merge x: c[:y], y: c[:x]
  }
end

require_relative 'lib/color_table'
def make_color_space count_x: 12, count_y: 16, table:, &block
  convert = -> x { $resolution.px_to_pt x }
  # at vs pt - but pt is obscure pdf name I'd try to avoid
  at = -> *xy {
    return convert[xy.first] if xy.count == 1
    xy.map &convert
  }

  cell_size = $resolution.small_side / count_x
  padding = 1
  square_size = cell_size - padding
  cells = table.generate count: count_x
  cells = block.call cells if block

  result = proc {
    cells.each do |cell|
      xx = cell[:x] * cell_size
      yy = cell[:y] * cell_size
      pdf.fill_color cell[:color]
      pdf.fill_rectangle at[xx, $resolution.h - yy], at[square_size], at[square_size]
    end
    (count_y - count_x).times { |iy|
      render_y = count_x + iy
      source_y = count_x - iy - 1 - 1
      count_x.times { |x|
        cell = cells.find { |c| c[:x] == x && c[:y] == source_y }

        xx = cell[:x] * cell_size
        yy = render_y * cell_size

        pdf.fill_color cell[:color]
        pdf.fill_rectangle at[xx, $resolution.h - yy], at[square_size], at[square_size]
      }
    }
    pdf.fill_color ?0 * 6
  }
  result.define_singleton_method :cells do cells end
  result
end


module Rubicks
  module_function

  # boilerplate

  def make name: 'Rubicks'
    format = FORMAT

    path = File.join __dir__, 'output'

    reformat_page :pro
    BS.setup name: name, path: path, description: DESCRIPTION
    BS.grid format

    make!

    BS::Info.generate
    BS.generate
  end

  # rendering helpers

  def link_back
    $bs.link LINK_BACK_AREA, $bs.page.parent
  end
end
