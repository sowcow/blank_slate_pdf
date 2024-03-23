# Blank Slate PDF

# What

PDFs for RM.

# Where

Latest landscape + split-mode PDFs:
- [Sundays_L12.pdf](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Sundays_L12.pdf)
- [Lists_L12.pdf](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Lists_L12.pdf)

Older portrait full-size PDFs:
- [Days.pdf](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Days.pdf)
- [Lists.pdf](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Lists.pdf)

NOTE:
- use new three finger gesture to reset the zoom after splitting
- when using split-mode PDFs, I go with lists being on the left currently
- closed RM toolbar is assumed
- I use rm-hacks to hide the round thing in the corner RM adds so that may be assumed in PDFs too
- PDFs I don't use get remeved from the list but may be there in older releases for example there should be Days.pdf with random flat backgrounds more fitting Bujo use

# Current System

- Days PDF as calendar or anything time-related
- Lists PDF for main things (PA in PARA)
- Separate files or Quick sheets + tags for most of other things

# Sundays landscape 1/2 PDF

![Structure overview](output/COLOR_Sundays_L12.png?raw=true)

Sunday weeks calendar + notes page per day.
It is made for landscape forced + split 1/2 mode in RM (that requires rm-hacks currently).

NOTE: They don't use Sunday-week calendars in my location but there may be a point in using this format still.

Notably navigation from month overview can be made only to weeks.
The point is in using the week page more.
Interesting feature of those week pages in Sunday-weeks mode is that weekend days wrap weekdays.
This adds plan-review functionality without special pages or separate space.

# Lists landscape 1/2 PDF

![Structure overview](output/COLOR_Lists_L12.png?raw=true)

This can be seen as advanced todo lists PDF.
It is made for landscape forced + split 1/2 mode in RM (that requires rm-hacks currently).

It supports a type of items that need further decomposition because every item has 11 pages inside.
Adding titles and marking used links is the way to navigate within the PDF.

First page (root) has:
- links to lists pages, these links have space inside to give short name to the list
- dots for whatever use, possibly to differentiate file preview by drawing something

Lists:
- every list has 7 items, linked by squares at the left
- odd space at the left of every item row can be used for priority/ordering

Items:
- items have 11 consecutive pages each

Also technically title can be rendered on every page by setting `title: 'ABC'` in `Lists.rb`.
It should be useful if separate PDF file is used per project.

# Days PDF (Monday weeks only, week overivew pages are secondary)

![Structure overview](output/COLOR_Days.png?raw=true)

It is a year calendar having only a single page for everything.
Day pages have predefined blocks for hours in the form of clock face.
Also there is a habits grid per month that can be used for word input or for checkmarks.

Single page is a feature because it makes the calendar more single-purpose.
So it is on the reviewability side of things.

There is predefined background with clock face for hours blocks and the central square can be used as:
- Focus of the day
- Eisenhower matrix in four parts
- Sketch built over the day
- Mix of these

There are some hidden features:
- hidden links below upper corners (second row) that lead from Month view to Habits page
- hidden links below upper corners that lead from Day view to Week view
- also less intuitive links from Month view to Week view are positioned right below every column of days

# Lists PDF

![Structure overview](output/COLOR_Lists.png?raw=true)

This can be seen as advanced todo lists PDF.
It supports a type of todo items that need further decomposition because every item has 12 pages inside.
Also it supports catchall for relevant ideas/inputs that can be processed later.
Adding titles and marking used links is a good idea to navigate within the PDF.

First page (root) is a table of contents:
- First row of links goes to 12 ideas/inputs pages.
- Then two rows link to 12 lists pages, these links are bigger so there is space to give them name when needed.
- Other links below link to items of lists in case that is needed at some point

Lists:
- Lists can be accessed just by turning to the next page from the root
- Every list has 7 items, linked by squares at the left

Items:
- Items have 12 consecutive pages each
- Also all pages have links to ideas/inputs pages (in the upper-right corner)

Ideas:
- linked from every page to be very accessible for addition
- Overall 12 pages with navigation between them at the top or by turning pages

Also title can be rendered on every page by setting `title: 'ABC'` in `Lists.rb`.
It should be useful if separate PDF file is used per project.

# Technical Usage

- the readable file with comments currently is `Lists_12.rb`, feel free to ask in issues if that file is unclear in some regards
- download and extract needed fonts as expected by `bs/fonts.rb`.
- have ruby installed and run `bundle` in the root of the project
- run `rake`, check `output/` dir
- for development some files generate PDFs by just running `ruby <FileName>.rb`

# Changelog

- org-mode early inspiration but that is too open ended by itself so no 
- it started as simplistic setup that allows generation of any interactive pdfs to be filled by the user
- then enough patterns crystallized so it became more incremental and modular technically
- then actual PDFs got to be stupid-simple with least complexity introduced by them
  (PDFs went from being abstract and experimental to asbstract and simplistic. Sadly names got simpler too and there are no more names like "Square BS PDF".)
- (there was funny side effect of the project is having dreams about linked pdf grids)
- then I tried to optimize PDFs for use approaches (Bujo/PARA)
- also Days PDF got clockface and focus area
- merged other simplistic PDFs back into abstract PDF for lists (that can fit Bujo/PARA by itself);
  it is not abstract in style as early PDFs but there are no arbitrary decisions so it is true to the idea still.


# [DAFUQPL](https://github.com/dafuqpl/dafuqpl) License
