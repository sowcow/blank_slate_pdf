require_relative 'base'

module BS
  class Nova < Base
    KEY = :nova

    def novas
      27.times.map { |i|
        ax = i % 3
        ay = i / 3

        x = ax * 4 # +empty columns
        y = 18 - 1 - ay * 2 # +empty rows
        if ay.odd?
          x += 2 # +odd shift
        end

        Point[x, y]
      }
    end

    api def draw_nova_grid page
      xs = novas
      page.visit do
        xs.each { |pos|
          dot pos
          dot pos.right
          dot pos.up
          dot pos.right.up
        }
      end
    end

    def generate parent: nil, nova_size: 1, &block
      parent = parent || BS.pages.get(:root)

      draw_nova_grid parent
      novas.each { |pos|
        child = nil
        parent.child_page key, key(:pos) => pos, key(:size) => nova_size do
          child = page

          link_back

          instance_eval &block if block
        end
        parent.visit do
          link pos, child
        end
      }
    end

    def integrate pages=BS.pages
      key_pos = key :pos
      key_size = key :size
      pages.xs(key_pos => -> x { !x.nil? }).each { |page|
        page.visit do
          pos = page[key_pos]
          color 8 do
            at = grid.at *pos, corner: 0.5
            r = grid.xs.step / 2.0 * page[key_size]
            pdf.stroke_circle at, r
          end
        end
      }
    end
  end
end
