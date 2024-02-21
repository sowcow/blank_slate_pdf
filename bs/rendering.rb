require_relative 'fonts'

module Prawn
  module Graphics
    module Patterns
      def create_crosses_pattern r, x, y, w, h, count: 4, thickness: 1.0, key:
        key = "SP#{key}"
        patterns = page.resources[:Pattern] ||= {}
        unless patterns[key]
          dx = w / count.to_f
          dy = dx
          #dy = (h - thickness) / count.to_f

          art_pat= ref!(
            #Type: '/Pattern',
            PatternType: 1,
            PaintType: 1,
            TilingType: 2,
            BBox: [ -10,-10,x+10,y+10 ],
            XStep: dx,
            YStep: dy,
            Matrix: [ 1.0,0.0,0.0,1.0,0.0,0.0 ],
            PatternColors: [1.0, 0.0, 0.0]
          )

          stream= PDF::Core::Stream.new
          stream << "0.53 0.53 0.53 rg"
          stream << " #{x-r} #{y} #{2*r+thickness} #{thickness} re"
          stream << " #{x} #{y-r} #{thickness} #{2*r+thickness} re"
          stream << "\nf"

          art_pat.stream = stream

          patterns[key] = art_pat
        end

        type= :fill
        operator =
          case type
          when :fill
            'scn'
          when :stroke
            'SCN'
          else
            raise ArgumentError, "unknown type '#{type}'"
          end

        set_color_space type, :Pattern
        renderer.add_content "/#{key} #{operator}"
      end

      def create_dotted_pattern x, y, w, h, count: 12, thickness: 1.0, key:
        key = "SP#{key}"
        patterns = page.resources[:Pattern] ||= {}
        unless patterns[key]
          dx = w / count.to_f
          dy = dx
          #dy = (h - thickness) / count.to_f

          art_pat= ref!(
            #Type: '/Pattern',
            PatternType: 1,
            PaintType: 1,
            TilingType: 2,
            BBox: [ -10,-10,x+10,y+10 ],
            XStep: dx,
            YStep: dy,
            Matrix: [ 1.0,0.0,0.0,1.0,0.0,0.0 ]
          )

          stream= PDF::Core::Stream.new
          stream << "#{x} #{y} #{thickness} #{thickness} re"
          stream << "\nf"

          art_pat.stream = stream

          patterns[key] = art_pat
        end

        type= :fill
        operator =
          case type
          when :fill
            'scn'
          when :stroke
            'SCN'
          else
            raise ArgumentError, "unknown type '#{type}'"
          end

        set_color_space type, :Pattern
        renderer.add_content "/#{key} #{operator}"
      end

    end
  end
end


# HSV values in [0..1[
# returns [r, g, b] values from 0 to 255
def hsv_to_rgb(h, s, v)
  h_i = (h*6).to_i
  f = h*6 - h_i
  p = v * (1 - s)
  q = v * (1 - f*s)
  t = v * (1 - (1 - f) * s)
  r, g, b = v, t, p if h_i==0
  r, g, b = q, v, p if h_i==1
  r, g, b = p, v, t if h_i==2
  r, g, b = p, q, v if h_i==3
  r, g, b = t, p, v if h_i==4
  r, g, b = v, p, q if h_i==5

  rgb = [(r*256).to_i, (g*256).to_i, (b*256).to_i]
  hex = rgb.map { |x| x.to_s(16).rjust(2, '0') }.join

  result = hex
  result.define_singleton_method :rgb do rgb end
  result
end

$color_generator_position = 0
def generate_random_color
  golden_ratio_conjugate = 0.618033988749895
  $color_generator_position += golden_ratio_conjugate
  $color_generator_position %= 1
  hsv_to_rgb($color_generator_position, 1, 0.5)
end

