require 'date'
require_relative 'lib/point'

this_name = File.basename(__FILE__).sub /\..*/, ''

frame = -> w, h { Grid.new.apply(w,h).rect 1, 0, -2, -2 }

# - not to have root? then no back at items pages, feels odd somehow
# ~ chess connotation
# ~ Apex in naming

nbs = BlankSlatePDF.new(this_name) do
  configure $setup
  configure({ grid: Grid.new(x: 12, y: 18, name: :stars, frame: frame).apply(PAGE_WIDTH, PAGE_HEIGHT) })

  description <<-END
    # Nova Blank Slate
    
    2D space with links around to draw/map notions/entities on.
    Space around links to name those entities and draw connections.
    Multiple pages as layers.
    Blank notes space inside entities (with pages?)
    (Could be checklists space inside entities too: abstract vs blank vs custom)

    ~ bigger cicrle breadcrumb
    ~ layers are items at both sides => root page to name layers (likely are given way later if at all)
      so I'd omit root page for starters or maybe keep it blank
  END

  step = 0
  squares = 27.times.map { |i|
    ax = i % 3
    ay = i / 3

    x = ax * 4 # +empty columns
    y = 18 - ay * 2 # +empty rows
    if ay.odd?
      x += 2 # +shift
    end

    Point[x, y]
    #at = grid.at x, y, corner: 0
    #{ pos: pos } # XXX: shitty pattern, gotta use any object + define more methods on it or whatever rich OO-way
  }

  pagination = 12.times.map { |i|
    x = i
    y = 18
    Point[x, y]
  }

  draw_grid = -> _=nil {
    name = _.nil? ? set_grid_name : @context.set_grid_name
    public_send name
  }

  items = [] # actualy with layers meaning in this context, but items in overall Blank Slate use because they are stil flex
  12.times { |i|
    cell = [-1.0, 18 - 1 - i] # at the left of the grid
    items << cell
  }
  0.times { |i|
    cell = [12, 18 - 1 - i] # at the right of the grid
    items << cell
  }

  #items = items.take 1 # XXX

  # main pages
  pages = []
  page do
    pages << current_page
    current_page.data = { root: true }
    draw_dots

    items.each { |item_cell|
      page do
        pages << current_page
        current_page.data = { item_cell: item_cell }
        # ? unify map vs data vs context-addup (oop-ish) - on lookup can use chain of parents and that's all for it?
        # having pool of them automatically too
        # (factoring improvement ideas, I guess the word refactoring got a smell/connotations already)

        # it is too convenient place not to do it here
        double_back_arrow
        diamond item_cell, corner: 0.5
      end
    }
  end

  # splitting drawing dots because why not
  pages.select { |x| x.data[:item_cell] }.each { |page|
    revisit_page page do
      squares.each { |pos|
        dot pos.to_a
        dot (pos + Point[1, 0]).to_a
        dot (pos + Point[0, -1]).to_a
        dot (pos + Point[1, -1]).to_a
      }
    end
  }

  # having details pages
  pages.select { |x| x.data[:item_cell] }.each { |page|
    with_parent page do
      squares.each { |square_pos|
        pagination.each_with_index { |cell, i|
          page do
            pages << current_page
            current_page.data = page.data.merge square_pos: square_pos, page_cell: cell, page_index: i
            item_cell = current_page[:item_cell]

            double_back_arrow
            diamond item_cell, corner: 0.5

            cell = cell.dup
            cell.y -= 0.5 # keeping header place (clear) in place as I see it in current general trend of the BS project
            mark2 cell.to_a, corner: 0.5

            #draw_dots
            draw_crosses # could be file size optimization but not looking that dramatic

            color 8 do
              pos = square_pos.dup
              pos.y -= 1
              at = grid.at *pos, corner: 0.5
              r = grid.by_x.step / 2.0
              pdf.stroke_circle at, r
            end
          end
        }
      }
    end
  }

  # and linking them from the parent
  pages.select { |x| x.data[:page_index] == 0 }.each { |page|
    revisit_page page.parent do
      pos = page[:square_pos].dup
      pos.y -= 1
      link! pos, page # should use ! version for debugging only and then convert to normal, remove old unused link pattern therefore
    end
  }

  # feature: notes pagesets
  notes = 12.times.map { |i| Point[i, 18] } # things imply cells here... so maybe coloring of a kind is the way/abstraction (on the grid)
  root = pages.find { |x| x[:root] }
  # pages.root as search by tag vs too much magics?
  with_parent root do
    notes.each { |pos|
      12.times { |note_page_index|
        page do
          pages << current_page
          current_page.data = { note_pos: pos }

          draw_stars # good for creative, my current association
          double_back_arrow

          text_pos = pos + [0, 1]
          text_at = grid.at *text_pos, corner: 0 # text needs that shift up the cell
          size = grid.by_x.step

          cell = Point[note_page_index, 18]
          cell.y -= 0.5 # keeping header place (clear) in place as I see it in current general trend of the BS project
          mark2 cell.to_a, corner: 0.5

          color 8 do
            font $roboto do
              font_size size * 0.9 do
                text = ?*
                pad_x = 0
                pad_y = 0
                dy = size * -0.2
                text_at[1] += dy
                pdf.text_box text, at: text_at, width: size-pad_x, height: size-pad_y, align: :center, valign: :bottom
              end
            end
          end
        end
      }
    }
  end
  # + linked everywhere
  pages.each { |page|
    revisit_page page do
      notes.each { |xy|
        # selector + caching when used from the same line+token
        that_page = pages.find { |x| x.data[:note_pos] == xy } # first page found is already there by default
        link! xy, that_page
      }
    end
  }

  # item menu everywhere
  pages.each { |page|
    revisit_page page do
      items.each { |xy|
        that_page = if page.data[:square_pos]
          pages.find { |x| x.data[:item_cell] == xy && x.data[:square_pos] == page[:square_pos] }
        else
          pages.find { |x| x.data[:item_cell] == xy } # assuming they go first, makes sense for hierarchy search
        end
        link! xy, that_page
      }
    end
  }

  # will factor-in
  render_file
end

result = [nbs.dup]
$configs_loaded = result
