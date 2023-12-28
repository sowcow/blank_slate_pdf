require_relative 'bs/all'
BS.will_generate if __FILE__ == $0

draw_grid = $draw_grid || -> _ { draw_stars }
name = $name || 'BS2'

path = File.join __dir__, 'output'
BS.setup name: name, path: path, description: <<END
  BS2 is two levels deep BS.
  The right side items are actually sub-items of the left-side ones.
  It can be seen as NBS for more free diagrams and the right side is a legend to go deeper into parts of them.
  ---
  UI patterns:
  - RM user should have toolbar closed
  - file-scoped notes are above the grid
  - items can be found outside the grid at sides
END
BS.grid 18

BS.page :root do
  instance_eval &draw_grid
end

BS::Items.generate left: 18 do
  instance_eval &draw_grid
end

BS.pages.xs(:item).each { |parent|
  BS::Items[:item2].generate parent: parent, right: 18 do
    instance_eval &draw_grid
  end
}

BS::TopNotes.generate do
  instance_eval &draw_grid
end

BS::Items.integrate
BS::Items[:item2].integrate BS.pages.drop(1).to_sa, stick: [
  :item_pos
]
BS::TopNotes.integrate
