require_relative 'base'

module BS
  class CornerNotes < Base
    KEY = :corner_note

    def generate parents, &block
      parents = [*parents]

      corner = self.corner
      pagination = $bs.g.tl.up.select_right(12)

      parents.each { |parent|
        first_child = nil
        pagination.each { |pos|
          parent.child_page key do
            first_child = page unless first_child

            link_back
            mark2 pos.down(0.5), corner: 0.5
            asterisk corner

            instance_eval &block if block
          end

          parent.visit do
            link corner, first_child
          end
        }
      }
    end

    def corner
      $bs.g.tr
    end

    api def link page
      $bs.link corner, page
    end
  end
end
