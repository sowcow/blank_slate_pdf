require_relative 'blank_slate_pdf'
require_relative 'lib/grid'
require 'pathname'

# - [x] order of pages differences
# - [x] stars layout
# - [x] always clickable navigation bars
# - [x] go full spatial and add top level menu

#$debug = true # shows links

$setup = {
  orientation: PORTRAIT,
  #hand: RIGHT, # varies inside, just changes back button corner to be usable in RM
  device: RM,
  #grid: Grid.new, # default grid, redefined anyway

  Title: 'Blank Slate PDF (%{name})',
  Author: 'Alexander K (https://github.com/sowcow)',
  Producer: 'https://github.com/sowcow/blank_slate_pdf',
  Subject: '%{description}',

  # v1 stuff:
  #calendar_year: 2024,
  #week_start: :monday,
}

# with v2 actually used configs are v2_configs/* but complexity there is higher
# (v1 stuff may be broken with v2 version being the main currently)
# still file configs/1c-0.rb is the simplest example of code of actual generation
# yet if the next version will have a refactoring then both ways may get outdated

here = Pathname __dir__
output = here + 'output'
output.mkpath unless output.exist?
Pathname.glob(here + 'v2_configs/*.rb') do |x|
  #next unless x.to_s =~ /\bspaced-2d/ # XXX

  load x
  $configs_loaded.each { |x| x.generate output }
end
