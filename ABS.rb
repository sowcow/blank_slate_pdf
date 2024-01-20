require_relative 'bs/all'
END { ABS.make name: 'ABS_STARS', grid: ?S } if __FILE__ == $0

#$debug = true
#$colored = true

# - high contrast version value with borders too?

module ABS
def self.make name:, grid:
###

path = File.join __dir__, 'output'

BS.setup name: name, path: path, description: <<END
  TODO: update. Text that also goes with image and relies on it in part?
  ...
  Abstract PDF for multi-page list items.
  The file is meant to be used on the exploratory side of things.
  The Left items have pagination directly in the item and there is no predefined page for resolution of the item.
  They offer standard abstract blank slate that stands out of the way.
  Right items are new in this configuration.
  Right items have predefined main page and nested pages in corner notes.
  In this PDF I look at right items to be exploratory too so the main page is not the review summary but likely
  to be a question/fact/decision that gets tested/looked-into over time.
  Checklist flavour could be there.
  ---
  UI patterns:
  TODO: update
  ...
  - RM user should have toolbar closed
  - file-scoped notes are above the grid
  - items can be found outside the grid at sides
  - item-scoped corner notes are in the upper-right corner of the grid
  - pagination is not UI-interactive, only page turning is meant

  - pages > subitems continuation
  - divided final page of collection

  Author: Alexander K.
  Project: https://github.com/sowcow/blank_slate_pdf
END

bg = BS::Bg.new grid

BS.page :root do
  page.tag = 'ABS.pdf'
  draw_grid bg.first
end

last_page_marks = -> {
  a = $bs
  if a.page[:subitem_index] == a.page[:subitem_count] - 1
    g = a.g
    x = a.g.xs.at 12
    y0 = a.g.ys.at 0
    y1 = a.g.ys.at g.h
    a.color 8 do
      a.pdf.stroke_line x, y0, x, y1
    end
  end
}

item_page = proc do
  item_bg = bg.take
  BS::Pagination.generate page do
    draw_grid item_bg
  end
  # both hands version + informative pagination? rotation in mind makes it interesting and unclear yet
  # reverse order is not that intuitive when rotated too
  #BS::Items[:subitem].generate area: $bs.g.tl.select_right(12), parent: page do
  BS::Items[:subitem].generate area: $bs.g.tr.right.select_down(3), parent: page do
    draw_grid item_bg
    last_page_marks.call
  end
end

BS::Items.generate top: 4, space_x: 1, levels: 2, &item_page

BS::Items.integrate
xs = BS.pages.select { |x| %i[ item subitem ].include? x[:type] }
BS::Items[:subitem].integrate xs.to_sa, stick: [
  :item_pos
]

BS::Info.generate

BS.generate

###
end
end
