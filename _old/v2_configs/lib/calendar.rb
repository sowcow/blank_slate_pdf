require 'date'

WEEK_MON = %w[monday tuesday wednesday thursday friday saturday sunday]
WEEK_SUN = %w[sunday monday tuesday wednesday thursday friday saturday]

class MonthCalendar
  def self.for_date year, month, monday: true
    raise "not implemented: sunday weeks" unless monday

    date = Date.new year, month, 1
    day_count = date.next_month.prev_day.day

    week = WEEK_MON
    wday = date.wday == 0 ? 7 : date.wday - 1
    start_weekday = week[wday]

    month_start_weekday = week.index(start_weekday) or raise 'wrong :month_start given for the :week'

    new days: day_count, month_start_weekday: month_start_weekday
  end

  # whether monday or sunday is a start of the week, assume that is 0 in given weekday value here
  def initialize days: 31, month_start_weekday: 0
    @days = days
    @month_start_weekday = month_start_weekday
  end

  # [{ day: 1.., weekday: 0..6, week: 0..}]
  def to_a
    result = []
    weekday = @month_start_weekday
    week = 0
    @days.times { |i|
      entry = {
        day: i + 1,
        weekday: weekday,
        week: week,
      }
      result << entry

      weekday = (weekday + 1) % 7
      week += 1 if weekday == 0
    }
    result
  end
end
