# Project

Abstract exploration within the constraints of the PDF format on RM device.

- it started as simplistic setup that allows generation of any interactive pdfs to be filled by the user
- then enough patterns crystallized so it became more incremental and modular technically

# Usage

UX is not optimized for a random first-time user so UX is as exploratory as the project itself.

RM toolbar is assumed to be closed and navigation controls mostly take space around the grid.

Other details about specific pdf files can be read in their metadata or in corresponding files such as `ABS.rb`

[Downloads](https://github.com/sowcow/blank_slate_pdf/releases)

# Technical Usage

- download and extract needed fonts as expected by `bs/fonts.rb`.
- have ruby installed and run `bundle` in the root
- either run `ruby all.rb` or specific files like `ruby ABS.rb` to generate pdfs

# BSv4

Current composition:

- ABS - abstract
- BSE - time, monthly
- NBS - spatial, graphs
- BS2 - abstract two levels deep, diagram legend use is an option

# Usage Assumptions

- not using layers or tags or toolbar at all
- still manual copying of pages content is easy (daily dashboard thing is not needed)
- still some rare navigation could be done with grid view (file-scoped notes space I assume)

# Future

- checklists are there already?
- titles, abstract titles, geometry

# Other

- org-mode early inspiration
- short names potenital .g .g16? .d?
- more abstractions around numbers..areas
- dots and lines collisions
- non-BS refactoring

## [DAFUQPL](https://github.com/dafuqpl/dafuqpl) License
