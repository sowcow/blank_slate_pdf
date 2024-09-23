class WeekFormat
  def initialize which
    case which
    when ?M
      @monday = true
    when ?S
      @monday = false
    else
      throw "week format? #{which}"
    end
  end

  def monday?
    @monday
  end

  def sunday?
    !monday?
  end

  def week_number date
    if monday?
      date.strftime('%W').to_i
    else
      date.strftime('%U').to_i
    end
  end

  def ordering
    if monday?
      [*1..6] << 0  # 0 is Sunday
    else
      [*0..7]
    end
  end
end
