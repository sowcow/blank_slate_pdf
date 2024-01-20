require_relative 'ABS'

mix_bg = 'SDLGdBlg'

$colored = true
ABS.make name: 'COLOR_ABS_MIX', grid: mix_bg
$colored = false

ABS.make name: 'ABS_MIX', grid: mix_bg
ABS.make name: 'ABS_BLANK', grid: ?B
ABS.make name: 'ABS_DOT', grid: ?D
ABS.make name: 'ABS_STARS', grid: ?S
ABS.make name: 'ABS_LINE', grid: ?L
ABS.make name: 'ABS_GRID', grid: ?G
ABS.make name: 'ABS_dot', grid: ?d
ABS.make name: 'ABS_line', grid: ?l
ABS.make name: 'ABS_grid', grid: ?g
