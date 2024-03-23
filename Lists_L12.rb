require_relative 'bs/all'
END {
  ListsL12.make name: 'Lists_L12', title: nil
  # 12 meaning 1/2
  # L meaning landscape layout (not directly stored in PDF, should be forced by rm-hacks anyway)
} if __FILE__ == $0

# $fast = true

module ListsL12
  module_function

  def make **params
    setup **params
    # generate -> integrate pattern/process as I call it here:
    # generating pages is like setting-up the data/context
    # and rendering+linking may happen separately at integrate step given full context with any logics around it
    generate_root
    generate_lists
    generate_items
    integrate_root
    BS::Info.generate # final info page
    BS.generate # pdf file
  end

  # order-dependent calls inside
  def setup name:, title: nil, format: :L12
    @name = name
    @title = title
    @format = format

    path = File.join __dir__, 'output'
    reformat_page format
    BS.setup name: name, path: path, description: <<-END.lines.map(&:strip).join(?\n)
      Lists_L12.pdf

      This can be seen as advanced todo lists PDF.
      It is made for landscape forced + split 1/2 mode in RM (that requires rm-hacks currently).

      It supports a type of items that need further decomposition because every item has 11 pages inside.
      Adding titles and marking used links is the way to navigate within the PDF.

      First page (root) has:
      - links to lists pages, these links have space inside to give short name to the list
      - dots for whatever use, possibly to differentiate file preview by drawing something

      Lists:
      - every list has 7 items, linked by squares at the left
      - odd space at the left of every item row can be used for priority/ordering

      Items:
      - items have 11 consecutive pages each

      Also technically title can be rendered on every page by setting `title: 'ABC'` in `Lists.rb`.
      It should be useful if separate PDF file is used per project.

      Author: Alexander K.
      Project: https://github.com/sowcow/blank_slate_pdf
    END
    BS.grid format
  end

  def generate_root
    xx = self # xontext
    BS.page :root do
      page.tag = 'Lists_L12.pdf' # tags are used for preview graph
      xx.render_title
    end
  end

  def generate_lists
    xx = self
    list_pages.link_rects.sort_by { |p| [-p[0].y, p[0].x] }.each { |rect|
      # adding nested page, tree structure is the foundational pattern here
      # assigning rect to the new page so that data can be used in integrate step somewhere below
      root.child_page :list, rect: rect do
        link_back
        xx.render_title
        xx.list_bg.render_lines
      end
    }
  end

  def generate_items
    xx = self
    # selecting all list pages
    BS.xs(:list).each { |parent|
      list_items.link_rects.reverse_each { |rect|
        child = parent.child_page :item, rect: rect do
          BS::Pagination.generate page, count: 11, step: 0.5 do
            xx.render_title
            xx.leaf_page_bg.render_lines
            link_back
          end
        end
        # linking new item page from the parent list page
        # this could happen in a separate integration step if there was need to be more dynamic
        parent.visit do
          rect = rect.map(&:to_a).flatten
          link rect, child
        end
      }
    }
  end

  def integrate_root
    xx = self
    root.visit do
      xx.root_bg.render_lines

      BS.xs(:list).each do |pg|
        rect = pg[:rect].map(&:to_a).flatten
        link rect, pg
      end

      xx.root_dots.render_dots
    end
  end

  # UI grids/areas
  
  def root_dots
    # xs and ys are x and y coordinate of dots or perpendicular lines
    # then when such lines form grid cells those can be used as links interactive areas
    #
    # grid is hardcoded here 8x12 (half of full 12x16 grid)
    # but using $bs.g.w to get grid width would be the dynamic way
    one = BS::LinesGrid.new
    # this makes 7x7 areas between dots using half-step density (double density of dots compared to grid)
    one.ys *(7+1).times.flat_map { |x| [x, 0.5+x]}.reject { |x| x == 0 }
    one.xs *(7+1).times.flat_map { |x| [x, 0.5+x]}.reject { |x| x == 0 }
    one
  end

  def root_bg
    one = BS::Group.new
    one.push list_pages
    one
  end

  def list_pages
    one = BS::LinesGrid.new
    if $fast
      one.ys 8, 9
      one.xs 0, 2
    else
      one.ys 8, 9, 10, 11, 12
      one.xs 0, 2, 4, 6, 8
    end
    one
  end

  def list_items
    one = BS::LinesGrid.new
    one.xs 0, 1.5
    one.ys *(7+1).times.map { |i| i * 1.5 + 0.5 }
    one.x_range 0, $bs.g.w
    one
  end

  def list_bg
    list_bg = BS::Group.new
    list_bg.push list_items

    7.times { |i|
      one = BS::LinesGrid.new
      one.xs 0.5
      one.ys 1 + 1.5 * i
      one.x_range 0.5, 1.5
      one.y_range 1 + 1.5 * i, 2 + 1.5 * i
      list_bg.push one
    }
    list_bg
  end

  def leaf_page_bg
    it = BS::Group.new
    one = BS::LinesGrid.new
    one.xs *(0..$bs.g.w).flat_map { |x| [x, x+0.5] }
    one.ys *(0..($bs.g.h - 1)).flat_map { |x| [x, x-0.5] }
    it.push one
    it.push one
    it
  end

  # helpers

  def root
    BS.pages.first
  end

  def render_title
    header @title
  end

  def use_font &block
    $bs.font $roboto_light do
    $bs.color ?4, &block
    end
  end

  def header text
    return unless text
    use_font do
      $bs.put_text At[4, 11.5], text, adjust: 0.77
    end
  end
end
