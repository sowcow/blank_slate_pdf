require_relative 'Monitors'

$colored = true
Monitors.make name: 'COLOR_Monitors'
$colored = false

Monitors.make name: 'Monitors'

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
