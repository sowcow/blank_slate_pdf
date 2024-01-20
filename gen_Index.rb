require_relative 'Index'

mix_bg = 'DLGBdlgB'

[1, 1.5].each { |scale|
  suffix = scale == 1 ? '_12x12' : ''
  $colored = true
  Index.make name: %'COLOR_Index#{suffix}_MIX', grid: mix_bg, scale: scale
  $colored = false

  Index.make name: %'Index#{suffix}_MIX', grid: mix_bg, scale: scale
  Index.make name: %'Index#{suffix}_BLANK', grid: ?B, scale: scale
  Index.make name: %'Index#{suffix}_DOT', grid: ?D, scale: scale
  Index.make name: %'Index#{suffix}_LINE', grid: ?L, scale: scale
  Index.make name: %'Index#{suffix}_GRID', grid: ?G, scale: scale
  Index.make name: %'Index#{suffix}_cdot', grid: ?d, scale: scale
  Index.make name: %'Index#{suffix}_cline', grid: ?l, scale: scale
  Index.make name: %'Index#{suffix}_cgrid', grid: ?g, scale: scale
}

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
