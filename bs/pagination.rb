module BS
  # TODO: separate integration that renders marks? can fully control order of rendering then
  module Pagination
    extend self

    # should be called right inside prototype ideally
    # for expected page order
    # so given block renders that page and all the rest of them
    #
    def generate prototype, count: 12, &block
      prototype.local[:pages] = count
      prototype.data.merge! page_index: 0
      prototype.visit &block if block
      parent = prototype.parent || prototype

      pagination = $bs.g.tl.up.select_right(count)
      pagination.each_with_index { |pos, i|
        if i == 0
          prototype.visit do
            mark2 pos.down(0.5), corner: 0.5
          end
          next
        end

        # same type and data
        data = prototype.data.merge page_index: i
        tag = prototype.tag
        parent.child_page prototype[:type], data do
          page.tag = tag
          link_back
          mark2 pos.down(0.5), corner: 0.5
          instance_eval &block if block
        end
      }
    end
  end
end
