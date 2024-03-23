require_relative '../Lists_L12'

$colored = true
ListsL12.make name: 'COLOR_Lists_L12'
$colored = false

ListsL12.make name: 'Lists_L12'

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
