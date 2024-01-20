require 'color'
require 'pathname'
require 'forwardable'
require_relative 'context'
require_relative '../_old/v2_configs/lib/point' # will change

# on pdf it is transparent to see through it
def lighter_color rgb
  #cc = "rgba(#{rgb[0]}, #{rgb[1]}, #{rgb[2]}, 0.5)"
  #require 'pry'; binding.pry
  cc = Color::RGB.new(*rgb)
  cc = cc.lighten_by(50)
end

module BS
  extend self

  def setup config={}
    $bs = BS::Context.new config # global is simpler than static
  end

  def generate
    # actually does not make sense
    #[*$bs].each { |bs|
    bs = $bs
      Pathname(bs[:path]).mkpath unless Dir.exist? bs[:path]
      name = File.join bs[:path], "#{bs[:name]}.pdf"
      #result_colored_name = File.join bs[:path], "COLOR_#{bs[:name]}.pdf"
      bs.pdf.render_file name

      if $colored
        tags = {}
        pages.each_with_index { |x, i|
          if !tags[x.tag]
            tags[x.tag] = x
          end
        }
        page_by_tag = {}
        tags.each { |tag_name, page|
          page_by_tag[tag_name] = page
          number = page.page_number - 1
          img_name = File.join bs[:path], "#{tag_name}.png"
          scaled_name = File.join bs[:path], "#{tag_name}-scaled.png"
          cmd = "convert -density 200 #{name.inspect}[#{number}] -background white -alpha remove -alpha off #{img_name.inspect}"
          system cmd
          col = $tag_colors[tag_name]
          stuff = if col
          rgb = col.rgb
          cc = lighter_color rgb
          cc = cc.to_a.map { |x| x * 255 }
          cc = "rgb(#{cc[0]}, #{cc[1]}, #{cc[2]})"
          cc
                  else
                    'rgb(128, 128, 128)'
                  end
          cmd = "convert #{img_name.inspect} -resize 500x -bordercolor '#{stuff}' -border 30 #{scaled_name.inspect}"
          system cmd
        }
        arrows = []
        tags.each { |tag_name, page|
          links = page.local[:links] || []
          other_names = links.map { |x| x.tag }.uniq
          other_names.each { |x|
            arrows << [tag_name, x] unless tag_name == x
          }
        }
        repeated = []
        seen = []
        arrows.each { |(a,b)|
          if seen.include? b
            repeated << [a, b]
          end
          seen << a
          seen << b
        }
        arrows.reject! { |x| repeated.include? x }
        # it seems it generates parent-child...
        #doubled = arrows.select { |(a, b)| arrows.include? [b, a] }
        #arrows.reject! { |x| doubled.include? x }
        nodes = arrows.flatten.uniq
        dot = <<-END.strip
digraph {
#{ nodes.map { |a|
        count = page_by_tag[a].local[:pages]
        label = a.to_s.tr(?_,' ')
        if count
          label << "\n→#{count}"
        end
        %'"#{a}"[image="#{a}-scaled.png" label=#{label.inspect} shape=none fontsize="60pt"]'
} * "\n"}
#{ arrows.map { |(a,b)|
  col = $tag_colors[b]
  stuff = if col
    rgb = col.rgb
    cc = lighter_color rgb
    cc.html
                  else
                    'rgb(128, 128, 128)' # unlinked page
                  end
  %'"#{a}" -> "#{b}" [arrowsize=5 color="#{stuff}" penwidth=5]'
} * "\n"}
}
        END
        dot_file = "dot.dot"
        Dir.chdir bs[:path] do
          File.write dot_file, dot
          system "dot -Tpng #{dot_file.inspect} -o #{bs[:name]}.png"

          system 'rm dot.dot'
          nodes.each { |name|
            system %'rm #{name}.png #{name}-scaled.png'
          }
          #system %'cp #{name.inspect} #{result_colored_name.inspect}'
        end
      end
    #}
    BS.reset
  end

  def will_generate
    eval 'END { BS.generate }'
  end

  # could move those globals into some contextual bs.state?
  def reset
    $tag_colors = nil
    $color_generator_position = 0
  end

  extend Forwardable
  delegate %i[ grid page pages xs ] => :$bs
end
