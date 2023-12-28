require_relative 'base'

module BS
  class Items < Base
    KEY = :item

    # include_parent does not alter link_back
    def generate left: 0, right: 0, parent: nil, include_parent: false, &block
      parent = parent || BS.pages.get(:root)
      area = []
      area += $bs.g.tl.left.select_down left # left-leaning loc
      area += $bs.g.tr.right.select_down right
      area.each_with_index { |pos, i|
        data = { key(:pos) => pos, key(:index) => i }
        if include_parent && i == 0
          parent.data.merge! data
          parent.visit do
            instance_eval &block if block
          end
          next
        end

        parent.child_page key, data do
          link_back

          instance_eval &block if block
        end
      }
      $bs.data[key] = area
    end

    # goes across pages, adds visuals and links
    def integrate pages=BS.pages, stick: [] # + block for configuration... or another abstraction?
      _key = key
      key_pos = key :pos

      pages.each { |page|
        page.visit do
          item_pos = page.data[key_pos]

          $bs.data[_key].each { |pos|
            next if pos == item_pos

            # the latest path found from first page wins
            stick_levels = [{ key_pos => pos, unconditional: true}, *stick]
            stick_paths = (stick_levels.count + 1).times.drop(1).map { |i|
              stick_levels.take i
            }
            target = nil
            stick_paths.reverse.find { |path|
              pattern = {}
              path.each { |stick_item|
                case stick_item
                when Hash
                  hash = stick_item.dup
                  conditional = true
                  conditional = !hash.delete(:unconditional) if hash.has_key? :unconditional

                  applies = if conditional
                              matcher = SearchableArray.expand_matcher hash
                              matcher === page
                            else
                              true
                            end

                  pattern.merge! hash if applies
                when Symbol
                  key = stick_item
                  pattern.merge! key => page[key] if page.data[key]
                else
                  raise "unexpected stick #{key}: #{stick_item}"
                end
              }
              target = pages.get pattern
            }
            link pos, target
          }

          diamond item_pos, corner: 0.5 if item_pos
        end
      }
    end
  end
end
