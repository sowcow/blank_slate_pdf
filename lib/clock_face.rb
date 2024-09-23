module ClockFace
  module_function

  def positions
    size = 3
    up = 16 - size # fucking axis shift

    # 4x4 grid
    get_x = -> i {
      (i % 4)
    }
    get_y = -> i {
      (i / 4)
    }

    # 7 - day start, 18 - day end, turning page in hours view further goes to another day
    hour_positions = [
      { grid_index: 12, hour: 7 },
      { grid_index: 8, hour: 8 },
      { grid_index: 4, hour: 9 },
      { grid_index: 0, hour: 10 },
      { grid_index: 1, hour: 11 },
      { grid_index: 2, hour: 12 },
      { grid_index: 3, hour: 1 },
      { grid_index: 7, hour: 2 },
      { grid_index: 11, hour: 3 },
      { grid_index: 15, hour: 4 },
      { grid_index: 14, hour: 5 },
      { grid_index: 13, hour: 6 },
    ]

    hour_positions.each { |x|
      i = x[:grid_index]
      x[:area] = There.at([get_x[i]*size, up - get_y[i]*size, size, size]) # fucking axis normalization
    }
    hour_positions
  end

  def numeration
    @numeration ||= Hash[
      NUMBERS.scan(/\S+/).map.with_index { |x, i|
        [i+1, x]
      }
    ]
  end

  # use center + size as params?
  def render_clock_face
    #  b|c
    #  -+-
    #  a|d
    #
    # ↑ coordinates of central points around "focus crosshair" + shifts in directions l,r,u,dn to get 12 hour positions

    # just manually aligned numbers
    a = At[6 - 0.25, 10 - 0.25 - 0.08]
    b = a.up(0.5)
    c = b.right(0.5)
    d = c.down(0.5)

    step = 3 - 0.05
    l = At[-step, 0]
    r = At[step, 0]
    u = At[0, step]
    dn = At[0, -step]

    have = -> at, text {
      text = numeration[Integer text] || text

      # x *= 0.5
      # y *= 0.5

      # at = Pos[x, y].up 0.5
      # pos = $bs.g.at at

      # size = $bs.g.xs.step*0.5

      $bs.color ?a do
      $bs.font $ao do
        $bs.font_size 8 do
          # p 11, text
          # $bs.put_text at, text, adjust: 0.77
          $bs.put_text at, text
        end
      end
      # $bs.omg_text_at pos, text, centering: 0.25, size: size, align: :center,
      #   font_is: $ao, size2: size * 0.6
      end
    }

    have.call a+l, ?8
    have.call a+dn, ?6
    have.call a+l+dn, ?7

    have.call b+l, ?9
    have.call b+l+u, '10'
    have.call b+u, '11'

    have.call c+u, '12'
    have.call c+u+r, ?1
    have.call c+r, ?2

    have.call d+r, ?3
    have.call d+r+dn, ?4
    have.call d+dn, ?5
  end
  # NUMBERS = 'Ⅰ	Ⅱ 	Ⅲ 	Ⅳ 	Ⅴ 	Ⅵ 	Ⅶ 	Ⅷ 	Ⅸ 	Ⅹ 	Ⅺ 	Ⅻ'
  NUMBERS = 'Ⅰ	Ⅱ 	Ⅲ 	ⅠⅠⅠⅠ 	Ⅴ 	Ⅵ 	Ⅶ 	Ⅷ 	Ⅸ 	Ⅹ 	Ⅺ 	Ⅻ'
end

if __FILE__ == $0
  p ClockFace.numeration
end

#Ⅰ	Ⅱ 	Ⅲ 	Ⅳ 	Ⅴ 	Ⅵ 	Ⅶ 	Ⅷ 	Ⅸ 	Ⅹ 	Ⅺ 	Ⅻ
#Ⅰ	Ⅱ 	Ⅲ 	ⅠⅠⅠⅠ 	Ⅴ 	Ⅵ 	Ⅶ 	Ⅷ 	Ⅸ 	Ⅹ 	Ⅺ 	Ⅻ
__END__
Ⅰ	Ⅱ 	Ⅲ 	Ⅳ 	Ⅴ 	Ⅵ 	Ⅶ 	Ⅷ 	Ⅸ 	Ⅹ 	Ⅺ 	Ⅻ
