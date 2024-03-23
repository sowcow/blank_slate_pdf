require_relative '../Sundays_L12'

$colored = true
Sundays.make name: 'COLOR_Sundays_L12'
$colored = false

Sundays.make name: 'Sundays_L12'

system 'rm output/info*.png'
system 'rm output/COLOR*.pdf'
system 'rm output/notes*.png'
