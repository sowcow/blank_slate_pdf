class ColorTable
  def initialize &setup
    @r = range
    @g = range
    @b = range
    instance_eval &setup
  end
  attr_accessor :r, :g, :b

  def generate count:
    ranges = [@r, @g, @b].select { |x| x.is_a? MyRange }

    throw %'only producing 2D tables, not: #{ranges.count}' if ranges.count != 2
    range1 = ranges.first
    range2 = ranges.last

    xs = []

    range1
      .step(255/(count - 1))
      .each_with_index { |v1, i1|
      range2
        .step(255/(count - 1))
        .each_with_index { |v2, i2|

        xs << entry = {}
        entry[:x] = i1
        entry[:y] = i2

        keys = [:r, :g, :b]
        [:r, :g, :b].each { |key|
          if send(key).equal?(range1)
            entry[key] = v1
          elsif send(key).equal?(range2)
            entry[key] = v2
          end
        }
        non_range_keys = keys - entry.keys
        non_range_keys.each { |key|
          setter = send key
          if setter.is_a? Proc
            # dsl purpose
            context = dup
            entry.each_pair { |k,v|
              context.instance_variable_set "@#{k}", v
            }
            entry[key] = context.instance_eval &setter # computable
          else
            entry[key] = setter # value directly
          end
        }
        (r, g, b) = entry.fetch_values :r, :g, :b
        entry[:color] = [r, g, b].map { |x| x.to_s(16).rjust(2, ?0) }.join
      }
    }

    xs
  end

  def name
    result = ''

    %i[r g b].map { |key|
      value = send(key)
      case value
      when MyRange
        "#{key} ~ #{value.inspect}".upcase
      when Proc
        file, line_number = value.source_location
        code_line = File.readlines(file)[line_number - 1].strip

        regex = /.*\{(.+?)\}/
        throw "proc definition should have {...} parens for name generation" unless code_line =~ regex
        value = code_line[regex, 1].strip
        "#{key} = #{value}".upcase
      else
        "#{key} = #{send(key).to_s(16).rjust(2, ?0).inspect}".upcase
      end
    }.join ', '
  end

  private

  require 'delegate'

  class MyRange < SimpleDelegator
    attr_accessor :id
  end

  def range
    value = MyRange.new 0..255

    @next_id ||= 0
    value.id = @next_id += 1

    value
  end

  def max
    range.max
  end

  # 9 options of coloring, allowing 2*2*2 more options of laying them out in 2D space
  # (other options:)
  # - swap x and y
  # - swap x direction left/right
  # - swap y direction left/right
  def self.setup_options
    xs = []
    %w[r g b].each { |which1|
      xs << proc { |x| x.send "#{which1}=", max }
    }
    %w[r g b].combination(2).each { |which1, which2|
      xs << proc { |x| x.send "#{which1}=", -> _ { send(which2) } }
    }
    %w[r g b].combination(2).each { |which1, which2|
      xs << proc { |x| x.send "#{which1}=", -> _ { max - send(which2) } }
    }
    xs
  end
end

if __FILE__ == $0
  subj = ColorTable.new { |x| x.r = max }
  got = subj.generate count: 3
  p subj.name

  subj = ColorTable.new { |x| x.r = -> _ { g } }
  subj.generate count: 3
  p subj.name

  subj = ColorTable.new { |x| x.r = -> _ { max - g } }
  subj.generate count: 3
  p subj.name
end
