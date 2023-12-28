require 'prawn'
require_relative 'page_sizes'
require_relative 'authorship'

module Pdf
  def pdf
    return @pdf if @pdf

    # the module is included into Context:
    title = 'Blank Slate PDF: %s' % self[:name]
    description = self[:description].strip.lines.map(&:strip).join(?\n)

    params = {
      page_size: [PAGE_WIDTH, PAGE_HEIGHT],
      page_layout: :portrait,
      margin: [0,0,0,0],
      info: {
        Title: title,
        Author: AUTHOR,
        Producer: PRODUCER,
        Subject: description,
      }
    }
    @pdf = Prawn::Document.new params
  end

  def pdf_width
    pdf.page.dimensions[2] - pdf.page.dimensions[0]
  end

  def pdf_height
    pdf.page.dimensions[3] - pdf.page.dimensions[1]
  end
end
