require_relative 'bs/all'
BS.will_generate if __FILE__ == $0

draw_squares = -> {
  at = [
    Pos[0, 0],
    Pos[0, 6],
    Pos[0, 12],
    Pos[6, 0],
    Pos[6, 6],
    Pos[6, 12],
  ]
  $bs.color 8 do
    at.each { |pos|
      sq = Square.sized(pos.x, pos.y, 6)
      $bs.poly *sq.points.map { |x| g.at *x }
    }
  end
}
draw_dots_in_square = -> pos {
  5.times { |x|
    5.times { |y|
      $bs.dot Pos[pos.x + x + 1, pos.y + y + 1]
    }
  }
}
draw_squares_dotted = -> {
  draw_squares.call
  all_squares = [
    Point[6, 0],
    Point[0, 6],
    Point[6, 12],
    Point[0, 0],
    Point[6, 6],
    Point[0, 12],
  ]
  all_squares.each { |pos|
    draw_dots_in_square.call pos
  }
}
draw_squares_chess = -> {
  draw_squares.call

  lines = 5.times.map { |i|
    [Pos[0, i+1], Pos[6, i+1]]
  } + 5.times.map { |i|
    [Pos[i+1, 0], Pos[i+1, 6]]
  }
  squares = [
    Point[6, 0],
    Point[0, 6],
    Point[6, 12],
  ]
  $bs.color 8 do
    squares.each { |pos|
      lines.each { |points|
        $bs.poly *points.map { |x| x + pos }.map { |x| g.at *x }
      }
    }
  end
  other_squares = [
    Point[0, 0],
    Point[6, 6],
    Point[0, 12],
  ]
  other_squares.each { |pos|
    draw_dots_in_square.call pos
  }
}

path = File.join __dir__, 'output'
BS.setup name: '6BS', path: path, description: <<END
  Six Big Squares.
  Quite versatile in potential.
  Right items have checklist flavour.
  ---
  UI patterns:
  - RM user should have toolbar closed
  - file-scoped notes are above the grid
  - items can be found outside the grid at sides
  - item-scoped corner notes are in the upper-right corner of the grid
  - pagination is not UI-interactive, only page turning is meant
END
BS.grid 18

BS.page :root do
  draw_dots
end

is_left = -> page { page[:item_pos].x == -1 }
BS::Items.generate left: 18, right: 3 do
  if is_left[page]
    page.tag = :left_item
    draw_squares_dotted.call
  else
    BS::Pagination.generate page do
      page.tag = :right_item
      draw_squares_chess.call
    end
  end
end

a = $bs.g.tr
corners = []
corners << a
corners << a.down(6)
corners << a.down(12)
corners << a.left(6)
corners << a.down(6).left(6)
corners << a.down(12).left(6)

left_items = BS.pages.xs(:item).select &is_left
left_items.each { |page|
  corners.each { |corner|
    BS::CornerNotes.generate page, corner: corner do
      draw_dots
    end
  }
}

BS::TopNotes.generate do
  draw_stars
end

BS::Items.integrate
BS::TopNotes.integrate
