require 'prawn'
require 'delegate'
require_relative 'details_rendering'
require_relative 'page_sizes'

RM = :RM
RIGHT = :RIGHT
LEFT = :LEFT
PORTRAIT = :portrait

class BlankSlatePDF
  attr_reader :page_stack
  attr_reader :page_queue
  attr_reader :current_page_number

  def current_page
    page_stack.last
  end

  def initialize name, &block
    @name = name
    @config = {}
    @description = ''
    @page_stack = []
    @page_queue = []
    @block = block
    @current_page_number = 0
  end

  def configure hash
    @config = @config.merge hash
    @config.each { |k,v|
      define_singleton_method k do @config.fetch k end
    }
  end

  def page &block
    new_page = Page.new self, &block
    @page_stack << new_page
    add_page_to_queue new_page
    render_queue if @page_queue.size == 1
    @page_stack.pop
    new_page
  end

  # sorted queue
  def add_page_to_queue new_page
    @page_queue << new_page
  end

  def description text
    @description = text.strip.lines.map(&:strip) * ?\n
  end

  # effect

  def generate path
    @path = path
    instance_eval &@block if @block
  end

  def pdf
    return @pdf if @pdf
    params = {
      page_size: [PAGE_WIDTH, PAGE_HEIGHT],
      page_layout: orientation,
      margin: [0,0,0,0],
      info: {
        Title: Title() % { name: @name },
        Author: Author(),
        Producer: Producer(),
        Subject: Subject() % { description: @description || '' },
      }
    }
    @pdf = Prawn::Document.new params
  end

  def render_queue
    while page_queue.any?
      page = page_queue.shift
      @current_page_number += 1

      pdf.start_new_page unless @current_page_number == 1
      pdf.add_dest page.id, pdf.dest_fit
      page.render
    end
  end

  def file_name
    File.join @path, "#{@name}.pdf"
  end

  def render_file
    @pdf.render_file file_name
  end

  include DetailsRendering
end

$Page_next_page_id = 0

class Page
  attr_reader :id
  attr_accessor :parent
  attr_reader :breadcrumbs
  attr_reader :page_number

  extend Forwardable
  delegate [:pdf, :grid_x, :grid_y, :page, :page_stack, :page_queue, :current_page, :hand, :device] => :@context

  def initialize context, &block
    @id = 'page-' + $Page_next_page_id.to_s # to_s is mandatory
    $Page_next_page_id += 1

    @context = context
    @parent = page_stack.last
    @block = block
    @breadcrumbs = []
  end

  def render
    @page_number = @context.current_page_number
    instance_eval &@block if @block
  end

  include DetailsRendering
end
