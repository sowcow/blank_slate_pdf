$noto = File.expand_path './fonts/Noto_Sans_Symbols/static/NotoSansSymbols-Medium.ttf'
$noto_semibold = $noto.sub('Medium', 'SemiBold')

# used for calendar:
$roboto = File.expand_path './fonts/Roboto/Roboto-Regular.ttf'
$roboto_light = File.expand_path './fonts/Roboto/Roboto-Light.ttf'
#$roboto_thin = File.expand_path './fonts/Roboto/Roboto-Thin.ttf'
$roboto_bold = File.expand_path './fonts/Roboto/Roboto-Bold.ttf'


# square link annotations in grids so that it is inside of borders in case there are any
# for less annoying flash on click
class Array
  # annotation coordinates
  def margin n = R(2.5)
    (x, y, xx, yy) = self
    [x + n, y - n, xx - n, yy + n]
  end
end


module DetailsRendering
  def go_last_page
    pdf.go_to_page pdf.page_count
  end

  def revisit_page page, &block
    throw unless page.page_number
    pdf.go_to_page page.page_number
    instance_eval &block
    go_last_page
  end

  def pdf_width
    pdf.page.dimensions[2] - pdf.page.dimensions[0]
  end

  def pdf_height
    pdf.page.dimensions[3] - pdf.page.dimensions[1]
  end

  def step_x
    pdf_width / grid_x
  end

  def step_y
    pdf_height / grid_y
  end

  def color given, given2=given, &block
    prev1 = pdf.fill_color
    prev2 = pdf.stroke_color

    pdf.fill_color given
    pdf.stroke_color given2

    instance_eval &block

    pdf.fill_color prev1 if prev1
    pdf.stroke_color prev2 if prev2
  end

  def font given, &block
    prev = pdf.font
    pdf.font given

    instance_eval &block

    pdf.font prev if prev rescue nil # annoying
  end

  def font_size given, &block
    prev = pdf.font_size
    pdf.font_size given

    instance_eval &block

    pdf.font_size prev if prev
  end

  def draw_grid *a
    if respond_to? :grid
      public_send "draw_#{grid.name}", *a
    else
      draw_dots *a
    end
  end

  def draw_ants
    dot_size = 1
    dot_color = ?0*6

    sum = -> v1, v2 {
      [v1[0] + v2[0], v1[1] + v2[1]]
    }

    half_size = dot_size / 2.0

    color dot_color do
      (0..grid.x).each { |x|
        (0..grid.y).each { |y|
          (xx, yy) = grid.at(x, y, corner: 0)

          #division = 3
          #division = 5
          division = 9

          ratios = division.times.map { |i|
            1 / (division + 1).to_f * (i + 1)
          }

          x2 = nil
          y2 = nil
          ratios.each { |ratio|
            (x2, y2) = grid.at(x, y, corner: ratio)
            pdf.fill_rectangle sum.([x2, yy], [-half_size,half_size]), dot_size, dot_size unless x == grid.x
            pdf.fill_rectangle sum.([xx, y2], [-half_size,half_size]), dot_size, dot_size unless y == grid.y
          }

          #color ?8*6 do
          #  pdf.line [x2 - r, yy], [x2 + r, yy] unless x == grid.x
          #  pdf.line [xx, y2 - r], [xx, y2 + r] unless y == grid.y
          #  pdf.stroke
          #end

          pdf.fill_rectangle sum.([xx, yy], [-half_size,half_size]), dot_size, dot_size
        }
      }
    end
  end

  def draw_waves; draw_lines end
  def draw_lines
    dot_size = 1
    dot_color = ?0*6

    sum = -> v1, v2 {
      [v1[0] + v2[0], v1[1] + v2[1]]
    }

    half_size = dot_size / 2.0

    color dot_color do
      (0..grid.y).each { |y|

        x0 = grid.by_x.at 0
        x1 = grid.by_x.at grid.x
        y0 = grid.by_y.at y, corner: 0

        pdf.line_width 0.5
        color ?C*6 do
          pdf.line [x0, y0], [x1, y0]
          pdf.stroke
        end
      }
    end
  end

  def draw_bamboo
    dot_size = 1
    dot_color = ?0*6

    sum = -> v1, v2 {
      [v1[0] + v2[0], v1[1] + v2[1]]
    }

    half_size = dot_size / 2.0

    color dot_color do
      (0..grid.y).each { |y|

        x0 = grid.by_x.at 0
        x1 = grid.by_x.at grid.x
        y0 = grid.by_y.at y, corner: 0

        pdf.line_width 0.5
        color ?C*6 do
          pdf.line [x0, y0], [x1, y0]
          pdf.stroke
        end

        (0..grid.x).each { |x|
          (xx, yy) = grid.at(x, y, corner: 0)
          (x2, y2) = grid.at(x, y, corner: 0.5)

          pdf.fill_rectangle sum.([xx, yy], [-half_size,half_size]), dot_size, dot_size
        }
      }
    end
  end

  def draw_morse
    dot_size = 1
    dot_color = ?0*6

    sum = -> v1, v2 {
      [v1[0] + v2[0], v1[1] + v2[1]]
    }

    half_size = dot_size / 2.0

    color dot_color do
      (0..grid.x).each { |x|
        (0..grid.y).each { |y|
          (xx, yy) = grid.at(x, y, corner: 0)
          (x2, y2) = grid.at(x, y, corner: 0.5)

          #r = step_x * 0.1
          #r = grid.by_y.step * 0.4
          r = grid.by_y.step * 0.382 / 2

          color ?8*6 do
            pdf.line [x2 - r, yy], [x2 + r, yy] unless x == grid.x
            #pdf.line [xx, y2 - r], [xx, y2 + r] unless y == grid.y
            pdf.stroke
          end
          pdf.fill_rectangle sum.([xx, yy], [-half_size,half_size]), dot_size, dot_size
        }
      }
    end
  end

  def draw_stars except: :borders
    if except == :borders
      except = []
    end

    dot_size = 1
    dot_color = ?0*6

    sum = -> v1, v2 {
      [v1[0] + v2[0], v1[1] + v2[1]]
    }

    half_size = dot_size / 2.0

    color dot_color do
      (0..grid.x).each { |x|
        (0..grid.y).each { |y|
          given = { x: x, y: y }
          next if except.any? { |rule|
            rule.all? { |k, v|
              v === given[k]
            }
          }
          case
          when x % 3 == grid.dx && y % 3 == grid.dy
            cross [x, y]
          else
            pdf.fill_rectangle sum.(grid.at(x, y), [-half_size,half_size]), dot_size, dot_size
          end
        }
      }
    end
  end

  def draw_sand; draw_dots end
  def draw_dots except: :borders
    if except == :borders
      except = []
    end

    dot_size = 1
    dot_color = ?0*6

    sum = -> v1, v2 {
      [v1[0] + v2[0], v1[1] + v2[1]]
    }

    half_size = dot_size / 2.0

    color dot_color do
      (0..grid_x).each { |x|
        (0..grid_y).each { |y|
          given = { x: x, y: y }
          next if except.any? { |rule|
            rule.all? { |k, v|
              v === given[k]
            }
          }
          pdf.fill_rectangle sum.(grid.at(x, y), [-half_size,half_size]), dot_size, dot_size
        }
      }
    end
  end

  # when you use for already existing pages... probably I need to turn link -> link_page do
  def link! given, another_page
    square = to_rect given

    pdf.link_annotation(
      square.to_a,
      #square.margin,
      :Dest => another_page.id,
      :Border => [0,0,$debug ? 1 : 0],
    )
  end

  def link_page given, &block
    child = page &block
    link given, child
    child
  end

  def to_rect given
    if given.count == 2
      grid.rect *(given.take(2) + given.take(2))
    else
      grid.rect *given.take(4)
    end
  end

  def link given, child
    square = to_rect given

    revisit_page child.parent do
      pdf.link_annotation(
        square.to_a, #margin,
        :Dest => child.id,
        :Border => [0,0,$debug ? 1 : 0],
      )
    end
  end

  def link_back
    current = page_stack.last
    page = current.parent

    text = ?↑

    at = hand == RIGHT ? [pdf_width - step_x, pdf_height] : [0, pdf_height]

    text_at = at.clone
    text_at[1] += R(20) # manual centering

    color ?8*6 do
      font $noto_semibold do
        font_size step_y - R(60) do
          pdf.text_box text, at: text_at, width: step_x, height: step_y, align: :center, valign: :center
        end
      end
    end

    omg_step_y = step_x
    rect = [at[0], at[1], at[0] + step_x, at[1] - omg_step_y] #.margin

    pdf.link_annotation(
      rect.to_a,
      :Dest => page.id,
      :Border => [0,0,$debug ? 1 : 0],
    )
  end

  # link back, specifically positioned to mirror (18 grid cell position but at the corner)
  def link_back_page_corner_18 target=page_stack.last&.parent
    return unless target
    text = ?↑
    dx = grid.by_x.step
    dy = grid.by_y.step

    link_cell_side = Grid.new.apply(pdf_width, pdf_height).by_x.step
    link_cell = hand == RIGHT ? [pdf_width - link_cell_side, pdf_height] : [0, pdf_height]
    text_cell = hand == RIGHT ? [pdf_width - dx, pdf_height] : [0, pdf_height]

    text_at = text_cell.clone
    text_at[1] += R(15) # manual centering
    color ?8*6 do
      font $noto_semibold do
        font_size step_y - R(60) do # ...
          pdf.text_box text, at: text_at, width: dx, height: dy, align: :center, valign: :center
        end
      end
    end

    at = link_cell
    rect = [at[0], at[1], at[0] + link_cell_side, at[1] - link_cell_side] #.margin
    pdf.link_annotation(
      rect.to_a,
      :Dest => target.id,
      :Border => [0,0,$debug ? 1 : 0],
    )
  end

  def diamond at, corner: 0
    (x, y) = grid.at(*at, corner: corner)
    r = step_x * 0.1

    color ?8*6 do
      pdf.stroke_polygon [x - r, y], [x, y + r], [x + r, y], [x, y - r]
    end
  end

  def cross at, corner: 0
    (x, y) = grid.at(*at, corner: corner)
    r = step_x * 0.1

    color ?8*6 do
      pdf.line [x - r, y], [x + r, y]
      pdf.line [x, y - r], [x, y + r]
      pdf.stroke
    end
  end

  # second order
  def mark2 at, corner: 0
    (x, y) = grid.at(*at, corner: corner)
    r = step_x * 0.1

    color ?8*6 do
      pdf.line [x, y - r], [x, y + r]
      pdf.stroke
    end
  end

  def fat_dot at
    x = at[0] * step_x + step_x / 2.0
    y = at[1] * step_y + step_y / 2.0
    r = step_x * 0.05

    color ?8*6 do
      pdf.fill_circle [x, y], r
    end
  end

  def draw_line x1, y1, x2, y2
    (x1, y1) = grid.at(x1, y1)
    (x2, y2) = grid.at(x2, y2)

    # no default color - may print white?
    pdf.line [x1, y1], [x2, y2]
    pdf.stroke
  end

  def draw_text text, x, y, width: nil, height: step_y, **other
    (x, y) = grid.at(x, y + 1) # no idea about this +1
    at = [x, y]

    # no default color - may print white?
    #pdf.font_size (size - R(10)) * 0.5

    width = pdf_width - at[0] unless width
    pdf.text_box text, at: at, width: width, height: height, **other
  end

  def reserved? x, y
    return true if x == 0 && y == grid_y-1 && device == RM && hand == RIGHT # blind spot because of round "show toolbar" button
    return true if x == 0 && y == grid_y-1 && device == RM && hand == LEFT && page_number > 1 # back button is there
    return true if x == grid_x-1 && y == grid_y-1 && device == RM && hand == RIGHT && page_number > 1 # back button
  end
end
