require_relative 'base'

module BS
  class TopNotes < Base
    KEY=:top_note

    def generate count: 12, parent: nil, &block
      parent = parent || BS.pages.get(:root)
      area = $bs.g.lt.up.select_right(count)

      area.each { |pos|
        first = nil
        12.times { |note_page_index|
          data = { key(:pos) => pos }
          parent.child_page key, data do
            first ||= page
            link_back

            asterisk pos

            cell = g.tl.up.right(note_page_index).down 0.5
            mark2 cell.to_a, corner: 0.5

            instance_eval &block if block
          end
        }
        first.local[:pages] = 12
      }
      $bs.instance_eval { @notes = area }
    end

    def integrate pages=BS.pages
      that = self
      pages.each { |page|
        page.visit do
          @notes.each { |xy|
            that_page = pages.find { |x| x.data[that.key :pos] == xy }
            link xy, that_page
          }
        end
      }
    end
  end
end
