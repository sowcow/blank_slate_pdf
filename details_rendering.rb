$noto = File.expand_path './fonts/Noto_Sans_Symbols/static/NotoSansSymbols-Medium.ttf'
$noto_semibold = $noto.sub('Medium', 'SemiBold')

# used for calendar:
$roboto = File.expand_path './fonts/Roboto/Roboto-Regular.ttf'
#$roboto_bold = File.expand_path './fonts/Roboto/Roboto-Bold.ttf'


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

  def draw_dots except: []
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
          pdf.fill_rectangle sum.([x * step_x, y * step_y], [-half_size,half_size]), dot_size, dot_size
        }
      }
    end
  end

  def link given, child
    at = [given[0] * step_x, given[1] * step_y]

    square = if given.count == 2
        [at[0], at[1] + step_y, at[0] + step_x, at[1]]
      else
        at2 = [given[2] * step_x, given[3] * step_y]
        [at[0], at[1], at2[0], at2[1]]
      end

    revisit_page child.parent do
      pdf.link_annotation(
        square.margin,
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

    rect = [at[0], at[1], at[0] + step_x, at[1] - step_y].margin

    pdf.link_annotation(
      rect,
      :Dest => page.id,
      :Border => [0,0,$debug ? 1 : 0],
    )
  end

  def diamond at
    x = at[0] * step_x + step_x / 2.0
    y = at[1] * step_y + step_y / 2.0
    r = step_x * 0.1

    color ?8*6 do
      pdf.stroke_polygon [x - r, y], [x, y + r], [x + r, y], [x, y - r]
    end
  end

  def cross at
    x = at[0] * step_x + step_x / 2.0
    y = at[1] * step_y + step_y / 2.0
    r = step_x * 0.1

    color ?8*6 do
      pdf.line [x - r, y], [x + r, y]
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
    x1 *= step_x
    x2 *= step_x
    y1 *= step_y
    y2 *= step_y

    # no default color - may print white?
    pdf.line [x1, y1], [x2, y2]
    pdf.stroke
  end

  def draw_text text, x, y, width: nil, height: step_y, **other
    x *= step_x
    y *= step_y
    at = [x, y]

    at[1] += 1 * step_y # right above that corner point

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
