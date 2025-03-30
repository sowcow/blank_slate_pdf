END {
  make_image 'triangle.png', 10 unless File.exist? 'triangle.png'
  system "convert triangle.png -trim trimmed.png"
  system "convert trimmed.png -background transparent -gravity center -extent 7794x7794 square.png"
  system "convert square.png -resize 707x707 ready.png"

  system 'rm trimmed.png square.png'
}


require 'chunky_png'

def interpolate_color *a
  interpolate_color_rgb *a
end

def interpolate_color_rgb(color1, color2, factor)
  r = ((ChunkyPNG::Color.r(color1) * (1 - factor)) + (ChunkyPNG::Color.r(color2) * factor)).round
  g = ((ChunkyPNG::Color.g(color1) * (1 - factor)) + (ChunkyPNG::Color.g(color2) * factor)).round
  b = ((ChunkyPNG::Color.b(color1) * (1 - factor)) + (ChunkyPNG::Color.b(color2) * factor)).round
  ChunkyPNG::Color.rgb(r, g, b)
end

def draw_gradient_triangle(png, points, colors)
  x1, y1 = points[0]
  x2, y2 = points[1]
  x3, y3 = points[2]
  color1, color2, color3 = colors

  # Get bounding box
  min_x = [x1, x2, x3].min
  max_x = [x1, x2, x3].max
  min_y = [y1, y2, y3].min
  max_y = [y1, y2, y3].max

  (min_y..max_y).each do |y|
    (min_x..max_x).each do |x|
      # Calculate barycentric coordinates
      w1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)).to_f / ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3))
      w2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)).to_f / ((y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3))
      w3 = 1 - w1 - w2

      # Only draw if point is inside triangle
      if w1 >= 0 && w2 >= 0 && w3 >= 0
        # Interpolate colors based on barycentric coordinates
        color12 = interpolate_color(color1, color2, w2 / (w1 + w2)) if (w1 + w2) > 0
        final_color = if w3 == 1
          color3
        elsif w3 > 0
          interpolate_color(color12 || color1, color3, w3)
        else
          color12
        end
        
        png[x, y] = final_color if final_color && x >= 0 && x < png.width && y >= 0 && y < png.height
      end
    end
  end
end

def make_image file, scale=10
  width = 1000 * scale
  height = 1000 * scale
  png = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)

  dx = 500 * scale
  dy = 300 * scale
  side_length = 300 * scale
  hh = (Math.sqrt(3) * side_length / 2).round / 2

  points1 = [
    [dx, dy],
    [dx + side_length, dy],
    [dx + side_length/2, dy + 2*hh]  # Bottom
  ]
  colors1 = [
    ChunkyPNG::Color.rgb(255, 255, 255),
    ChunkyPNG::Color.rgb(255, 255, 0),
    ChunkyPNG::Color.rgb(0, 255, 0),
  ]
  draw_gradient_triangle(png, points1, colors1)

  points1 = [
    [dx - side_length, dy],
    [dx, dy],
    [dx - side_length/2, dy + 2*hh]  # Bottom
  ]
  colors1 = [
    ChunkyPNG::Color.rgb(255, 0, 0),
    ChunkyPNG::Color.rgb(255, 255, 255),
    ChunkyPNG::Color.rgb(255, 0, 255),
  ]
  draw_gradient_triangle(png, points1, colors1)

  ###

  dy +=1
  points1 = [
    [dx, dy],
    [dx + side_length, dy],
    [dx, dy - (Math.sqrt(3) * side_length / 2).round]  # Bottom
  ]
  colors1 = [
    ChunkyPNG::Color.rgb(255, 255, 255),
    ChunkyPNG::Color.rgb(255, 255, 0),
    ChunkyPNG::Color.rgb(255, 165, 0),
  ]
  draw_gradient_triangle(png, points1, colors1)

  points1 = [
    [dx - side_length, dy],
    [dx, dy],
    [dx, dy - (Math.sqrt(3) * side_length / 2).round]  # Bottom
  ]
  colors1 = [
    ChunkyPNG::Color.rgb(255, 0, 0),
    ChunkyPNG::Color.rgb(255, 255, 255),
    ChunkyPNG::Color.rgb(255, 165, 0),
  ]
  draw_gradient_triangle(png, points1, colors1)

  ##
  dy -= 1

  points1 = [
    [dx, dy],
    [dx - side_length/2, dy + 2*hh],
    [dx, dy + 4*hh]
  ]
  colors1 = [
    ChunkyPNG::Color.rgb(255, 255, 255),
    ChunkyPNG::Color.rgb(255, 0, 255),
    ChunkyPNG::Color.rgb(0, 0, 255),
  ]
  draw_gradient_triangle(png, points1, colors1)

  points1 = [
    [dx, dy],
    [dx + side_length/2, dy + 2*hh],
    [dx, dy + 4*hh]
  ]
  colors1 = [
    ChunkyPNG::Color.rgb(255, 255, 255),
    ChunkyPNG::Color.rgb(0, 255, 0),
    ChunkyPNG::Color.rgb(0, 0, 255),
  ]
  draw_gradient_triangle(png, points1, colors1)

  png.save(file, :interlace => false)
end
