require_relative 'blank_slate_pdf'
require 'pathname'

# - [ ] order of pages param to have?

#$debug = true # shows links

$setup = {
  # only variability supported in this block is the hand configuration (it moves back button to be accessible in RM)
  hand: RIGHT,
  device: RM,
  orientation: PORTRAIT,
  # page sizes are fixed in constants now (may need mapping to device types)
  # also scaling method of distances in raw pixels `R` when used uses those constants

  # grid is used alot, some places may have numbers hardcoded though
  grid_x: 12,
  grid_y: 16,

  # To not have otherwise useless credits and entry info pages
  Title: 'Blank Slate PDF (%{name})',
  Author: 'Alexander K (https://github.com/sowcow)',
  Producer: 'https://github.com/sowcow/blank_slate_pdf',
  Subject: '%{description}',

  # calendar-specific
  calendar_year: 2024,
  week_start: :monday,
}

# file configs/1c-0.rb should be the first actual generation example to check
# then squares-* file adds some basic layout (as opposed to drawing it in-place by hand)
# then month-day-* adds even more specific layout

here = Pathname __dir__
output = here + 'output'
output.mkpath unless output.exist?
Pathname.glob(here + 'configs/*.rb') do |x|
  #next unless x.to_s =~ /\bmonth/ # XXX

  load x
  $config_loaded.generate output
end
