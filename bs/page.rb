module BS
class Page
  # both .add and #visit are reasonable syntactic sugar
  def self.add context, parent: nil, data:
    page = self.new context, parent: parent, data: data
    context.add_new_page page
    page
  end

  attr_reader :id
  attr_accessor :page_number
  attr_reader :parent
  attr_accessor :data
  attr_reader :local
  attr_accessor :tag
  # tags are local state, different kind of pages from the overview images perspective

  def initialize context, parent: nil, data:
    @context = context
    @parent = parent
    @id = context.next_page_id
    @page_number = nil
    @data = data
    @local = {}
  end

  def [] key
    data[key]
    #data.fetch key # being consistant to simpler pre-existing expectations
  end

  def visit &block
    @context.visit_page self, &block
    self
  end

  def dest_id
    "Page-#@id"
  end

  def inspect
    "(BS::Page(#{id}))"
  end

  # parent-child is core for back navigation
  def child_page type, given_data={}, &block
    page = Page.add @context, parent: self, data: data.merge({ type: type }).merge(given_data.to_h)
    page.tag = type
    page.visit &block if block
    page
  end
end
end
