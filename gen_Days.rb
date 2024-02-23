require_relative 'Days'

mix_bg = 'DLGBdlgB'

$colored = true
Days.make name: 'COLOR_Days_MIX', grid: mix_bg
$colored = false

Days.make name: 'Days_focus', grid: ?g, focus: true

Days.make name: 'Days_MIX', grid: mix_bg
Days.make name: 'Days_BLANK', grid: ?B
Days.make name: 'Days_DOT', grid: ?D
Days.make name: 'Days_LINE', grid: ?L
Days.make name: 'Days_GRID', grid: ?G
Days.make name: 'Days_cdot', grid: ?d
Days.make name: 'Days_cline', grid: ?l
Days.make name: 'Days_cgrid', grid: ?g

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
