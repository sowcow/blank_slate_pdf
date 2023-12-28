$config_loaded = BlankSlatePDF.new('12c-0') do
  configure $setup

  description <<-END
    Root page is a grid full of links that lead to plain pages.
    ---
    Necessary when using with Remarkable: #{hand} hand mode.
    Otherwise links/navigation controls in the pdf overlap controls in RM.
    There are breadcrumbs left at the place of links in part to visualize page ordering.
  END

  page do
    draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]

    grid_x.times.reverse_each { |x|
      grid_y.times.reverse_each { |y|
        next if reserved? x, y

        link [x, y], page {
          draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
          link_back

          path = [[x, y]]
          diamond path[0]
        }
      }
    }
  end

  render_file
end
