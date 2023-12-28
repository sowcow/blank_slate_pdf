this_name = File.basename(__FILE__).sub /\..*/, ''

# some hourly printed-on ABS? 18 hours are items from 6 to 24, inside can have any details
# yml for printing then
# file names in yaml then?
# bg config too then
# => images from that into readme

# - readme images

# ? actual RTL version???
# hand-configuration versions of this PDF do not affect position if things except
# the back button to not collide with RM navigation controls
# so left-to-write writing is assumed

require 'yaml'
_ABS_config = File.join __dir__, 'ABS.yml'
$ABS_config = nil
$ABS_config = YAML.load_file _ABS_config if File.exist? _ABS_config

frame = -> w, h { Grid.new.apply(w,h).rect 1, 0, -2, -2 }

BS = BlankSlatePDF.new(this_name) do
  configure $setup
  configure({ grid: Grid.new(x: 12, y: 18, name: :stars, frame: frame).apply(PAGE_WIDTH, PAGE_HEIGHT) })
  #configure({ set_grid_name: :draw_dots })

  description <<-END
    # Main

    Abstract and very flexible inter-connected PDF for different workflows and experiments.
    Tested on Remarkable only.
    It is optimized for the right-hand left-to-right writing experience because links are positioned to not appear under the hand.

    # Constraints

    Important notes for RM:
    - you'll need to hide the toolbar to have navigation links accessible

    # Contents

    This PDF has three levels of pages:
    - top-most root page
    - item pages
    - sub-pages

    Root page has 18 "invisible" square links at the left of the grid (outside the grid itself).
    One workflow is to mark any link with a circle, then to write some name nearby, then to tap the circle and maybe repeat the name as the header on the newly opened page.

    The opened page is that item page.
    By turning pages you have 12 pages there and kind-of pagination above.
    Also there are links to sub pages: 3 of them are at the right near the upper-right corner outside the grid.

    Sub pages are single pages per item so there is no pagination for them.
    Instead they have different page-turning dynamics: by turning pages you change the item at the left instead.
    This should make better place for more general notes or item summary/review.
    The dynamics can be seen as more optimized for reading/scanning through multiple items.
    And for that reason it makes sense to use those the same way consistently through different items.

    # Other
    
    Navigation back/up is by arrow at the upper corner.
    Also there are breadcrumbs left at the place of links.
    They should be helpful to actually see page-turning dynamics.
  END

  pages = []
  sub_pages = []

  # it is 2D (in potential, not in use):
  list_item_coordinates = []
  group_items_coordinates = []

  grid_y.times.reverse_each { |y|
    x = -1.0 # to the left of the grid
    list_item_coordinates << [x, y]
  }

  sub_items = [
    #{ at: [grid_x - 3, grid_y] },
    #{ at: [grid_x - 2, grid_y] },
    #{ at: [grid_x - 1, grid_y] },
    { at: [grid_x, grid_y - 1] },
    { at: [grid_x, grid_y - 2] },
    { at: [grid_x, grid_y - 3] },
  ]
  special_pages_count = sub_items.select { |x| x[:at][1] === grid_y }.count

  (grid_x - special_pages_count).times.each { |x|
    y = grid_y # above the grid
    group_items_coordinates << [x, y]
  }

  render_layout = -> rendered_page {
    data = rendered_page.data
    proc {
      public_send set_grid_name if defined? set_grid_name

      link_back_page_corner_18 rendered_page.parent if rendered_page.parent

      # root page case
      unless data
        list_item_coordinates.each_with_index { |at, list_index|
          page = pages.find { |p| p.data && p.data[:group_index] == 0 && p.data[:list_index] == list_index }
          if page
            link! [-1.0, list_index], page unless data && list_index == data[:list_index]
          end
        }
        next
      end

      # non-root pages
      group_items_coordinates.each_with_index { |at, group_index|
        page = pages.find { |p| p.data && p.data[:group_index] == group_index && p.data[:list_index] == data[:list_index] }
        if page
          if data && data[:sub_item]
            link! at, page
          else
            link! at, page unless data && group_index == data[:group_index]
          end
        end
      }

      if data[:sub_item]
        # special sub-pages
        diamond data[:diamond_at], corner: 0.5 if data[:diamond_at]
        diamond data[:sub_item][:at], corner: 0.5 if data[:sub_item][:at]

        list_item_coordinates.each_with_index { |at, list_index|
          page = sub_pages.find { |p| p.data && p.data[:list_index] == list_index && p.data[:sub_item] && p.data[:sub_item][:at] == data[:sub_item][:at] }
          if page
            link! [-1.0, list_index], page unless data && list_index == data[:list_index]
          end
        }
      else
        # pagination base pages
        diamond data[:diamond_at], corner: 0.5 if data[:diamond_at]
        mark2 data[:mark_at], corner: 0.5 if data[:mark_at]

        list_item_coordinates.each_with_index { |at, list_index|
          page = pages.find { |p| p.data && p.data[:group_index] == 0 && p.data[:list_index] == list_index }
          if page
            link! [-1.0, list_index], page unless data && list_index == data[:list_index]
          end
        }
      end
    }
  }

  page do
    root_page = page_stack.first
    pages << root_page
    root_page.define_singleton_method :data do
      nil
    end

    list_item_coordinates.each_with_index { |at, index|
      group_items_coordinates.count.times { |i|
        pages << page do
          inverse_index = list_item_coordinates.count - 1 - index
          self.define_singleton_method :data do
            { at: at, list_index: inverse_index, group_index: i, diamond_at: at, mark_at: [i, grid.y] }
          end
        end
      }
    }
  end

  pages.each { |page|
    revisit_page page do
      instance_eval &render_layout[page]
    end
  }

  sub_items.each { |sub_item|
    parent_items = pages.select { |page|
      page.data && page.data[:group_index] == 0
    }
    parent_items.each { |parent|
      # incrementally things ask for some interesting refactoring but there is no point yet
      with_parent parent do
        sub_pages << page do
          self.define_singleton_method :data do
            parent.data.merge sub_item: sub_item
          end
        end
      end
    }
  }

  # go at the end separately, have own separate page-turning dynamics
  sub_pages.each { |page|
    revisit_page page do
      instance_eval &render_layout[page]
    end
    parent_group = pages.select { |x|
      x.data && x.data[:list_index] == page.data[:list_index]
    }
    parent_group.each { |parent_group_page|
      revisit_page parent_group_page do
        at = page.data[:sub_item][:at]
        link! at, page
      end
    }
    other_sub_items = sub_items.reject { |x| x == page.data[:sub_item] }
    revisit_page page do
      other_sub_items.each { |other_sub_item|
        that_page = sub_pages.find { |p| p.data[:list_index] == page.data[:list_index] && p.data[:sub_item] == other_sub_item }
        link! other_sub_item[:at], that_page
      }
    end
  }

  render_file
