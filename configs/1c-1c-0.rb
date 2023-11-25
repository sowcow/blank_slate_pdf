$config_loaded = BlankSlatePDF.new('1c-1c-0') do
  configure $setup

  description <<-END
    Two levels of lists and a level of just blank pages.
    ---
    Necessary when using with Remarkable: #{hand} hand mode and closed toolbar.
    Otherwise links/navigation controls in the pdf overlap controls in RM.
    There are breadcrumbs left at the place of links in part to visualize page ordering.
  END

  page do
    draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]

    grid_y.times.reverse_each { |y|
      x = 0
      next if reserved? x, y

      link [x, y], page {
        draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
        link_back

        path = [[x, y]]
        cross path[0]

        grid_y.times.reverse_each { |y|
          x = 0
          next if reserved? x, y

          link [x, y], page {
            draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
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
