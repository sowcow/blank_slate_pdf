[true, false].each { |x|
  $colored = x

  $name = 'ABS_STARS'
  $draw_grid = -> { $bs.draw_stars }
  load './ABS.rb'
  BS.generate

=begin
  $name = 'ABS_SAND'
  $draw_grid = -> { $bs.draw_dots }
  load './ABS.rb'
  BS.generate

  $name = 'ABS_WAVES'
  $draw_grid = -> { $bs.draw_lines }
  load './ABS.rb'
  BS.generate

  $name = nil
  $draw_grid = nil

  load './NBS.rb'
  BS.generate

  load './BS2.rb'
  BS.generate

  load './BSE.rb'
  BS.generate

  load './6BS.rb'
  BS.generate

  load './SBS.rb'
  BS.generate
=end
}
