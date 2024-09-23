require 'date'
require_relative 'bs/all'
END { Sundays.make name: 'Sundays_L12' } if __FILE__ == $0

# - [ ] double border on weekends

# a bit more chaotic file while keeping similar structuring of more organized and commented Lists_L12.rb

module Sundays
  YEAR = 2024

  module_function

  def make **params
    setup **params

    generate_root
    generate_months
    generate_weeks
    generate_days

    integrate_root
    integrate_month

    BS::Info.generate
    BS.generate
  end

  def setup name:, format: :L12
    @name = name

    path = File.join __dir__, 'output'

    reformat_page format
    BS.setup name: name, path: path, description: <<-END
      Sundays_L12.pdf

      NOTE: They don't use Sunday-week calendars in my location but there may be a point in using this format still.

      Sunday weeks calendar + notes page per day.
      It is made for landscape forced + split 1/2 mode in RM (that requires rm-hacks currently).

      Notably navigation from month overview can be made only to weeks.
      The point is in using the week page more.
      Interesting feature of those week pages in Sunday-weeks mode is that weekend days wrap weekdays.
      This adds plan-review functionality without special pages or separate space.

      Author: Alexander K.
      Project: https://github.com/sowcow/blank_slate_pdf
    END
    BS.grid format
  end

  def generate_root
    xx = self
    BS.page :root do
      page.tag = 'Sundays.pdf'
      xx.year_months_grid.render_lines
    end
  end

  def generate_months
    xx = self
    root.visit do
      xx.year_months_grid.link_rects.each_with_index { |rect, i|
        mnum = i+1
        d = Date.new YEAR, mnum, 1

        page.child_page :month, rect: rect, month: d, mnum: mnum do
          link_back
          xx.header d.strftime('%B')
        end
      } 
    end
  end
  
  # all Sundays in that start weeks that cover the year
  def get_weeks
    start = Date.new YEAR, 1, 1
    finish = Date.new(YEAR+1, 1, 1) - 1

    weeks = {}
    d = start
    while d <= finish
      week = d.strftime '%U'
      weeks[week] = d unless weeks[week]
      d += 1
    end
    while weeks['00'].wday > 0
      weeks['00'] = weeks['00'] - 1
    end
    weeks
  end

  def week_grid
    one = BS::LinesGrid.new
    one.ys *8.times.map { |x| x * 1.5 + 0.5 }
    one.xs 0, 1.5
    one.x_range 0, $bs.g.w
    one
  end

  def generate_weeks
    xx = self
    get_weeks.each { |wnum, sunday| # not exactly "...num"
      days = 7.times.map { |i| sunday + i }
      mnum = days.find { |x| x.year == YEAR }.month
      parent = BS.xs(:month).find { |x| x[:month].month == mnum }
      mname = Date.new(YEAR, mnum, 1).strftime '%B'
      all_mnums = days.select { |x| x.year == YEAR }.map(&:month).uniq
      parent.child_page :week, days: days, wnum: wnum, mnum: mnum, all_mnums: all_mnums do |pg|
        r1 = xx.week_grid.rects.first
        r2 = xx.week_grid.rects.last
        [r1, r2].each { |rect|
          (a, c) = rect
          color ?e do
            fill_poly *a.corners_with(c).map { |x| g.at x }
          end
        }

        link_back

        xx.header %'#{mname} w#{wnum}'
        xx.week_grid.render_lines
      end
    }
  end

  def use_font &block
    $bs.font $roboto_light do
    $bs.color ?4, &block
    end
  end

  def header text
    use_font do
      $bs.put_text At[4, 11.5], text, adjust: 0.77
    end
  end

  def generate_days
    xx = self
    BS.xs(:week).visit {
      days = page[:days]
      days.each { |d|
        wday = d.wday
        dy = $bs.g.h - 1 - wday * 1.5 - 1.5

        # longer way to construct a rect
        one = BS::LinesGrid.new
        one.ys 0 + dy, 1.5 + dy
        one.xs 0, 1.5
        rect = one.link_rects.first

        text = d.strftime '%a. %Y-%m-%d'

        child = page.child_page :day, day: d do
          link_back
          xx.day_grid.render_lines
          xx.header text
          xx.render_clock_face
        end
        page.child_page :notes do
          link_back
          xx.notes_grid.render_lines
          xx.header text
        end

        rect = rect.map(&:to_a).flatten
        link rect, child

        font $roboto_light do
        color ?4 do
          margin = 0.07
          # x: 0..1 is align left..right
          put_text At[*rect.take(2)].right(0 + margin).up(0.15), d.strftime('%a.'), x: 0
          put_text At[*rect.take(2)].right(1.5 - margin).up(0.15), d.strftime('%d'), x: 1
        end
        end
      }
    }
  end

  def integrate_month
    # it is all about grid cell sizes
    size = 1.5
    margin = 0.07
    get_width = -> week_index, count {
      case
      when count == 6 && week_index == 0
        1
      when count == 6 && week_index == 5
        1
      else
        1.5
      end
    }

    shrink = -> ((a,b,c,d)) {
      [
        a.down(margin),
        b.down(margin),
        c.up(margin),
        d.up(margin),
      ]
    }

    xx = self
    BS.xs(:month).visit do
      xs = []
      ys = []
      weeks = BS.xs(:week).select { |x| x[:all_mnums].include? page[:mnum] }
      weeks.each_with_index { |week, i|
        width_size = get_width.call i, weeks.count
        x_coord = i.times.map { |ii| get_width.call ii, weeks.count }.reduce(0, :+)
        get_y = -> j { g.h - 1 - j * size }
        week[:days].each_with_index { |d, j|
          at = At[x_coord, get_y[j]]
          line_width 0.5 do
          color ?a do
            if [0,6].include? j
              color ?e do
                fill_poly *at.corners(width_size, size).map { |x| g.at x }
              end
            end
            poly *at.corners(width_size, size).map { |x| g.at x }
          end
          end
          xx.use_font do
            c = 4
            if d.month != page[:mnum]
              c = ?a
            end
            color c do
              put_text at.right(width_size).down(size).up(margin).left(margin), d.day.to_s, x: 1, y: 0
            end
          end
        }
        a = At[x_coord, get_y[0]]
        b = At[x_coord, get_y[7]].down(1).right(width_size - 1)
        rect = [a, b].map(&:to_a).flatten
        link rect, week
      }
    end
  end

  def integrate_root
    xx = self
    root.visit do
      BS.xs(:month).each { |pg|
        rect = pg[:rect]
        rect = rect.map(&:to_a).flatten
        link rect, pg

        d = pg[:month]
        text = d.strftime('%B')
        text = YEAR.to_s if d.month == 1
        xx.use_font do
          # text_at pg[:rect].first, text
          margin = 0.07
          $bs.put_text pg[:rect].last.down(1).right(1).up(margin).left(margin), text, x: 1, y: 0
        end
      }
    end
  end

  # UI

  def render_clock_face
    #  b|c
    #  -+-
    #  a|d
    #
    # ↑ coordinates of central points around "focus crosshair" + shifts in directions l,r,u,dn to get 12 hour positions

    a = At[7.5 * 0.5, 13.5 * 0.5]
    b = a.up(0.5)
    c = b.right(0.5)
    d = c.down(0.5)

    step = 2
    l = At[-step, 0]
    r = At[step, 0]
    u = At[0, step]
    dn = At[0, -step]

    number_mapping = {
    }
    num_i = 1
    'Ⅰ	Ⅱ 	Ⅲ 	Ⅳ 	Ⅴ 	Ⅵ 	Ⅶ 	Ⅷ 	Ⅸ 	Ⅹ 	Ⅺ 	Ⅻ'.chars.each { |c|
      next if c =~ /\s/
      number_mapping[num_i.to_s] = c
      num_i += 1
    }
    have = -> at, text {
      text = number_mapping[text] || text

      # x *= 0.5
      # y *= 0.5

      # at = Pos[x, y].up 0.5
      pos = $bs.g.at at

      # size = $bs.g.xs.step*0.5

      $bs.color ?4 do
      $bs.font $ao do
        $bs.font_size 8 do
          $bs.put_text at, text, adjust: 0.77
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
  
  def notes_grid
    one = BS::LinesGrid.new
    one.ys *11.times.flat_map { |x| [x, x + 0.5] }.map { |x| x + 0.5 }
    one.x_range 0, $bs.g.w
    one
  end

  def day_grid
    it = BS::Group.new

    style = -> x { x.width = 1; x.color = ?4; x }

    one = BS::LinesGrid.new
    one.ys 0.5, 1, 1.5, 2, 2.5
    one.x_range 0, $bs.g.w
    it.push one

    one = BS::LinesGrid.new
    one.xs *9.times.flat_map { |x| [x, x + 0.5] }.map { |x| x + 0.5 }
    one.ys *8.times.flat_map { |x| [x, x + 0.5] }.map { |x| x + 0.5 + 3 }
    one.x_range 0, 12
    one.y_range 3, 11
    it.push one

    one = BS::LinesGrid.new
    one.ys 11, 9, 7, 5, 3
    one.xs 0, 2
    it.push style.call one

    one = BS::LinesGrid.new
    one.ys 11, 9, 7, 5, 3
    one.xs 6, 8
    it.push style.call one

    one = BS::LinesGrid.new
    one.ys 11, 9
    one.xs 2, 4, 6
    it.push style.call one

    one = BS::LinesGrid.new
    one.ys 5, 3
    one.xs 2, 4, 6
    it.push style.call one

    one = BS::LinesGrid.new
    one.xs 4
    one.ys 4 + 3
    one.x_range 3.5, 4.5
    one.y_range 3.5 + 3, 4.5 + 3
    it.push style.call one

    it
  end

  def year_months_grid
    one = BS::LinesGrid.new
    one.ys *(6+1).times.map { |x| x * 2 }
    one.xs 0, 4, 8
    one
  end

  # helpers

  def root
    BS.pages.first
  end
end
