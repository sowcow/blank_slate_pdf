# Blank Slate

The project consists of spiritually close pdfs for Remarkable in the first place.

Main files now are:
- Abstract BS
- BS Exec

One is abstract and is more adding content optimized; another has a calendar of the current month and is more of a plan/review place.
Abstract one goes in different background versions.

Also there are pdfs generated on the way:
- BS Habits - one pdf per month to log all possible BS habits/activities/events
- different pdfs for nested lists and experiments

Main pdfs evolve to support my use cases.
Even though I see some potential for non-BS refactoring, I'm like the codebase as I use it.

# General

There is implicitness in UI is by design.
On one hand early flexible experimental approach is not going anywhere.
On another hand pdfs are optimized for long-time user and not for initial marketing impression.
One tradeoff to flexibility is that page headers are not there unless you manually add them but going deeper they become impractical to add.

Pdfs assume the Remarkable toolbar to be closed and space around the borders is used for often invisible navigation controls.

If needed pdfs are not in the most recent release then they should be somewhere below as part of another release assets.

[Downloads](https://github.com/sowcow/blank_slate_pdf/releases)

# BS Exec

- there is a new pdf for every next month
- weeks starts from Monday
- root page has many links to specific aspects/item pages around the border that can be named manually
- aspect page has a calendar of the month in question and links to day and week pages
- day and week pages have links to each-other

Habits use case:
- on the root page give a name to an aspect page link
- enter the link
- give the same name as a header of the page
- mark stuff anyhow in day squares

More detailed logging:
- same as habits but enter the day for a page of stuff to write there

Week planning:
- week links are right below the last day of that week or on the day page right below the day square

Review use case:
- use page turning on different types of pages
- also it should be possible to have one aspect/item to be for some activity and the next one for review of it
- then switching between them then is a matter of tapping the link on the border

Overall this pdf favors single page entries and some degree of decomposition.

# BS Habits

This is the preceeding to BS Exect pdf that is way simpler but stable and has versions for any month generated in Downolads.
Download the pdf that fits: number of days in the month, starting day of week, week type (MON/SUN).
Also there are background variations to choose from.

# Abstract BS

# What

Abstract and very flexible inter-connected PDF for different workflows and experiments.
Tested on Remarkable only.
It is optimized for the right-hand left-to-right writing experience because links are positioned to not appear under the hand.

# Constraints

Important notes for RM:
- you'll need to hide the toolbar to have left-most "buttons" accessible

# Contents

This PDF has three levels of pages:
- top-most root page
- item pages
- sub-pages

Root page has 18 "invisible" square links at the left of the grid (outside the grid itself).
One workflow is to mark any link with a circle, then to write some name nearby, then to tap the circle and maybe repeat the name as the header on the newly opened page.

The opened page is that item page.
By turning pages you have 9 pages there and kind-of pagination above.
Also there are links to sub pages: 6 of them in the upper-right corner outside the grid.

Sub pages are single pages per item so there is no pagination for them.
Instead they have different page-turning dynamics: by turning pages you change the item at the left instead.
This should make better place for more general notes or item summary/review.
The dynamics can be seen as more optimized for reading/scanning through multiple items.
And for that reason it makes sense to use those the same way consistently through different items.

# Other

Navigation back/up is by the arrow at the upper corner.
Also there are breadcrumbs left at the place of links.
They should be helpful to actually see page-turning dynamics.

---

# V1 stuff below

That code is not removed and is not being refactored to be fit v2 changes. So most likely it needs a switch into older commit/branch to be working.

---


# What

- Very flexible and simplistic pdfs for nested lists or other own processes for devices like Remarkable.
- In some regards inspired by org-mode
- Also readable ruby code that generates each is there for further experiments. Actual generation files are under 50 LOC in most cases
- One version of pdfs is a calendar, I think the best way is to use it in parallel with more blank versions

Pages of PDF are connected by invisible links into a tree.
The idea is that one can experiment with own processes right inside Remarkable
by drawing whatever stuff around those links and then using links as buttons in the UI.

The next level is to alter the code to tune things when needed.

Info on specific PDFs is present either in their properties when opened or can be read in corresponding files in `configs/` directory.

Here is example info for `1c0-0.pdf`

```
Root page has one column of square "invisible" links at the left side.
Every link leads to just a plain page with no further links.
---
Necessary when using with Remarkable: #{hand} hand mode and closed toolbar.
Otherwise links/navigation controls in the pdf overlap controls in RM.
There are breadcrumbs left at the place of links in part to visualize page ordering.
```

[Downloads](https://github.com/sowcow/blank_slate_pdf/releases)

## How

There are empty square links on pages that are not shown.
On a single column pages links use cells in the leftmost column.
The way to use a link is first to circle it and then tap the circle.

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

## [DAFUQPL](https://github.com/dafuqpl/dafuqpl) License
