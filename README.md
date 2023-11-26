# What

- Very flexible and simplistic pdfs for nested lists or other own processes for devices like Remarkable.
- In some regards inspired by org-mode
- Also readable ruby code that generates each is there for further experiments. Actual generation files are under 50 LOC in most cases
- One version of pdfs is a calendar, I think the best way is to use it in parallel with more blank versions

Pages of PDF are connected by invisible links into a tree.
The idea is that one can experiment with own processes right inside Remarkable
by drawing whatever stuff around those links and then using links as buttons in the UI.

The next level is to alter the code to tune things when needed.

Note that left hand and right hand versions are not compatible with RM in another mode.

[Downloads](https://github.com/sowcow/blank_slate_pdf/releases)

## How

There are empty square links on pages that are not shown.
On a single column pages links use cells in the leftmost column.
The way to use a link is first to circle it and then tap the circle.

Info on specific PDFs is present either in their properties when opened or can be read in corresponding files in `configs/` directory.

[Example code](configs/1c-0.rb)

Filename `1c` means there is one column of links in that PDF - basically a list of one level depth to go down.
`1c-1c` in the name means that this will be a list with possibility to go two levels deep.
`1c-1c-0` just means that there is a layer of plain pages as leaf nodes.

## Also

Feedback/PR regarding other devices is welcomed.

Also I keep PDFs small to not see loader at all.
But 10k pages pdf is easy with this code, even though it looks impractical to me now.

## Other

- I think round checkboxes go better with this
- it hits somewhere between apps and paper organizers but there is no point to just copy paper organizer the whole way with this

## Running it

- Download fonts from google fonts into paths at the top of `details_rendering.rb`.
- `bundle install`
- `ruby run.rb`

Code-wise `run.rb` should be reabable starting point.

## Todo

- pages ordering can be another way actually, there are tradeoffs to both ways
- screenshot that I wanted

## WTFPL License
