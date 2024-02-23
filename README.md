# Blank Slate PDF

# What

PDFs for RM.

# Where

- [Days_focus.pdf has predefined background with hour blocks](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Days_focus.pdf)
- [Days.pdf random background version](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Days_MIX.pdf)
- [Projects.pdf](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Projects.pdf)
- [Index.pdf random background version](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Index_MIX.pdf)
- [Index_12x12.pdf random background version](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Index_12x12_MIX.pdf)
- [Monitors](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Monitors.pdf)
- [All other background versions ('cdot' version has higher density of dots than 'DOT' version)](https://github.com/sowcow/blank_slate_pdf/releases/latest)

NOTE: closed RM toolbar is needed to see the back link at the top.

# Latest bigger update

- General UI principles:
  1. RM toolbar needs to be closed
  1. squares are links except the bottom row
- Projects PDF changed to hold only four projects.
  They are meant to be reasonably scoped to rotate the PDF often.
  Also this can be seen as a type of kanban WIP limit.
- Instead of quantity projects got additional level of depth.
  Now inside the project there are 12 pages of lists.
  Every item in the list (except the bottom row) has additional single page inside.
- Main page can be used for whatever creative activity logging one can come-up with.
- I assume this structure favors decomposition.

# Current stable state of the Project

PDFs went from being abstract and experimental to asbstract and simplistic.
Sadly names got simpler too and there are no more names like "Square BS PDF".

Initially I was looking into combining things.
And I think that value of combining is there when it comes to grouping similar things like habbits.
But it looks like otherwise combining different things in such interactive PDFs may loose value.
And those combined PDFs exist just to be more marketable.

The idea is that things with different speed of change should be separable.
Then things should be combined by the system.
I assume switching between files "cost" is smaller if the system is clear and one knows it by memory.

# System

- Days PDF
- Projects PDF (separate files per PARa letters if/when needed)
- (optional) Index cards PDF
- (optional) Monitors PDF

Morning pages and such longer content goes into a separate default template Notebook.
Paper and other mediums are good for own specialized uses as well.

Still one interesting scenario would be to not use Index cards and navigate between two remaining PDFs
with a `rm-hacks` gesture. Maybe Days can have that Areas aspect from PARa, maybe with using tags.

# Days PDF

It is a year calendar (using Monday weeks) having only a single page for everything.
Day pages only have a grid of choice with no dashboard or anything.
Also there is a habits grid per month that can be used for word input or for checkmarks.

Single page is a feature because it makes the calendar more single-purpose.
So it is on the reviewability side of things.

There are some hidden features:
- hidden links below upper corners (second row) that lead from Month view to Habits page
- hidden links below upper corners that lead from Day view to Week view
- also less intuitive links from Month view to Week view are positioned right below every column of days

Also there is a predefined background version where center square can be used as:
- Focus of the day
- Eisenhower matrix in four parts
- Sketch built over the day
- Mix of these
- Bottom space is probably catchall/followup then (unless another tool does it)

![Structure overview](output/COLOR_Days_MIX.png?raw=true)

# Projects PDF

Latest update description is way above.

Usage:
- given RM toolbar is closed
- write a project name near one square on the main page
- enter the project square
- 12 consecutive pages can be seen as todo lists where every item can be entered for details
  page inside it by entering the square at the left of the item
- use back button at the top to return to the grid

![Structure overview](output/COLOR_Projects.png?raw=true)

# Index cards PDF

Similar to Projects but having single page inside any entry so grouping is imposed from the
grid page instead.
More likely to be used for more random content that still can be grouped into topics.
It is more organizable than plain index cards but less powerfull then physical/digital board of them.
It can be seen as grid view where you make own preview or just mark page as used.
It can be seen as less powerful verision of tagged pages but more experimental instead.

Usage pattern:
- mark any square as being used
- enter it, use any number of pages for any content (marker above shows current column in the square)
- use back button, mark used pages anyhow
- divide the grid into parts and write topics to have this type grouping on creation of new notes

![Structure overview](output/COLOR_Index_MIX.png?raw=true)
![Structure overview](output/COLOR_Index_12x12_MIX.png?raw=true)

# Monitors PDF

PDF to monitor weather, habits, or whatever else.
One page has a table of four columns for every day of month.
PDF has 12 pages of that for every month of the year.
Because of the volume it is meant for mostly less essential, more experimental columns/variables to record and see.
Contrasting to that Days.pdf has only a single such page per month.
Anyway the volume could open interesting uses like a habit per page plus three columns for some related controls/variables.

Horizontal lines are week divisions (Monday-starting weeks).

![Structure overview](output/COLOR_Monitors.png?raw=true)

# Usage Assumptions

- generally I don't use layers or tags or toolbar
- still manual copying of pages content is easy so pre-made daily dashboard thing is never necessary

# Technical Usage

- download and extract needed fonts as expected by `bs/fonts.rb`.
- have ruby installed and run `bundle` in the root
- run `rake`, check `output/` dir
- for development some files generate PDFs by just running `ruby <FileName>.rb`

# Changelog

- org-mode early inspiration but that is too open ended by itself so no 
- it started as simplistic setup that allows generation of any interactive pdfs to be filled by the user
- then enough patterns crystallized so it became more incremental and modular technically
- then actual PDFs got to be stupid-simple with least complexity introduced by them
- will see if there are side effects to the project other than having dreams about linked pdf grids

## [DAFUQPL](https://github.com/dafuqpl/dafuqpl) License
