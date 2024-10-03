require_relative '../Q.rb'

$colored = true
$week_format = WeekFormat.new ?M
Q.make name: 'COLOR_Q', year: 2024, quarter: 4
$colored = false

[?S, ?M].each { |week_type|
  $week_format = WeekFormat.new week_type
  suffix = $week_format.monday?? "MON" : "SUN"

  Q.make name: %'2024_Q4_#{suffix}', year: 2024, quarter: 4

  Q.make name: %'2025_Q1_#{suffix}', year: 2025, quarter: 1
  Q.make name: %'2025_Q2_#{suffix}', year: 2025, quarter: 2
  Q.make name: %'2025_Q3_#{suffix}', year: 2025, quarter: 3
  Q.make name: %'2025_Q4_#{suffix}', year: 2025, quarter: 4
}

system 'rm output/info*.png'
system 'rm output/*extra*.png'
system 'rm output/COLOR*.pdf'
