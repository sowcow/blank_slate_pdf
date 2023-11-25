require 'date'


$config_loaded = BlankSlatePDF.new('month-day-1c-0') do
  configure $setup

  description <<-END
    Months -> Days -> list at the left -> plain pages.
    List pages here are smaller, only having five items/additional pages
    that are positioned at the top five cells at the left side.
    Topmost cell is ignored due to RM not having it accessible anyway.
    ---
    Necessary when using with Remarkable: #{hand} hand mode and closed toolbar.
    Otherwise links/navigation controls in the pdf overlap controls in RM.
    There are breadcrumbs left at the place of links in part to visualize page ordering.
  END

  v_line = -> x { draw_line x, 0, x, grid_y }
  h_line = -> y { draw_line 0, y, grid_x, y }

  cell_size = 4
  year_grid = []
  4.times.map { |y|
    3.times.map { |x|
      index = x + y * 3
      date = Date.new calendar_year, index+1, 1
      year_grid << { index: index, x: x, y: 3 - y, date: date }
    }
  }

  year_layout = -> _ {
    color ?8*6 do
      v_line.call grid_x / 3
      v_line.call grid_x / 3 * 2

      h_line.call grid_y / 4
      h_line.call grid_y / 4 * 2
      h_line.call grid_y / 4 * 3
    end

    year_grid.each { |cell|
      date = cell.fetch :date
      x = cell.fetch :x
      y = cell.fetch :y
      month_name = date.strftime '  %B'

      text = date.month == 1 ? month_name + " #{date.year}" : month_name
      color ?8*6 do
        font_size step_y * 0.5 do
          font $roboto do
            draw_text text, x*cell_size, y*cell_size, valign: :center
          end
        end
      end
    }
  }

  make_month_grid = -> date {
    grid = [[]]
    d = Date.new date.year, date.month, 1
    loop {
      grid << [] if d.public_send(week_start.to_s.downcase + ??)
      grid.last << d

      d += 1
      break if d.month != date.month
    }
    grid.shift if grid.first == [] # monday starting week

    empty_cells = 7 - grid[0].count
    empty_cells.times {
      grid[0].unshift nil
    }

    def grid.cell_size; 2 end  # oh, no!

    grid
  }

  page do
    instance_eval &year_layout

    year_grid.each { |cell|
      date = cell.fetch :date
      x = cell.fetch :x
      y = cell.fetch :y
      month_name = date.strftime '%B'

      link [x*cell_size, y*cell_size, (x+1)*cell_size, (y+1)*cell_size], page {
        #draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
        link_back

        color ?8*6 do
          font_size step_y * 0.5 do
            font $roboto do
              draw_text month_name, 1, grid_y-1, valign: :center
            end
          end
        end

        y_shift = -3 # manual adjustment, y direction gets inversed first (just ignore this)
        grid = make_month_grid[date]
        cells = []
        grid.each_with_index { |days, i|
          days.each_with_index { |date, j|
            next unless date

            x = i * grid.cell_size
            y = (j * grid.cell_size)

            y = grid_y - y
            y += y_shift

            color ?8*6 do
              draw_text date.day.to_s, x + 0.2, y - 0.5
            end

            at = [x, y]

            x *= step_x
            y *= step_y
            side = grid.cell_size * step_x
            color ?8*6 do
              pdf.stroke_rectangle [x, y+side], side, side
            end

            cells << { date: date, at: at }
          }
        }

        cells.each { |cell|
          date = cell.fetch :date
          at = cell.fetch :at

          square = [at[0], at[1],
                    at[0] + grid.cell_size,
                    at[1] + grid.cell_size]

          link square, page {
            draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
            link_back

            text = date.strftime '%A, %B %e, %Y'
            color ?8*6 do
              font_size step_y * 0.5 do
                font $roboto do
                  draw_text text, 1, grid_y-1, valign: :center
                end
              end
            end

            # only five items or additional pages per day
            5.times.each { |dy|
              y = grid_y - dy - 2 # minus resered cell
              x = 0
              next if reserved? x, y

              link [x, y], page {
                draw_dots except: [{ x: 0 }, { x: 12 }, { y: 0 }, { y: 16 }]
                link_back

                color ?8*6 do
                  font_size step_y * 0.5 do
                    font $roboto do
                      draw_text text, 1, grid_y-1, valign: :center
                    end
                  end
                end

                diamond [x, y]
              }
            }
          }
        }
      }
    }
  end

  render_file
end
