class MonthCalendar
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
