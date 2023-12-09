class Dimension
  attr_reader :size, :divizor, :step, :delta

  def initialize size, divizor, delta: 0
    @size = size
    @divizor = divizor
    @step = size / divizor.to_f
    @delta = delta
  end

  # corner: 0 - 0.5 - 1
  def at index, corner: 0
    unless index.is_a? Float # way to opt-out
      index += divizor while index < 0
    end
    index += corner
    @delta + step * index
  end
end
