$config_loaded = BlankSlatePDF.new('2c-1c-0') do
  configure $setup

  description <<-END
    Two levels of lists and a level of just blank pages.
    Root level list has two columns.
    ---
    Necessary when using with Remarkable: #{hand} hand mode and closed toolbar.
    Otherwise links/navigation controls in the pdf overlap controls in RM.
    There are breadcrumbs left at the place of links in part to visualize page ordering.
  END

  page do
    color ?0*6 do # color #000000
      draw_line grid_x / 2, 0, grid_x / 2, grid_y
    end
    draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }, { x: grid_x / 2 }]

    [0, grid_x / 2].each { |x|
      grid_y.times.reverse_each { |y|
        next if reserved? x, y

        link [x, y], page {
          draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
          link_back

          path = [[x, y]]
          cross path[0]

          grid_y.times.reverse_each { |y|
            x2 = 0
            next if reserved? x2, y

            link [x2, y], page {
              draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
              link_back

              path2 = [*path, [x2, y]]
              cross path2[0]
              diamond path2[1]
            }
          }
        }
      }
    }
  end

  render_file
end