module Rendering
  #def with color: nil, font: nil, font_size: nil, line_width: nil
  #  #
  #end
  # could override "local" stuff in methods?
  # store priority and on nesting increment it
  # non-nested way too?

  def polygon *a
    a = a.first if a.size == 1 && a[0].length > 2
    pdf.stroke_polygon *a
  end
  alias poly polygon

  def draw_grid key
    case key
    when ?D then draw_dots
    when ?S then draw_stars
    when ?L then draw_lines
    when ?G then draw_lines cross: true
    when ?B then :noop
    when ?d then draw_dots_compact
    when ?l then draw_lines_compact
    when ?g then draw_lines_compact cross: true
    else
      raise "Unexpected grid to draw: #{key}"
    end
  end

  def fill_poly *a
    a = a.first if a.size == 1 && a[0].length > 2
    pdf.fill_polygon *a
  end

  def link_back
    text = ?↑
    grid = Positioning.grid_portrait_18_padded pdf_width, pdf_height

    dx = grid.xs.step
    dy = grid.ys.step
    bigger_cell = pdf_width / 12

    cells = [
      [pdf_width - dx, pdf_height],
      [0, pdf_height]
    ]

    cells.each_with_index { |text_cell, i|
      link_cell = text_cell
      link_cell_side = dx
      if i == 0
        # this link I actially use, another is a fallback for the left-hand setting that should not be taking space otherwise
        link_cell_side = bigger_cell
        link_cell = [pdf_width - link_cell_side, pdf_height]
      end

      text_at = text_cell.clone
      text_at[1] += R(15) # manual centering
      color 8 do
        font $noto_semibold do
          font_size dy - R(60) do # ...
            pdf.text_box text, at: text_at, width: dx, height: dy, align: :center, valign: :center
          end
        end
      end

      at = link_cell
      rect = [at[0], at[1], at[0] + link_cell_side, at[1] - link_cell_side]
      link rect, page.parent, raw: true, ignore_for_overview_structure: true
    }
  end
  
  def link! *a
    @debug_link = true
    link *a
    @debug_link = false
  end

  # could use At / Pos to differentiate instead of raw
  def link given, target, raw: false, ignore_for_overview_structure: false
    given = given.to_a
    given = given.count == 2 ? given+given : given
    square = grid.rect *given

    square = Rect.new(*given) if raw

    if $colored
      s = Square[*square.margin] # different squares...
      $tag_colors ||= {}
      $tag_colors[target.tag] ||= generate_random_color
      c = $tag_colors[target.tag]
      page.local[:overviews] ||= []
      pdf.transparent 0.5 do
        color c do
          coords = s.points.map &:to_a
          unless page.local[:overviews]&.include? coords
            fill_poly coords
            page.local[:overviews].push coords
            unless ignore_for_overview_structure
              page.local[:links] ||= []
              page.local[:links] << target
            end
          end
        end
      end
    end

    pdf.link_annotation(
      square.to_a,
      :Dest => target.dest_id,
      :Border => [0,0,($debug || @debug_link) ? 1 : 0],
    )
  end

  def to_rect given
    if given.count == 2
      grid.rect *(given.take(2) + given.take(2))
    else
      grid.rect *given.take(4)
    end
  end

  def omg_text_at pos, text, align: nil, size: nil, centering: -0.1, font_is: $roboto_light
    text_at = pos #grid.at *pos.up, corner: 0
    further_at = pos #grid.at *pos.up, corner: 1
    size = grid.xs.step unless size

      font font_is do
        font_size size * 0.8 do
          #pad_x = 0 ~width or pos
          pad_y = 0
          dy = size * centering # manual centering
          text_at[1] += dy # again? because alignment or what?

          width = nil #size-pad_x #...
          case align
          when :left
            width = pdf_width - text_at[0] # full width, no aligning-right/centering then
          when :right
            text_at[0] = 0
            width = further_at[0]
          end

          align = :left if !align

          pdf.text_box text, at: text_at, width: width, height: size-pad_y, align: align, valign: :bottom
          #pdf.text_box text, at: text_at, width: size-pad_x, height: size-pad_y, align: :center, valign: :center
        end
      end
  end

  def text_at pos, text, align: nil, size: nil
    text_at = grid.at *pos.up, corner: 0
    further_at = grid.at *pos.up, corner: 1
    size = grid.xs.step unless size

      font $roboto_light do
        font_size size * 0.8 do
          #pad_x = 0 ~width or pos
          pad_y = 0
          dy = size * -0.1 # manual centering
          text_at[1] += dy # again? because alignment or what?

          width = nil #size-pad_x #...
          case align
          when :left
            width = pdf_width - text_at[0] # full width, no aligning-right/centering then
          when :right
            text_at[0] = 0
            width = further_at[0]
          end

          align = :left if !align

          pdf.text_box text, at: text_at, width: width, height: size-pad_y, align: align, valign: :bottom
          #pdf.text_box text, at: text_at, width: size-pad_x, height: size-pad_y, align: :center, valign: :center
        end
      end
  end

  def asterisk pos
    text_at = grid.at *pos.up, corner: 0
    size = grid.xs.step

    #dot pos
    #dot pos.right
    #dot pos.up
    #dot pos.right.up

    color 8 do
      font $roboto_light do
        font_size size * 0.8 do
          text = ?*
          pad_x = 0
          pad_y = 0
          dy = size * -0.1 # manual centering
          text_at[1] += dy
          pdf.text_box text, at: text_at, width: size-pad_x, height: size-pad_y, align: :center, valign: :center
        end
      end
    end
  end

  def diamond at, corner: 0, fill: false, use_color: 8
    (x, y) = grid.at(*at, corner: corner)
    r = grid.xs.step * 0.1

    color *[*use_color] do
      pdf.stroke_polygon [x - r, y], [x, y + r], [x + r, y], [x, y - r]
      if fill
        pdf.fill_polygon [x - r, y], [x, y + r], [x + r, y], [x, y - r]
      end
    end
  end

  def dot pos, corner: 0
    (x, y) = grid.at(*pos, corner: corner)

    dot_size = 1
    dot_color = 0

    half_size = dot_size / 2.0

    at = Point[x, y]
    at += Point[-half_size, half_size]

    color dot_color do
      pdf.fill_rectangle at.to_a, dot_size, dot_size
    end
  end

  def cross at, corner: 0
    (x, y) = grid.at(*at, corner: corner)
    r = grid.xs.step * 0.1

    color 8 do
      pdf.line [x - r, y], [x + r, y]
      pdf.line [x, y - r], [x, y + r]
      pdf.stroke
    end
  end

  # second order
  def mark2 at, corner: 0
    (x, y) = grid.at(*at, corner: corner)
    r = grid.xs.step * 0.1

    color 8 do
      pdf.line [x, y - r], [x, y + r]
      pdf.stroke
    end
  end

  def color given, given2=given, &block
    process = -> x {
      return x.to_s * 6 if [*(?0..?9), ?a, ?b, ?c, ?d, ?e, ?f].include? x.to_s
      return x
    }
    given = process.call given
    given2 = process.call given2

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

  def draw_lines_compact cross: false, max_y: nil
    if g.h == 16
      return draw_lines cross: cross, step: 2, max_y: max_y
    end
    x0 = g.xs.at 0
    y0 = g.ys.at 0

    grid_16_step = g.ys.at(18) / 15.0 # up to actually be on the corner point, 10x15 is what is left from 16 height grid there
    step = grid_16_step / 2

    xs = []
    ys = []
    (10*2 + 1).times { |ax| # + border
      x = x0 + ax * step
      xs << x
    }
    (15*2 + 1).times { |ay|
      y = y0 + ay * step
      ys << y
    }

    ys.each { |y|
      x0 = grid.xs.at 0
      x1 = grid.xs.at grid.w

      pdf.line [x0, y], [x1, y]
    }

    cross and xs.each { |x|
      y0 = grid.ys.at 0
      y1 = grid.ys.at grid.h

      pdf.line [x, y0], [x, y1]
    }

    line_width 0.5 do
      color ?a do
        pdf.stroke
      end
    end
  end

  def draw_dots_compact max_y: grid.h
    if g.h == 16
      return draw_dots step: 2, max_y: max_y
    end

    x0 = g.xs.at 0
    y0 = g.ys.at 0

    grid_16_step = g.ys.at(18) / 15.0 # up to actually be on the corner point, 10x15 is what is left from 16 height grid there
    step = grid_16_step / 2

    positions = []
    (10*2 + 1).times { |ax| # + border
      (15*2 + 1).times { |ay|
        x = x0 + ax * step
        y = y0 + ay * step
        positions << Pos[x, y]
      }
    }

    dot_size = 1
    dot_color = 0

    shift = dot_size / 2.0

    color dot_color do
      positions.each { |pos|
        #(gx, gy) = grid.at pos
        pdf.fill_rectangle [pos.x - shift, pos.y + shift], dot_size, dot_size
      }
    end
  end


  def draw_dots border: false, max_y: grid.h, step: 1
    xs = g.tl.select_right(grid.w + 1).map &:x
    ys = g.bl.select_up(max_y + 1).map &:y

    if step > 1
      xs = xs.flat_map { |x| step.times.map { |i| x + i * 1/step.to_f } }
      ys = ys.flat_map { |y| step.times.map { |i| y + i * 1/step.to_f } }
    end

    positions = []
    xs.each { |x|
      ys.each { |y|
        positions << Pos[x, y]
      }
    }

    if max_y
      positions.reject! { |pos| pos.y > max_y }
    end

    if border
      xs = [xs.first, xs.last]
      ys = [ys.first, ys.last]
      positions.select! { |pos|
        xs.include?(pos.x) || ys.include?(pos.y)
      }
    end

    dot_size = 1
    dot_color = 0

    shift = dot_size / 2.0

    color dot_color do
      positions.each { |pos|
        (gx, gy) = grid.at pos
        pdf.fill_rectangle [gx - shift, gy + shift], dot_size, dot_size
      }
    end
  end

  def draw_stars dots: true
    dot_size = 1
    dot_color = 0

    sum = -> v1, v2 {
      [v1[0] + v2[0], v1[1] + v2[1]]
    }

    half_size = dot_size / 2.0

    color dot_color do
      (0..grid.x).each { |x|
        (0..grid.y).each { |y|
          given = { x: x, y: y }
          case
          when x % 3 == grid.dx && y % 3 == grid.dy
            cross [x, y]
          else
            dot [x, y] if dots
          end
        }
      }
    end
  end

  def draw_lines cross: false, step: 1, max_y: g.h
    (0..max_y * step).each { |y|
      y /= step.to_f

      x0 = grid.xs.at 0
      x1 = grid.xs.at grid.w
      y0 = grid.ys.at y, corner: 0

      line_width 0.5 do
        color ?a do
          pdf.line [x0, y0], [x1, y0]
          pdf.stroke
        end
      end
    }

    cross and (0..grid.w * step).each { |x|
      x /= step.to_f

      y0 = grid.ys.at 0
      y1 = grid.ys.at max_y
      x0 = grid.xs.at x, corner: 0

      line_width 0.5 do
        color ?a do
          pdf.line [x0, y0], [x0, y1]
          pdf.stroke
        end
      end
    }
  end

  def line_width given=1, &block
    prev = pdf.line_width
    pdf.line_width given

    instance_eval &block

    pdf.line_width prev if prev
  end

  def dots
    g = grid
    x = g.xs.at 0
    y = g.ys.at 0
    w = g.xs.size
    h = g.ys.size

    x -= 0.5
    y -= 0.5

    rect = [
      [x, y+h+1],
      w+1, h+1
    ]
    pdf.create_dotted_pattern x, y, w, h, key: 'dots_pattern'
    pdf.fill_rectangle *rect
  end

  def stars
    dots

    g = grid
    x = g.xs.at 0
    y = g.ys.at 0
    w = g.xs.size #- 0.5
    h = g.ys.size #- 0.5

    x -= 0.5
    y -= 0.5

    r = 2
    rect = [
      #[x, y+h],
      #w, h
      [x-r, y+h+1+r],
      w+1+r*2, h+1+r*2
    ]
    pdf.create_crosses_pattern r, x, y, w, h, key: 'stars_pattern'
    pdf.fill_rectangle *rect
  end
end
