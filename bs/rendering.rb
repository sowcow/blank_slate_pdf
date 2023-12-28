require_relative 'fonts'

module Rendering
  #def with color: nil, font: nil, font_size: nil, line_width: nil
  #  #
  #end
  # could override "local" stuff in methods?
  # store priority and on nesting increment it
  # non-nested way too?

  def polygon *a, **aa, &b
    pdf.stroke_polygon *a, **aa, &b
  end

  def link_back
    text = ?↑
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
      link rect, page.parent, raw: true
    }
  end
  
  def link! *a
    @debug_link = true
    link *a
    @debug_link = false
  end

  # could use At / Pos to differentiate instead of raw
  def link given, target, raw: false
    given = given.to_a
    given = given.count == 2 ? given+given : given
    square = grid.rect *given

    square = given if raw

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

  def diamond at, corner: 0
    (x, y) = grid.at(*at, corner: corner)
    r = grid.xs.step * 0.1

    color 8 do
      pdf.stroke_polygon [x - r, y], [x, y + r], [x + r, y], [x, y - r]
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

  def draw_dots border: false
    xs = g.tl.select_right(grid.w + 1).map &:x
    ys = g.bl.select_up(grid.h + 1).map &:y

    positions = []
    xs.each { |x|
      ys.each { |y|
        positions << Pos[x, y]
      }
    }

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

  def draw_lines
    color 0 do
      (0..grid.h).each { |y|

        x0 = grid.xs.at 0
        x1 = grid.xs.at grid.x
        y0 = grid.ys.at y, corner: 0

        line_width 0.5 do
          color ?c do
            pdf.line [x0, y0], [x1, y0]
            pdf.stroke
          end
        end
      }
    end
  end

  def line_width given=1, &block
    prev = pdf.line_width
    pdf.line_width given

    instance_eval &block

    pdf.line_width prev if prev
  end
end
