module BS
  module TopNotes
    extend self

    def generate count: 12, parent: nil, prefix: 'note', &block
      parent = parent || BS.pages.get(:root)
      area = $bs.g.lt.up.select_right(count)

      area.each { |pos|
        12.times { |note_page_index|
          data = { :"#{prefix}_pos" => pos }
          parent.child_page :note, data do
            link_back

            asterisk pos

            cell = g.tl.up.right(note_page_index).down 0.5
            mark2 cell.to_a, corner: 0.5

            instance_eval &block if block
          end
        }
      }
      $bs.instance_eval { @notes = area }
    end

    def integrate pages=BS.pages
      pages.each { |page|
        page.visit do
          @notes.each { |xy|
            that_page = pages.find { |x| x.data[:note_pos] == xy }
            link xy, that_page
          }
        end
      }
    end
  end
end
