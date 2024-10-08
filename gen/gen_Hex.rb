require_relative '../Hex.rb'

$colored = true
Hex.make name: 'COLOR_Hex'
$colored = false

Hex.make name: 'Hex'

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
