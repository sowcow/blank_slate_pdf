# Blank Slate PDF

# What

PDFs for RM with experimental features.

# Where

- [Rubiks.pdf](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/Rubiks.pdf)
- [32.pdf](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/32.pdf)
- [Q4 2024.pdf monday weeks](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/2024_Q4_MON.pdf)
- [Q4 2024.pdf sunday weeks](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/2024_Q4_SUN.pdf)
- [other](https://github.com/sowcow/blank_slate_pdf/releases/latest/)

Also, PDFs I don't use get removed from the list but stay in older releases downloads.


# 32.pdf

![Structure overview](output/COLOR_32.png?raw=true)

Random abstract PDF.
The main page may be the most interesting by itself.
Also there are big hexagons on all children pages.
Otherwise it simple set of 32 5-item lists with 17 consecutive pages per item.

- main page has a hexagon grid of roundish links,
  so it can have experimental uses like mind mapping
- inside such links there is a single page of content space and a list of five items with links per item to go down further
- every such item has 17 consecutive pages with pagination marker on top
- turning pages outside those paginated items just moves between those list pages
- link for going back/up is in the top right corner
- must do with such PDFs is to mark or name links before entering them and then to write the same name into the page header after entered the link

Catchall is not part of the PDF, I assume it should be just flat.

This info is also on the last page of the PDF.


# Q.pdf

![Structure overview](output/COLOR_Q.png?raw=true)

Flexible quarter calendar PDF with write-friendly minimalistic UI.

Main pages: Quarter > Month > Week > Day > Hour

Main experimental feature is having extra page per any calendar page - it can be used for plan/review for example.
Since those extra/review pages have own parallel navigation between them, they can be seen as parallel second calendar with bigger single area for writing.
Second experimental feature is the presence of own hour pages (covering 12 hours per day).

Must know is the use of hidden links, there are two types:
- moving up/back in main calendar is done by the wide link area in the upper-right corner (also exits extra page into corresponding calendar page)
- entering extra page is done by the square link in the bottom-left corner (this corner toggles between extra and main page)

Also on month overview page the last square/day of each column/week will open the week overview.

Also there is best practice to mark used links before entering them.

Also turning pages opens the next month/week/day/hour.
From turning pages perspective start of the day is assumed at 7, and end at 6, so if you open 6 and turn to the next page, it gives 7 of the next day (header shows that).

Day pages have predefined background with clock face for hours blocks and the central square can be used as:
- Focus of the day
- Eisenhower matrix in four parts
- Sketch built over the day
- Mix of these

Flat habit grids are not part of the PDF but there is plenty of more hierarchical plan/review type of space.

This info is also on the last page of the PDF.

# Technical Info

Disclaimer: creative chaos codebase that serves it's purpose well lies ahead.
Other than that, top level `.rb` files should have some comments.

Big picture:

- the pdf is defined by a tree structure starting from root page and going down by child page branches that link back to the parent page
- every child page is defined by link position within the parent page
- there are sequential collections of pages that share the parent and only the first page of them is linked from the parent, this adds volume to be used so you don't cram things onto one page but the tradeoff is you loose turning to the next-page also opening the sibling page (from parent perspective) interaction

Order of things in code:

- generally generation ruby file has pdf description text very early in the file
- then data for rendering may be generated beforehand if it is needed that way
- then in separate chunks of code different types of pages are generated
  (this also makes them appear consequently)
- (then optionally some advanced rendering depending on all pages being in place is done)
- also ui helpers may go to the end of file

# Technical Usage

- download and extract needed fonts as expected by `bs/fonts.rb`.
  `ls fonts => Aoboshi_One/  Noto_Sans_Symbols/  Roboto/`
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
- went back for asbstract for lists, went for plan/review at all scales in calendar (previously Sunday weeks version had that aspect)
- went for more geometry with hexagons

# Maybe todo

- unification about stuff (areas: There.at + there was some grid stuff), lots of code to remove too
- fuck their coordinates, use top-left as 0,0; also have selection being about centers of cells, corners only play on use; no widths/heights interface, use natural directions
- RM PRO renders those grays?
- split each pdf generation between files Q/{data,ui,all}

# [DAFUQPL](https://github.com/dafuqpl/dafuqpl) License
