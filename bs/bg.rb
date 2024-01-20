module BS
  class Bg
    def initialize grid_key
      @grid_key = grid_key
      @index = 0
    end

    def first
      @index = 0
      current
    end

    def current
      return @grid_key if @grid_key.chars.length == 1
      @grid_key.chars[@index % @grid_key.chars.count]
    end

    def take
      current.tap { @index += 1 }
    end
  end
end
