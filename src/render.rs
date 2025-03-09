use crate::area::*;
use crate::grid::*;
use crate::page::*;
use crate::pdf::*;
use printpdf::*;

#[derive(Clone)]
pub struct Render<'a, T: Clone> {
    pub pdf: &'a PDF<T>,
    pub page: Page<T>,
    pub grid: Grid,
    pub thick: f32,
    pub line_color: Color,
    pub font_color: Color,
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

impl<'a, T: Clone> Render<'a, T> {
    pub fn thickness(&mut self, value: f32) {
        self.thick = value;
    }

    pub fn line_color_hex(&mut self, value: &str) {
        self.line_color = parse_color(value);
    }

    pub fn font_color_hex(&mut self, value: &str) {
        self.font_color = parse_color(value);
    }

    pub fn x(&self, value: f32) -> f32 {
        let cell_w = self.pdf.setup.width as f32 / self.grid.w;
        value * cell_w
    }

    pub fn y(&self, value: f32) -> f32 {
        let cell_h = self.pdf.setup.height as f32 / self.grid.h;
        value * cell_h
    }

    pub fn mm(&self, value: f32) -> Mm {
        Mm(self.pdf.setup.mm(value))
    }

    pub fn new(pdf: &'a PDF<T>, page: Page<T>, grid: Grid) -> Self {
        Self {
            pdf,
            page,
            grid,
            thick: 1.,
            line_color: Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None)),
            font_color: Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None)),
        }
    }

    pub fn link(&self, other: &Page<T>, area: Area) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);

        let rect = printpdf::Rect::new(
            self.mm(self.x(area.x1)),
            self.mm(self.y(area.y1)),
            self.mm(self.x(area.x2)),
            self.mm(self.y(area.y2)),
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

    pub fn header_link(&self, other: &Page<T>, text: &str, area: Area) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);

        let font = doc.add_builtin_font(BuiltinFont::Symbol).unwrap();
        let x = self.mm(self.x(area.x1 + area.w() / 2.) - 28.);
        let y = self.mm(self.y(area.y1) + 37.);
        let color = self.font_color.clone();
        current_layer.set_fill_color(color);
        current_layer.use_text(text, 32., x, y, &font);

        let rect = printpdf::Rect::new(
            self.mm(self.x(area.x1)),
            self.mm(self.y(area.y1)),
            self.mm(self.x(area.x2)),
            self.mm(self.y(area.y2)),
        );
        current_layer.add_link_annotation(LinkAnnotation::new(
            rect,
            Some(printpdf::BorderArray::default()),
            Some(printpdf::ColorArray::default()),
            printpdf::Actions::go_to(Destination::XYZ {
                page: other.page,
                left: None,
                top: None,
                zoom: None,
            }),
            Some(printpdf::HighlightingMode::Invert),
        ));
    }

    // I use one corner for content stuff in PDFs - bottom-right
    pub fn corner_text(&self, text: &str, grid_x: f32, grid_y: f32) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);

        let font = doc.add_builtin_font(BuiltinFont::CourierOblique).unwrap();

        let size = 16.;
        let pad = 2.;
        let dx = text.chars().count() as f32 * 32.;
        let x = self.mm(self.x(grid_x) - dx); // - pad);
        let y = self.mm(self.y(grid_y) + pad);

        let color = self.font_color.clone();
        current_layer.set_fill_color(color);
        current_layer.use_text(text, size, x, y, &font);
    }

    pub fn header(&self, text: &str) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);

        let font = doc.add_builtin_font(BuiltinFont::CourierOblique).unwrap();

        let step = self.pdf.setup.width / self.grid.w;
        let size = 32.;
        let x = self.mm(step);
        let y = self.mm(self.pdf.setup.height - step + 37.);

        let color = self.font_color.clone();
        current_layer.set_fill_color(color);
        current_layer.use_text(text, size, x, y, &font);
    }

    pub fn line(&self, x1: f32, y1: f32, x2: f32, y2: f32) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);

        let points = vec![
            (Point::new(self.mm(self.x(x1)), self.mm(self.y(y1))), false),
            (Point::new(self.mm(self.x(x2)), self.mm(self.y(y2))), false),
        ];

        let line1 = Line {
            points,
            is_closed: false,
        };

        let color = self.line_color.clone();
        current_layer.set_outline_color(color);
        current_layer.set_outline_thickness(self.thick);
        current_layer.add_line(line1);
    }

    pub fn archer_target(&self, x1: f32, y1: f32, r1: f32) {
        use printpdf::path::{PaintMode, WindingOrder};
        use printpdf::*;

        let doc = &self.pdf.doc;
        let x = self.mm(self.x(x1));
        let y = self.mm(self.y(y1));
        let dr1 = self.x(r1);
        let dr2 = self.x(r1 * 2.);
        let r = self.mm(dr2 - dr1);

        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);

        // gold     red      blue
        // #FFE552, #F65058, #00B4E4

        //let outline1 = parse_color("aaaaaa");
        let outline2 = parse_color("888888");
        let rr = r / 10.; // radius step
        let mut circles = vec![
            //Ring {
            //    r: rr,
            //    color: parse_color("ffe552"),
            //    outline: &outline1,
            //},
            Ring {
                r: rr * 2.,
                color: parse_color("ffe552"),
                outline: &outline2,
            },
            //Ring {
            //    r: rr * 3.,
            //    color: parse_color("f65058"),
            //    outline: &outline1,
            //},
            Ring {
                r: rr * 4.,
                color: parse_color("f65058"),
                outline: &outline2,
            },
            //Ring {
            //    r: rr * 5.,
            //    color: parse_color("00b4e5"),
            //    outline: &outline1,
            //},
            Ring {
                r: rr * 6.,
                color: parse_color("00b4e5"),
                outline: &outline2,
            },
            //Ring {
            //    r: rr * 7.,
            //    color: parse_color("cccccc"),
            //    outline: &outline1,
            //},
            Ring {
                r: rr * 8.,
                //color: parse_color("888888"),
                //color: parse_color("a6a6a6"),
                color: parse_color("cccccc"),
                outline: &outline2,
            },
            //Ring {
            //    r: rr * 9.,
            //    color: parse_color("ffffff"),
            //    outline: &outline1,
            //},
            Ring {
                r: rr * 10.,
                color: parse_color("ffffff"),
                outline: &outline2,
            },
        ];
        circles.sort_by(|a, b| b.r.cmp(&a.r));

        for (index, one) in circles.iter().enumerate() {
            let mode = if index == 0 {
                PaintMode::FillStroke
            } else {
                PaintMode::Fill
            };

            let line = Polygon {
                rings: vec![calculate_points_for_circle(one.r, x, y)],
                mode,
                winding_order: WindingOrder::EvenOdd,
            };
            current_layer.set_outline_color(one.outline.clone());
            current_layer.set_fill_color(one.color.clone());
            current_layer.set_outline_thickness(0.5); //self.thick);
            current_layer.add_polygon(line);
        }
    }

    #[inline]
    pub fn calculate_points_for_half_circle<P: Into<Pt>>(
        radius: P,
        offset_x: P,
        offset_y: P,
    ) -> Vec<(Point, bool)> {
        // PDF doesn't understand what a "circle" is, so we have to
        // approximate it.
        let C: f32 = 0.551915024494;

        let (radius, offset_x, offset_y) = (radius.into(), offset_x.into(), offset_y.into());
        let radius = radius.0;

        let p10 = Point {
            x: Pt(0.0 * radius),
            y: Pt(1.0 * radius),
        };
        let p11 = Point {
            x: Pt(C * radius),
            y: Pt(1.0 * radius),
        };
        let p12 = Point {
            x: Pt(1.0 * radius),
            y: Pt(C * radius),
        };
        let p13 = Point {
            x: Pt(1.0 * radius),
            y: Pt(0.0 * radius),
        };

        let p20 = Point {
            x: Pt(1.0 * radius),
            y: Pt(0.0 * radius),
        };
        let p21 = Point {
            x: Pt(1.0 * radius),
            y: Pt(-C * radius),
        };
        let p22 = Point {
            x: Pt(C * radius),
            y: Pt(-1.0 * radius),
        };
        let p23 = Point {
            x: Pt(0.0 * radius),
            y: Pt(-1.0 * radius),
        };

        let p30 = Point {
            x: Pt(0.0 * radius),
            y: Pt(-1.0 * radius),
        };
        let p31 = Point {
            x: Pt(-C * radius),
            y: Pt(-1.0 * radius),
        };
        let p32 = Point {
            x: Pt(-1.0 * radius),
            y: Pt(-C * radius),
        };
        let p33 = Point {
            x: Pt(-1.0 * radius),
            y: Pt(0.0 * radius),
        };

        let p40 = Point {
            x: Pt(-1.0 * radius),
            y: Pt(0.0 * radius),
        };
        let p41 = Point {
            x: Pt(-1.0 * radius),
            y: Pt(C * radius),
        };
        let p42 = Point {
            x: Pt(-C * radius),
            y: Pt(1.0 * radius),
        };
        let p43 = Point {
            x: Pt(0.0 * radius),
            y: Pt(1.0 * radius),
        };

        let mut pts = vec![
            (p10, true),
            (p11, true),
            (p12, true),
            (p13, false),
            (p20, true),
            (p21, true),
            (p22, true),
            (p23, false),
            //(p30, true),
            //(p31, true),
            //(p32, true),
            //(p33, false),
            //(p40, true),
            //(p41, true),
            //(p42, true),
            //(p43, false),
        ];

        for &mut (ref mut p, _) in pts.iter_mut() {
            p.x.0 += offset_x.0;
            p.y.0 += offset_y.0;
        }

        pts
    }

    pub fn half_circle(&self, x: f32, y: f32, r: f32) {
        let dr = self.x(1.);
        let r = dr * r;

        let x = self.mm(self.x(x));
        let y = self.mm(self.y(y));
        let r = self.mm(r);

        //let dr = self.mm(dr2 - dr1);
        //let r = selfr * dr;
        //self.circle(x, y, r * dr);

        use printpdf::path::{PaintMode, WindingOrder};
        use printpdf::*;

        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);
        let mode = PaintMode::Stroke;

        let line = Polygon {
            rings: vec![Self::calculate_points_for_half_circle(r, x, y)],
            mode,
            winding_order: WindingOrder::EvenOdd,
        };
        let color = self.line_color.clone();
        current_layer.set_outline_color(color.clone());
        current_layer.set_outline_thickness(1.); //self.thick);
        current_layer.add_polygon(line);
    }

    pub fn circle_omg(&self, x: f32, y: f32, r: f32) {
        let dr = self.x(1.);
        let r = dr * r;

        let x = self.mm(self.x(x));
        let y = self.mm(self.y(y));
        let r = self.mm(r);

        //let dr = self.mm(dr2 - dr1);
        //let r = selfr * dr;
        //self.circle(x, y, r * dr);

        use printpdf::path::{PaintMode, WindingOrder};
        use printpdf::*;

        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);
        let mode = PaintMode::Stroke;

        let line = Polygon {
            rings: vec![calculate_points_for_circle(r, x, y)],
            mode,
            winding_order: WindingOrder::EvenOdd,
        };
        let color = self.line_color.clone();
        current_layer.set_outline_color(color.clone());
        current_layer.set_outline_thickness(1.); //self.thick);
        current_layer.add_polygon(line);
    }

    pub fn circle(&self, x: f32, y: f32, r: f32) {
        use printpdf::path::{PaintMode, WindingOrder};
        use printpdf::*;

        let doc = &self.pdf.doc;
        let x = self.mm(self.x(x));
        let y = self.mm(self.y(y));
        let r = self.mm(r);

        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);

        let mode = if flip_coin() {
            PaintMode::Fill
        } else {
            PaintMode::Stroke
        };

        let line = Polygon {
            rings: vec![calculate_points_for_circle(r, x, y)],
            mode,
            winding_order: WindingOrder::EvenOdd,
        };
        let color = self.line_color.clone();

        current_layer.set_fill_color(color.clone());
        current_layer.set_outline_color(color.clone());
        current_layer.set_outline_thickness(2.); //self.thick);
        current_layer.add_polygon(line);
    }

    pub fn line_text(&self, text: &str, grid_x: f32, grid_y: f32) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);
        let font = doc.add_builtin_font(BuiltinFont::CourierOblique).unwrap();

        let size = 16.;
        let pad = 8.;
        let dx = text.chars().count() as f32 * 32.;
        let x = self.mm(self.x(grid_x) - dx); // - pad);
        let y = self.mm(self.y(grid_y) + pad);

        let color = self.font_color.clone();
        current_layer.set_fill_color(color);
        current_layer.use_text(text, size, x, y, &font);
    }

    pub fn line_start_text(&self, text: &str, grid_x: f32, grid_y: f32) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);
        let font = doc.add_builtin_font(BuiltinFont::CourierOblique).unwrap();

        let size = 16.;
        let pad = 8.;
        let dx = 0.;
        let x = self.mm(self.x(grid_x) - dx); // - pad);
        let y = self.mm(self.y(grid_y) + pad);

        let color = self.font_color.clone();
        current_layer.set_fill_color(color);
        current_layer.use_text(text, size, x, y, &font);
    }

    pub fn center_text(&self, text: &str, grid_x: f32, grid_y: f32) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);
        let font = doc.add_builtin_font(BuiltinFont::CourierOblique).unwrap();

        let size = 16.;
        let pad = 8.;
        let dx = text.chars().count() as f32 * 32.;
        let x = self.mm(self.x(grid_x) - dx / 2.); // - pad);
        let y = self.mm(self.y(grid_y) + pad / 2.);

        let color = self.font_color.clone();
        current_layer.set_fill_color(color);
        current_layer.use_text(text, size, x, y, &font);
    }
    pub fn sm_center_text(&self, text: &str, grid_x: f32, grid_y: f32) {
        let doc = &self.pdf.doc;
        let current_layer = doc.get_page(self.page.page).get_layer(self.page.layer);
        let font = doc.add_builtin_font(BuiltinFont::CourierOblique).unwrap();

        let size = 12.;
        let pad = 10.;
        let dx = text.chars().count() as f32 * size * 2.;
        let x = self.mm(self.x(grid_x) - dx / 2.); // - pad);
        let y = self.mm(self.y(grid_y) + pad / 2.);

        let color = self.font_color.clone();
        current_layer.set_fill_color(color);
        current_layer.use_text(text, size, x, y, &font);
    }

    pub fn hline(&self, y: f32, x1: Option<f32>, x2: Option<f32>) {
        let x1: f32 = x1.unwrap_or(0.);
        let x2: f32 = x2.unwrap_or(self.grid.w);
        self.line(x1, y, x2, y);
    }

    pub fn vline(&self, x: f32, y1: Option<f32>, y2: Option<f32>) {
        let y1: f32 = y1.unwrap_or(0.);
        let y2: f32 = y2.unwrap_or(self.grid.h);
        self.line(x, y1, x, y2);
    }
}

fn flip_coin() -> bool {
    use rand::thread_rng;
    use rand::Rng;
    use wasm_bindgen::prelude::*;
    let mut rng = thread_rng();
    rng.gen_bool(0.5)
}

struct Ring<'a> {
    r: Mm,
    color: Color,
    outline: &'a Color,
}
