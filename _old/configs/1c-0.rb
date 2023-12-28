$config_loaded = BlankSlatePDF.new('1c-0') do
  configure $setup

  description <<-END
    Root page has one column of square "invisible" links at the left side.
    Every link leads to just a plain page with no further links.
    ---
    Necessary when using with Remarkable: #{hand} hand mode and closed toolbar.
    Otherwise links/navigation controls in the pdf overlap controls in RM.
    There are breadcrumbs left at the place of links in part to visualize page ordering.
  END

  page do
    draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }] # except at page boundaries

    # Some things are configured in `run.rb`
    # grid_y = 16  # 16 rows in portrait mode

    # reverse_each for page ordering since y=0 means bottom row in prawn/pdf
    grid_y.times.reverse_each { |y|
      x = 0 # leftmost column
      next if reserved? x, y # avoids unreachable links

      link [x, y], page {
        draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
        link_back

        path = [[x, y]]
        diamond path[0]
      }
    }
  end

  render_file
end
