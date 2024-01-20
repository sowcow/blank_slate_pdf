require_relative 'base'

module BS
  module Info
    def self.generate
      text = $bs[:description]

      $bs.pages.first.child_page :info do
        font $roboto do
          h = pdf.height_of text
          pdf.move_down (pdf_height - h) / 2
          pdf.text text
        end
      end
    end
  end
end
