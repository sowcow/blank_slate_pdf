require_relative '../Rubicks.rb'

$colored = true
Rubicks.make name: 'COLOR_Rubicks'
$colored = false

Rubicks.make

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
