require_relative 'base'

module BS
  class Items < Base
    KEY = :item

    # stick must exist on all integrated pages

    # include_parent does not alter link_back
    def generate area: [], left: 0, grid_left: 0, right: 0, top: 0, parent: nil, include_parent: false, space_x: 0, space_y: 0, levels: 1, &block
      parent = parent || BS.pages.get(:root)
      area += $bs.g.tl.left.select_down left # left-leaning loc
      area += $bs.g.tl.select_down grid_left
      area += $bs.g.tr.right.select_down right
      area += $bs.g.tl.up.select_right top
      if space_x
        area = area.map.with_index { |x, i|
          x.right(space_x + i*2*space_x)
        }
      end
      if space_y
        area = area.map.with_index { |x, i|
          x.down(space_y + i*2*space_y)
        }
      end
        area.each_with_index { |pos, i|
      levels.times { |level|
          data = {
            key(:pos) => pos,
            key(:index) => i,
            key(:count) => area.count,
            key(:level) => level,
            key(:level_count) => levels,
          }
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
      }
      $bs.data[key] ||= []
      $bs.data[key] << { area: area, space_x: space_x, space_y: space_y }
    end

    # this code starts to be messy or I need more explicit naming

    # goes across pages, adds visuals and links
    def integrate pages=BS.pages, stick: [] # + block for configuration... or another abstraction?
      _key = key
      key_pos = key :pos
      that = self

      pages.each { |page|
        #next if page[:hide]

        page.visit do

          item_pos = page.data[key_pos]
          $bs.data[_key].each { |config|
            area = config[:area]
            space_x = config[:space_x]
            space_y = config[:space_y]
          area.each { |pos|
            # the latest path found from first page wins
            stick_levels = [{ key_pos => pos, unconditional: true}, *stick]

            # "levels:" linking handling
            if pos == item_pos
              this_level = page[that.key(:level)]
              count = page[that.key(:level_count)]
              next_level = (this_level + 1) % count

              stick_levels << {
                that.key(:level) => next_level,
                unconditional: true
              }
            end

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
            link_pos = pos.dup
            link_pos = [*link_pos, *link_pos]
            if space_x
              link_pos[0] -= space_x
              link_pos[2] += space_x
            end
            if space_y
              link_pos[1] -= space_y
              link_pos[3] += space_y
            end
            require 'pry'; binding.pry if not target
            link link_pos, target
          }
          }

          if item_pos
            if page[that.key(:level)] > 0
              #diamond item_pos, corner: 0.5, fill: true
              cross item_pos, corner: 0.5
            else
              diamond item_pos, corner: 0.5
            end
          end
        end
      }
    end
  end
end
