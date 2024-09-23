require_relative '../32.rb'

$colored = true
Rounds32.make name: 'COLOR_32'
$colored = false

Rounds32.make name: '32'

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
