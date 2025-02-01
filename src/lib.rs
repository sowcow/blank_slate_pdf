use printpdf::*;
use serde::{Deserialize, Serialize};
use wasm_bindgen::prelude::*;

// - probably abstract info/idea page from "-" page?
// 1. yaml single field form (could even use query param with that text to store in bookmark)
// 2. pages count control
// 3. template of main header
// 4. template of item header, separate

mod area;
mod grid;
mod page;
mod pdf;
mod render;
mod setup;

use area::*;
use grid::*;
use page::*;
use pdf::*;
use render::*;
use setup::*;

//unused:
//- bezier
//- dash patters
//- TOC/bookmark

// When the `wee_alloc` feature is enabled, use `wee_alloc` as the global
// allocator.
//#[cfg(feature = "wee_alloc")]
//#[global_allocator]
//static ALLOC: wee_alloc::WeeAlloc = wee_alloc::WeeAlloc::INIT;

#[derive(Deserialize, Serialize)]
struct Message {
    #[serde(with = "serde_bytes")]
    payload: Vec<u8>,
}

#[derive(Deserialize, Serialize)]
struct Input {
    title: String,
    line_thickness: String,
    grid_color: String,
    font_color: String,
    renamings: String,
    arrows: Option<String>,
    target: Option<String>,
    timetable: Option<String>,
}

type PageData = Option<String>;

