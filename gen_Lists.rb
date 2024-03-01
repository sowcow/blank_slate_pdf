require_relative 'Lists'

$colored = true
Lists.make name: 'COLOR_Lists'
$colored = false

Lists.make name: 'Lists'

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
