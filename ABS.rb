require_relative 'bs/all'
BS.will_generate if __FILE__ == $0

draw_grid = $draw_grid || -> _ { draw_stars }
name = $name || 'ABS'

path = File.join __dir__, 'output'
BS.setup name: name, path: path, description: <<END
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
  - RM user should have toolbar closed
  - file-scoped notes are above the grid
  - items can be found outside the grid at sides
  - item-scoped corner notes are in the upper-right corner of the grid
  - pagination is not UI-interactive, only page turning is meant
END
BS.grid 18

BS.page :root do
  instance_eval &draw_grid
end

is_left = -> page { page[:item_pos].x == -1 }

BS::Items.generate left: 18, right: 18 do
  if is_left[page]
    BS::Pagination.generate page do
      instance_eval &draw_grid
    end
  else
    instance_eval &draw_grid
  end
end

# prefix vs filtering?
right_items = BS.pages.xs(:item).reject &is_left

BS::CornerNotes.generate right_items do
  instance_eval &draw_grid
end

# iteration notes per file as I use it
BS::TopNotes.generate do
  instance_eval &draw_grid
  #draw_stars # always creative setup or consistent to file?
end

BS::Items.integrate stick: [
  { type: :corner_note }
]
BS::TopNotes.integrate
