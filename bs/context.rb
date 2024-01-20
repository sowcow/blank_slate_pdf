require_relative 'bs'
require_relative 'page'
require_relative 'pdf'
require_relative 'positioning'
require_relative 'rendering'
require_relative 'searchable_array'

module BS
end
class BS::Context
  attr_reader :pages
  attr_reader :data

  def [] key
    @config.fetch key # strict here as opposed to pages
  end

  def initialize config
    @data = {}
    @config = config # vs walk and execute?
    @pages = []
    SearchableArray.call @pages
    @current_page = nil
    @next_page_id = 1
    grid 18 # default established in the project, portrait format
  end

  # both getter and creator of pages
  def page type=nil, data={}, &block
    return @current_page unless block
    raise "new page type expected" unless type
    new_page = BS::Page.add self, data: { type: type }.merge(data)
    new_page.tag = type
    new_page.visit &block
  end

  # internalish methods, used through page:

  def visit_page page, &block
    prev = @current_page # stack

    self.current_page = page
    instance_eval &block
    self.current_page = prev
    page
  end

  def current_page= page
    @current_page = page
    return pdf.go_to_page pdf.page_count unless @current_page
    pdf.go_to_page @current_page.page_number
  end

  def add_new_page page
    @pages << page
    pdf.go_to_page pdf.page_count
    pdf.start_new_page unless @pages.count == 1
    page.page_number = pdf.page_count
    pdf.add_dest page.dest_id, pdf.dest_fit
  end

  def next_page_id
    id = @next_page_id
    @next_page_id += 1
    id
  end

  def inspect
    "(BS::Context)"
  end

  def xs *a
    pages.xs *a
  end

  include Pdf
  include Positioning
  include Rendering
end
