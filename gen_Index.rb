require_relative 'Index'

mix_bg = 'DLGBdlgB'

$colored = true
Index.make name: 'COLOR_Index_MIX', grid: mix_bg
$colored = false

Index.make name: 'Index_MIX', grid: mix_bg
Index.make name: 'Index_BLANK', grid: ?B
Index.make name: 'Index_DOT', grid: ?D
Index.make name: 'Index_LINE', grid: ?L
Index.make name: 'Index_GRID', grid: ?G
Index.make name: 'Index_cdot', grid: ?d
Index.make name: 'Index_cline', grid: ?l
Index.make name: 'Index_cgrid', grid: ?g

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
