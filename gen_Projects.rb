require_relative 'Projects'

mix_bg = 'DLGBdlgB'

$colored = true
Projects.make name: 'COLOR_Projects_MIX', grid: mix_bg
$colored = false

Projects.make name: 'Projects_MIX', grid: mix_bg
Projects.make name: 'Projects_BLANK', grid: ?B
Projects.make name: 'Projects_DOT', grid: ?D
Projects.make name: 'Projects_LINE', grid: ?L
Projects.make name: 'Projects_GRID', grid: ?G
Projects.make name: 'Projects_cdot', grid: ?d
Projects.make name: 'Projects_cline', grid: ?l
Projects.make name: 'Projects_cgrid', grid: ?g

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
