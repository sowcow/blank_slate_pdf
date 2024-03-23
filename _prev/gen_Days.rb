require_relative 'Days'

$colored = true
Days.make name: 'COLOR_Days', grid: ?g
$colored = false

Days.make name: 'Days', grid: ?g, focus: true

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
