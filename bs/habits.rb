module BS
  module Habits
    extend self

    # month is own object
    def generate parent, month, &block
      g = Positioning.grid_portrait_18_padded $bs.pdf_width, $bs.pdf_height
      parent.child_page :habits do
        instance_eval &block if block
        link_back
        days_count = month.squares.count

        limit_y = g.ys.at(days_count) / 2.0

        # bar
        h = limit_y
        w = g.xs.step / 2.0

        (12).times { |ax|
          axx = ax + 0.5
          x = g.xs.at ax
          xx = g.xs.at axx
          y0 = g.ys.at 0
          y1 = g.ys.at g.h

          if ax.even?
            c = (ax / 12.0 * 255).to_i.to_s(16).rjust(2, ?0) * 3
            color c do
              pdf.fill_rectangle [xx, h], w, h
            end
          end
          color 8 do
            pdf.line x, y0, x, y1
            pdf.line xx, y0, xx, limit_y
            pdf.stroke
          end
        }
        month.squares.reverse.each_with_index { |square, ay|
          ay += 1
          ay = ay / 2.0
          y = g.ys.at ay
          xs = []
          12.times { |i|
            xs << [i, i + 0.5]
          }
          xs.each { |(from, to)|
            x0 = g.xs.at from
            x1 = g.xs.at to
            color 8 do
              pdf.line x0, y, x1, y
              pdf.stroke
            end
          }

          if square.weekday == 0 # Monday
            x0 = g.xs.at 0
            x1 = g.xs.at g.w
            line_width 1.5 do
              color 8 do
                pdf.line x0, y, x1, y
                pdf.stroke
              end
            end
          end
        }
      end
    end

    # for words (not checkmarks):

    def generate2 parent, month, here: nil, &block
      g2 = Positioning.grid_portrait_18_padded $bs.pdf_width, $bs.pdf_height

      gen = proc do
        instance_eval &block if block
        link_back
        days_count = month.squares.count

        limit_y = g.ys.at(days_count) / 2.0

        # bar
        h = limit_y
        w = g.xs.step / 2.0

        (5).times { |ax|
          ax *= 3
          x = g.xs.at ax
          y0 = g.ys.at 0
          y1 = g.ys.at g.h - 1

          pdf.line x, y0, x, y1
        }
        line_width 1 do
        color 8 do
          pdf.stroke
        end
        end

        month.squares.reverse.each_with_index { |square, ay|
          ay += 1
          ay = ay / 2.0
          y = g2.ys.at ay
          xs = []

          x0 = g.xs.at 0
          x1 = g.xs.at g.w

          pdf.line x0, y, x1, y

          line_width 0.5 do
            color ?a do
              pdf.stroke
            end
          end

          step = g2.ys.step * 0.5 * 1
          color ?8 do
            omg_text_at Pos[step * 0.2, y], square.day.to_s, size: step, centering: 0
          end

          #if [0, 5].include? square.weekday # Monday/Weekend
          if [0].include? square.weekday # Monday
            x0 = g.xs.at 0
            x1 = g.xs.at g.w
            line_width 1 do
              color 8 do
                pdf.line x0, y, x1, y
                pdf.stroke
              end
            end
          end
        }
      end

      if here
        here.visit &gen
        here
      else
        parent.child_page :habits, &gen
      end
    end
  end
end

