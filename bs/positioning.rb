require_relative '../lib/grid'

module Positioning
  def self.grid_portrait_18_padded pdf_width, pdf_height
    # grids nesting has raw interface
    frame = -> w, h { Grid.new.apply(w,h).rect 1, 0, 12-2, 16-2 }
    Grid.new(x: 12, y: 18, frame: frame).apply(pdf_width, pdf_height)
  end

  def grid which=nil
    case which
    when nil
      @grid
    when 18
      @grid = Positioning.grid_portrait_18_padded(pdf_width, pdf_height)
    else
      raise "grid #{which.inspect} is not implemented"
    end
  end

  alias g grid
end
