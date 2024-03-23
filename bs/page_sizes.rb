require 'prawn/measurement_extensions'

# NOTE: I probably messed things around by dividing pt/px while thinking thath PAGE_WIDTH is in pt (thanks do misread docs)
# while actually these are in px
# anyway I like the default line-width I get with this so no point in scaling stuff around
# (the only issue could be with images quality and I don't use them at all because RM seem to be slow with them)

# assuming portrait layout (3x4 perfectly)
REMARKABLE2_SCREEN_WIDTH_PX = 1404
REMARKABLE2_SCREEN_HEIGHT_PX = 1872

# actual remarkable2 size to use would be something around: ~157.2.mm or ~152.4.mm
# but I like fitting it into the clear size of A5 (~5% downscale)
A5_WIDTH_IN_PT = 148.5.mm

# ratio should convert used pixels width into A5-fitting size
SCALE_RATIO = A5_WIDTH_IN_PT / REMARKABLE2_SCREEN_WIDTH_PX.to_f

# rescale pixels for distances (not for line widths)
def R number
  number * SCALE_RATIO
end

PAGE_WIDTH = R REMARKABLE2_SCREEN_WIDTH_PX
PAGE_HEIGHT = R REMARKABLE2_SCREEN_HEIGHT_PX

$PAGE_HEIGHT = PAGE_HEIGHT
$PAGE_WIDTH = PAGE_WIDTH

def reformat_page format_name
  format_name = 16 unless format_name
  case format_name
  when 16
    $PAGE_HEIGHT = PAGE_HEIGHT
    $PAGE_WIDTH = PAGE_WIDTH
    $PAGE_LAYOUT = :portrait
  when :L12 # landscape orientation split in halves
    $PAGE_HEIGHT = PAGE_WIDTH
    $PAGE_WIDTH = PAGE_HEIGHT / 2
  else
    raise %'Unexpected format: #{format_name.inspect}'
  end
end