end


#have_hand_versions = -> given_bs {
#  result = []
#
#  bs = given_bs.dup
#  bs.name = "RIGHT_#{bs.name}"
#  bs.configure({hand: RIGHT}, deep: false)
#  result << bs
#
#  bs = given_bs.dup
#  bs.name = "LEFT_#{bs.name}"
#  bs.configure({hand: LEFT}, deep: false)
#  result << bs
#
#  result
#}

#have_grid_versions = -> given_bs {
#  result = []
#
#  %w[sand stars waves bamboo].each { |bg_name|
#    bs = given_bs.dup
#    bs.name = "#{bs.name}_#{bg_name.upcase}"
#    bs.configure({set_grid_name: "draw_#{bg_name}"}, deep: false) # deep thingy better be different method completely
#    result << bs
#  }
#
#  #bs = given_bs.dup
#  #bs.name = "MORSE_#{bs.name}"
#  #bs.configure({set_grid_name: :draw_morse}, deep: false)
#  #result << bs
#
#  #bs = given_bs.dup
#  #bs.name = "ANTS_#{bs.name}"
#  #bs.configure({set_grid_name: :draw_ants}, deep: false)
#  #result << bs
#
#  result
#}

have_configured_versions = -> given_bs {
  result = []

  unless $ABS_config
    return [given_bs]
  end

  $ABS_config.each { |name, hash|
    bs = given_bs.dup
    bs.name = name
    bg = hash['bg']
    bs.configure({set_grid_name: "draw_#{bg}"}, deep: false) if bg
    bs.configure({ items: hash['items'] }, deep: false) if hash['items']
    result << bs
  }

  result
}

result = [BS.dup]
#result = result.map(&have_grid_versions).flatten
#result = result.map(&have_hand_versions).flatten
result = result.map(&have_configured_versions).flatten
$configs_loaded = result
