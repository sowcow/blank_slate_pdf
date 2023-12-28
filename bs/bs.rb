require 'pathname'
require 'forwardable'
require_relative 'context'
require_relative '../_old/v2_configs/lib/point' # will change

module BS
  extend self

  def setup config={}
    $bs = BS::Context.new config # global is simpler than static
  end

  def generate
    [*$bs].each { |bs|
      Pathname(bs[:path]).mkpath unless Dir.exist? bs[:path]
      name = File.join bs[:path], "#{bs[:name]}.pdf"
      bs.pdf.render_file name
    }
  end

  def will_generate
    eval 'END { BS.generate }'
  end

  extend Forwardable
  delegate %i[ grid page pages ] => :$bs
end
