require_relative 'bs/all'
BS.will_generate if __FILE__ == $0

#flavour = :nested # not much value in nesting with PDFs it seems
flavour = :flat
item_count = 6

path = File.join __dir__, 'output'
BS.setup name: "NBS", path: path, description: <<END
  Abstract PDF for graphs or possibly mind-mapping.
  Root page is a table of contents for items.
  Items at the left (mostly top) outside the grid can be seen as layers.
  Then there are nodes and each has own pages inside if needed.
  Experimental.
  ---
  UI patterns:
  - RM user should have toolbar closed
  - file-scoped notes are above the grid
  - items can be found outside the grid at sides
END
BS.grid 18

BS.page :root do
  draw_dots # looking for some story consistency with other views
  #draw_dots border: true
  #draw_stars # could be lines but it is too chaotic and non-defined here
end

BS::Items.generate left: item_count

BS.pages.xs(:item).each { |parent|
  BS::Nova.generate parent: parent do
    if flavour == :nested
      BS::Nova.draw_nova_grid page
    end

    if flavour == :flat
      BS::Pagination.generate page do
        draw_stars dots: false
      end
    end
  end
}

if flavour == :nested
  BS.pages.xs(:nova).each { |parent|
    BS::Nova[:nova2].generate parent: parent, nova_size: 2 do
      draw_stars dots: false
    end
  }
end

# iteration notes per file as I use it
BS::TopNotes.generate do
  draw_stars # creative
end

BS::Items.integrate stick: [
  :nova_pos,
  :nova2_pos,
  { type: :corner_note }
]
BS::TopNotes.integrate
BS::Nova.integrate
BS::Nova[:nova2].integrate