#[wasm_bindgen]
pub fn create(given: JsValue) -> JsValue {
    use serde_wasm_bindgen::from_value;

    let input: Input = from_value(given).unwrap();

    let data: PageData = None;
    let mut pdf = PDF::new(&input.title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    // main alpha page is existing root page ("+" page)
    let page = pdf.page(0);
    let alpha_page = page.clone();

    let count_consecutive = 23;
    render_alpha(&pdf, page.clone(), grid.clone(), &input);
    render_tick(
        &pdf,
        page,
        grid.clone(),
        &input,
        1. / (count_consecutive as f32 + 1.),
    );
    // consecutive alpha pages
    for i in 2..=count_consecutive {
        let page = pdf.add_page(None);
        render_alpha(&pdf, page.clone(), grid.clone(), &input);
        render_tick(
            &pdf,
            page,
            grid.clone(),
            &input,
            i as f32 / (count_consecutive as f32 + 1.),
        );
    }

    // delta is "-" page
    let delta_page = pdf.add_page(None);
    render_delta(&pdf, delta_page.clone(), grid.clone(), &input);

    // delta pages that make 6x6=36 entries grid
    for yy in 0..6 {
        for xx in 0..6 {
            let count_consecutive = 11;
            let mut pages = vec![];
            for i in 1..=count_consecutive {
                let subheader = (xx + yy * 6 + 1).to_string();
                let subheader = renamings(&subheader, &input.renamings).to_string();
                let page = pdf.add_page(Some(subheader));
                pages.push(page.clone());

                let with_targets = input.arrows.is_some() || input.target.is_some();
                let both = with_targets && input.timetable.is_some();
                let one = with_targets || input.timetable.is_some();

                // iterator composition is the way
                if both {
                    if i == 1 {
                        render_targets(&pdf, page.clone(), grid.clone(), &input);
                        render_delta_entry(&pdf, page.clone(), grid.clone(), &input, true, false);
                    } else if i == 2 {
                        render_delta_entry(&pdf, page.clone(), grid.clone(), &input, false, true);
                    } else {
                        render_delta_entry(&pdf, page.clone(), grid.clone(), &input, false, false);
                    }
                } else if one {
                    if i == 1 {
                        if input.arrows.is_some() {
                            render_targets(&pdf, page.clone(), grid.clone(), &input);
                            render_delta_entry(
                                &pdf,
                                page.clone(),
                                grid.clone(),
                                &input,
                                true,
                                false,
                            );
                        } else if input.target.is_some() {
                            render_single_target(&pdf, page.clone(), grid.clone(), &input);
                        } else {
                            render_delta_entry(
                                &pdf,
                                page.clone(),
                                grid.clone(),
                                &input,
                                false,
                                true,
                            );
                        }
                    } else {
                        render_delta_entry(&pdf, page.clone(), grid.clone(), &input, false, false);
                    }
                } else {
                    render_delta_entry(&pdf, page.clone(), grid.clone(), &input, false, false);
                }

                render_tick(
                    &pdf,
                    page,
                    grid.clone(),
                    &input,
                    i as f32 / (count_consecutive as f32 + 1.),
                );
            }
            let page = &pages[0];

            // link from grid into the entry
            let mut render = Render::new(&pdf, delta_page.clone(), grid.clone());
            render.line_color_hex(&input.grid_color);
            render.font_color_hex(&input.font_color);
            let size = 2.;
            let x = xx as f32;
            let y = yy as f32;
            let door = Area::xywh(x * size, 13. - y * size, size, size);
            render.link(&page, door.clone());
            render.corner_text(&page.data.clone().unwrap(), door.x2, door.y1);
        }
    }

    // after all pages are there,
    // render header and navigation for all pages
    //
    for page in pdf.pages.iter() {
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        let data = page.data.clone();
        let title = if let Some(subheader) = data {
            if input.title == "" {
                format!("{}", subheader)
            } else {
                format!("{} - {}", &input.title, subheader)
            }
        } else {
            input.title.clone()
        };
        render.header(&title);
        render.header_link(
            &alpha_page,
            "-",
            Area::xywh(12. - 1.5, 16., -1.5, -1. + 0.02),
        );
        render.header_link(&delta_page, "+", Area::xywh(12., 16., -1.5, -1. + 0.02));
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

fn renamings<'a>(given_value: &'a str, renamings: &'a str) -> &'a str {
    for line in renamings.lines() {
        if let Some((key, value)) = line.split_once("-") {
            let key = key.trim();
            let value = value.trim();
            if given_value == key {
                return value; // first renaming applies
            }
        }
    }
    given_value // as is
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        let title = "Project name";

        let pdf = PDF::new(title, Setup::rm_pro());
        let grid = Grid::new(12., 16.);

        let page = pdf.pages.get(0).unwrap().clone();
        let render = Render::new(pdf, page, grid);
        render.line(0., 0., 6., 6.);
    }
}

fn parse_thickness(str: &str) -> f32 {
    let got: f32 = str.parse().unwrap_or(0.5); // line thickness
    got
}

fn render_delta(pdf: &PDF<PageData>, page: Page<PageData>, grid: Grid, input: &Input) {
    let mut render = Render::new(pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));
    let mut min_y = grid.h;
    let mut max_y = 0.;
    for i in 0..=6 {
        let y = grid.h - 1. - (i as f32) * 2.;
        if y > max_y {
            max_y = y
        }
        if y < min_y {
            min_y = y
        }
        render.line(0., y, render.grid.w, y);
    }
    for i in 1..=5 {
        let x = (i as f32) * 2.;
        render.line(x, min_y, x, max_y);
    }
}

// alpha page bg-grid
// double denseness of bg-grid compared to general measurement grid
fn render_alpha(pdf: &PDF<PageData>, page: Page<PageData>, grid: Grid, input: &Input) {
    let mut render = Render::new(pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    for y in 1..=(render.grid.h - 1.) as usize {
        render.line(0., y as f32, render.grid.w, y as f32);
    }
}

// pagination tick-mark
fn render_tick(pdf: &PDF<PageData>, page: Page<PageData>, grid: Grid, input: &Input, ratio: f32) {
    let mut render = Render::new(pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    let breadth = 12.;
    let x = ratio * breadth;
    render.thickness(parse_thickness(&input.line_thickness));
    render.line(x, render.grid.h, x, render.grid.h - 0.1);
}

// page bg
fn render_delta_entry(
    pdf: &PDF<PageData>,
    page: Page<PageData>,
    grid: Grid,
    input: &Input,
    // too lazy for new type
    arrows_page: bool,
    timetable_page: bool,
) {
    if timetable_page {
        render_timetable(&pdf, page, grid, input);
        return;
    }

    let mut render = Render::new(pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    let mut max_y = render.grid.h;
    if arrows_page {
        max_y -= 11.;
    }

    if arrows_page && input.timetable.is_some() {
        // just lines as on the following page
        for y in 1..=4 {
            render.line(0., y as f32, render.grid.w, y as f32);
        }
        return;
    }

    for i in 1..=((max_y - 1.) as i32 * 2) {
        let y = (i as f32) / 2.;
        render.line(0., y, render.grid.w, y);
    }
    for i in 1..=((render.grid.w) as i32 * 2 - 1) {
        let x = (i as f32) / 2.;
        render.line(x, 0., x, max_y - 1.);
    }
}

fn render_targets(pdf: &PDF<PageData>, page: Page<PageData>, grid: Grid, input: &Input) {
    let mut render = Render::new(pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.thickness(parse_thickness(&input.line_thickness));
    let r = 2.8;
    let dx = 0.10;
    render.archer_target(6., 12., r);
    render.archer_target(3. + dx, 7., r);
    render.archer_target(9. - dx, 7., r);
}

fn render_single_target(pdf: &PDF<PageData>, page: Page<PageData>, grid: Grid, input: &Input) {
    let mut render = Render::new(pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.thickness(parse_thickness(&input.line_thickness));
    let r = 4.; // less in-your-face that 5.
    render.archer_target(6., 8., r);
}

static RADIUS_OPTIONS: [f32; 3] = [5., 10., 15.];

fn mark_radius() -> f32 {
    use rand::seq::SliceRandom;
    use rand::thread_rng;
    use wasm_bindgen::prelude::*;

    let mut rng = thread_rng();
    *RADIUS_OPTIONS.choose(&mut rng).unwrap()
}

fn render_timetable(pdf: &PDF<PageData>, page: Page<PageData>, grid: Grid, input: &Input) {
    let mut render = Render::new(pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    // horizontal lines
    for y in 1..=(render.grid.h - 1.) as usize {
        render.line(0., y as f32, render.grid.w, y as f32);
    }

    // alternating pattern for lines
    let x1 = render.grid.w / 4.;
    let x2 = render.grid.w / 2.;
    let x3 = render.grid.w * 3. / 4.;
    let text_x = render.grid.w;

    use std::collections::HashMap;
    let mut mapping = HashMap::new();
    let start_hour = 6;
    let start_y = (render.grid.h - 2.) as usize;
    for i in 0..=12 {
        let hour = start_hour + i;
        //let mut hour = (start_hour + i) % 12;
        //if hour == 0 {
        //    hour = 12;
        //}
        let y = start_y - i;
        mapping.insert(y, hour);
    }

    for y in 1..=(render.grid.h - 1.) as usize {
        if y % 2 != 0 {
            render.circle(x1, y as f32 - 0.5, mark_radius());
            render.circle(x3, y as f32 - 0.5, mark_radius());
        } else {
            render.circle(x2, y as f32 - 0.5, mark_radius());
        }
        if let Some(value) = mapping.get(&(y as usize)) {
            let text = value.to_string();
            render.line_text(&text, text_x, 0.33 + y as f32);
        }
    }
}
