use crate::area::*;
use crate::grid::*;
use crate::page::*;
use crate::pdf::*;
use printpdf::*;

pub struct Render<'a, T: Clone> {
    pub pdf: &'a PDF<T>,
    pub page: Page<T>,
    pub grid: Grid,
    pub thick: f32,
    pub line_color: Color,
    pub font_color: Color,
}

fn parse_color(given: &str) -> Color {
    let hex = given.trim();
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
}
