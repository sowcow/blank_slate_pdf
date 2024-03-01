require_relative 'Days'

mix_bg = 'DLGBdlgB'

$colored = true
Days.make name: 'COLOR_Days_MIX', grid: mix_bg
$colored = false

Days.make name: 'Days', grid: ?g, focus: true

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
