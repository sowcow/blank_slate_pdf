$config_loaded = BlankSlatePDF.new('squares-1c-1c-0') do
  configure $setup

  description <<-END
    Two levels of lists and a level of just blank pages.
    It has some predefined layout structure on nested pages.
    ---
    Necessary when using with Remarkable: #{hand} hand mode and closed toolbar.
    Otherwise links/navigation controls in the pdf overlap controls in RM.
    There are breadcrumbs left at the place of links in part to visualize page ordering.
  END

  simple_layout = -> _ {
    draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
  }

  custom_layout = -> _ {
    color ?0*6 do
      draw_line grid_x / 2, 0, grid_x / 2, 6
      draw_line 0, 6, grid_x, 6
      draw_line 0, 10, grid_x, 10
      draw_line grid_x / 2, grid_y, grid_x / 2, 10

      draw_line 4, 6, 4, 10
      draw_line 8, 6, 8, 10
    end
    draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 },
                       { y: 6 },
                       { y: 10 },
                       { x: grid_x / 2, y: -> y { y <= 6 } },
                       { x: grid_x / 2, y: -> y { y >= 10 } },
                       { x: 4, y: 6..10 },
                       { x: 8, y: 6..10 },
    ]
  }

  page do
    instance_eval &simple_layout

    grid_y.times.reverse_each { |y|
      x = 0
      next if reserved? x, y

      link [x, y], page {
        instance_eval &custom_layout
        link_back

        path = [[x, y]]
        cross path[0]

        grid_y.times.reverse_each { |y|
          x = 0
          next if reserved? x, y

          link [x, y], page {
            instance_eval &custom_layout
            link_back

            path2 = [*path, [x, y]]
            cross path2[0]
            diamond path2[1]
          }
        }
      }
    }
  end

  render_file
end
