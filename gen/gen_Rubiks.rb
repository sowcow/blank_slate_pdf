require_relative '../Rubiks.rb'

$colored = true
Rubiks.make name: 'COLOR_Rubiks'
$colored = false

Rubiks.make

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
