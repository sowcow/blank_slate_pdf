# What

Utterly abstract PDFs for use on RM device.

# Why

The idea is to explore possibilities for abstract but useful PDFs without introducing arbitrary constraints or decisions.
So in fact no use is possible without first deciding on how the PDF is going to be used.

# Where

[ABS](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/ABS_SAND.pdf)
[BSE](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/BSE.pdf)
[NBS](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/NBS.pdf)
[2BS](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/2BS.pdf)
[6BS](https://github.com/sowcow/blank_slate_pdf/releases/latest/download/6BS.pdf)

# ABS: Abstract BS

The obvious use is to have any list items at the left of the page.
Each item having 12 consecutive pages inside.

RM toolbar is closed to not cover the links.
Right items are experimental.
Top links are for notes not scoped by any item.
Also there are different background versions in releases.

![Structure overview](output/ABS_STARS.png?raw=true)

# BSE: BS Exec

A PDF per month. 12 pages per day notes.
12 pages per week notes.
18 week views per week to cover different aspects.

![Structure overview](output/BSE.png?raw=true)

# NBS: Nova BS

Every item is a place for a graph where every node has own 12 pages.

![Structure overview](output/NBS.png?raw=true)

# BS2: two levels deep BS

Items have subitems.

![Structure overview](output/BS2.png?raw=true)

# 6BS: Six Big Squares

Latest and experimental.

![Structure overview](output/6BS.png?raw=true)

# Usage Assumptions

- generally I don't use layers or tags or toolbar
- still manual copying of pages content is easy (so pre-made daily dashboard thing is not needed)
- still some rare navigation could be done with RM grid view (file-scoped notes space I assume)

# Technical Usage

- download and extract needed fonts as expected by `bs/fonts.rb`.
- have ruby installed and run `bundle` in the root
- either run `ruby all.rb` or specific files like `ruby ABS.rb` to generate pdfs

# Other Notes

- org-mode early inspiration
- it started as simplistic setup that allows generation of any interactive pdfs to be filled by the user
- then enough patterns crystallized so it became more incremental and modular technically
- fundamental abstractions may or may not get a look into

## [DAFUQPL](https://github.com/dafuqpl/dafuqpl) License
