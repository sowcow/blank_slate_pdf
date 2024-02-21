require_relative 'Projects'
require_relative 'Days'
require_relative 'Index'
require_relative 'Monitors'

# - final page line-marker position, not arrow position I assume but try anyway with this grid

Projects.make name: 'Projects', grid: 'GGDD', timeline: true, rows: 6
Monitors.make name: 'Monitors' # no point to pass own filling
Days.make name: 'Days', grid: 'dlg'
Index.make name: 'Index', grid: 'B', scale: 1
