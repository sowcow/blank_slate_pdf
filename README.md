# Blank Slate PDF

# What

PDFs for RM.

# Where

- [Days.pdf random background version](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Days_MIX.pdf)
- [Projects.pdf random background version](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Projects_MIX.pdf)
- [Index.pdf random background version](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Index_MIX.pdf)
- [All other background versions ('cdot' version has higher density of dots than 'DOT' version)](https://github.com/sowcow/blank_slate_pdf/releases/latest)

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
- Index cards PDF

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

![Structure overview](output/COLOR_Days_MIX.png?raw=true)

# Projects PDF

There is a grid of entries, every one having 12 consecutive pages inside.
So it can be seen as a folder of fixed-size files with the difference that you don't use file-system UI and write names by hand.

Usage:
- write a project name into any cell
- enter it, use any number of pages
- use back button at the top to return to the grid

![Structure overview](output/COLOR_Projects_MIX.png?raw=true)

# Index cards PDF

Similar to Projects but having single page inside any entry so grouping is imposed from the
grid page instead.
More likely to be used for more random content that still can be grouped into topics.
It was somewhere on the path inspired by index cards.
But in this case index cards are more likely to be organized.
It can be seen as grid view where you make own preview or just mark page as used.
It can be seen as less powerful verision of tagged pages but more experimental instead.

Usage pattern:
- mark any square as being used
- enter it, use any number of pages for any content (marker above shows current column in the square)
- use back button, mark used pages anyhow
- divide the grid into parts and write topics to have this type grouping on creation of new notes

![Structure overview](output/COLOR_Index_MIX.png?raw=true)

# Usage Assumptions

- generally I don't use layers or tags or toolbar
- still manual copying of pages content is easy so pre-made daily dashboard thing is never necessary

# Technical Usage

- download and extract needed fonts as expected by `bs/fonts.rb`.
- have ruby installed and run `bundle` in the root
- run `rake`, check `output/` dir

# Changelog

- org-mode early inspiration but that is too open ended by itself so no 
- it started as simplistic setup that allows generation of any interactive pdfs to be filled by the user
- then enough patterns crystallized so it became more incremental and modular technically
- then actual PDFs got to be stupid-simple with least complexity introduced by them
- will see if there are side effects to the project other than having dreams about linked pdf grids

## [DAFUQPL](https://github.com/dafuqpl/dafuqpl) License
