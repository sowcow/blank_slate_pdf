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

  attr_accessor :name

  def initialize name, &block
    @name = name
    @config = {}
    @description = ''
    @page_stack = []
    @page_queue = []
    @block = block
    @current_page_number = 0
  end

  def configure hash, deep: true
    @config = @config.merge hash
    @config.each { |k,v|
      define_singleton_method k do @config.fetch k end
      thing = @config.fetch k
      thing.configure self if deep && thing.respond_to?(:configure)
    }
  end

  # kind of revisit
  def with_parent page, &block
    prev = @given_parent
    @given_parent = page
    instance_eval &block
    @given_parent = prev
  end

  def get_parent
    @given_parent || page_stack.last
  end

  # wtf is with naming around
  def current_page
    page_stack.last
  end

  # useless, makes for slow or low quality page backgrounds, svg is not supported directly
  #
  #BG_SCALE = 4 # resizing
  #BG_SCALE_2 = 1 # usage
  #def make_background name, &block
  #  raise 'done before everything' unless @current_page_number == 0
  #  was_pdf = @pdf

  #  @backgrounds ||= {}

  #  file_name = File.join @path, "_temp_bg.pdf"
  #  @pdf = configure_pdf

  #  page = Page.new self, &block
  #  @current_page_number += 1
  #  page.render
  #  @pdf.render_file file_name

  #  Dir.chdir @path do
  #    #system "convert -density #{72*BG_SCALE*BG_SCALE_2} _temp_bg.pdf -background white -alpha remove -alpha off -resize #{(100 / BG_SCALE.to_f).floor}% _temp_bg.png"
  #    system "convert -density #{72*BG_SCALE*BG_SCALE_2} _temp_bg.pdf -resize #{(100 / BG_SCALE.to_f).floor}% _temp_bg.png"
  #    system "rm _temp_bg.pdf"
  #    system "mv _temp_bg.png #{name}.png"
  #  end
  #  @backgrounds[name] = File.join @path, "#{name}.png"

  #  @current_page_number = 0
  #  @pdf = was_pdf
  #end

  #def use_background name
  #  file = @backgrounds[name] or raise 'bg not found'
  #  pdf.image(file, scale: 1.0/BG_SCALE_2)
  #end

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

  def configure_pdf
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
    Prawn::Document.new params
  end

  def pdf
    return @pdf if @pdf
    @pdf = configure_pdf
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
  attr_accessor :data

  extend Forwardable
  delegate [:pdf, :grid_x, :get_parent, :grid_y, :grid, :page, :page_stack, :page_queue, :current_page, :hand, :device, :use_background] => :@context

  def initialize context, &block
    @id = 'page-' + $Page_next_page_id.to_s # to_s is mandatory
    $Page_next_page_id += 1

    @context = context
    @parent = get_parent
    @block = block
    @breadcrumbs = []
  end

  def render
    @page_number = @context.current_page_number
    instance_eval &@block if @block
  end

  include DetailsRendering
end
