use crate::area::*;
use crate::grid::*;
use crate::page::*;
use crate::pdf::*;
use printpdf::*;

// ruler wtf: grid x setup of page

pub fn have_tick<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>, i: i32, overall: i32) {
    let ratio = i as f32 / (overall as f32 + 1.);
    let breadth = 12.;
    let x = ratio * breadth;
    line(pdf, page, x, pdf.grid.h, None, Some(pdf.grid.h - 0.1));
}

pub fn have_big_grid<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>) {
    let mut max_y = pdf.grid.h;

    for i in 1..=((max_y - 1.) as i32) {
        let y = i as f32;
        line(pdf, &page, 0., y, Some(pdf.grid.w), None);
    }
    for i in 1..=((pdf.grid.w) as i32 - 1) {
        let x = i as f32;
        line(pdf, &page, x, 0., None, Some(max_y - 1.));
    }
}

pub fn link<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>, area: Area, other: &Page<T>) {
    let doc = &pdf.doc;
    let current_layer = doc.get_page(page.page).get_layer(page.layer);

    let rect = printpdf::Rect::new(
        pdf.xx(area.x1),
        pdf.yy(area.y1),
        pdf.xx(area.x2),
        pdf.yy(area.y2),
    );
    current_layer.add_link_annotation(LinkAnnotation::new(
        rect,
        None,
        None,
        printpdf::Actions::go_to(Destination::XYZ {
            page: other.page,
            left: None,
            top: None,
            zoom: None,
        }),
        None,
    ));
}

pub fn center_text<T: Clone>(
    pdf: &mut PDF<T>,
    page: &Page<T>,
    text: &str,
    grid_x: f32,
    grid_y: f32,
) {
    let doc = &pdf.doc;
    let current_layer = doc.get_page(page.page).get_layer(page.layer);
    let font = doc.add_builtin_font(BuiltinFont::CourierOblique).unwrap();

    let size = 16.;
    let pad = 8.;
    let dx = text.chars().count() as f32 * 32.;
    let x = pdf.mm(pdf.x(grid_x) - dx / 2.); // - pad);
    let y = pdf.mm(pdf.y(grid_y) + pad / 2.);

    current_layer.use_text(text, size, x, y, &font);
}

pub fn circle<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>, x: f32, y: f32, r: f32) {
    let doc = &pdf.doc;
    let current_layer = doc.get_page(page.page).get_layer(page.layer);

    let dr = pdf.x(1.);
    let r = dr * r;

    let x = pdf.xx(x);
    let y = pdf.yy(y);
    let r = pdf.mm(r);

    use printpdf::path::{PaintMode, WindingOrder};
    use printpdf::*;

    let mode = PaintMode::Stroke;

    let line = Polygon {
        rings: vec![calculate_points_for_circle(r, x, y)],
        mode,
        winding_order: WindingOrder::EvenOdd,
    };
    current_layer.add_polygon(line);
}

pub fn hline<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>, y: f32, x1: Option<f32>, x2: Option<f32>) {
    let x1: f32 = x1.unwrap_or(0.);
    let x2: f32 = x2.unwrap_or(pdf.grid.w);
    line(pdf, page, x1, y, Some(x2), None);
}

pub fn vline<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>, x: f32, y1: Option<f32>, y2: Option<f32>) {
    let y1: f32 = y1.unwrap_or(0.);
    let y2: f32 = y2.unwrap_or(pdf.grid.h);
    line(pdf, page, x, y1, None, Some(y2));
}

pub fn line<T: Clone>(
    pdf: &mut PDF<T>,
    page: &Page<T>,
    x1: f32,
    y1: f32,
    x2: Option<f32>,
    y2: Option<f32>,
) {
    let x2 = x2.unwrap_or(x1);
    let y2 = y2.unwrap_or(y1);

    let doc = &pdf.doc;
    let current_layer = doc.get_page(page.page).get_layer(page.layer);

    let line = Line {
        points: vec![
            (Point::new(pdf.xx(x1), pdf.yy(y1)), false),
            (Point::new(pdf.xx(x2), pdf.yy(y2)), false),
        ],
        is_closed: false,
    };
    current_layer.add_line(line);
}

fn parse_color(given: &str) -> Color {
    let hex = given.trim().trim_start_matches('#');
    if hex.len() != 6 {
        return Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None));
    }

    let r = u8::from_str_radix(&hex[0..2], 16).unwrap_or(0);
    let g = u8::from_str_radix(&hex[2..4], 16).unwrap_or(0);
    let b = u8::from_str_radix(&hex[4..6], 16).unwrap_or(0);

    Color::Rgb(Rgb::new(
        r as f32 / 255.0,
        g as f32 / 255.0,
        b as f32 / 255.0,
        None,
    ))
}

pub fn line_color_hex<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>, value: &str) {
    let doc = &pdf.doc;
    let current_layer = doc.get_page(page.page).get_layer(page.layer);

    let color = parse_color(value);
    current_layer.set_outline_color(color);
}

pub fn font_color_hex<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>, value: &str) {
    let doc = &pdf.doc;
    let current_layer = doc.get_page(page.page).get_layer(page.layer);

    let color = parse_color(value);
    current_layer.set_fill_color(color);
}

pub fn thickness<T: Clone>(pdf: &mut PDF<T>, page: &Page<T>, value: f32) {
    let doc = &pdf.doc;
    let current_layer = doc.get_page(page.page).get_layer(page.layer);

    current_layer.set_outline_thickness(value);
}
