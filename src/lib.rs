#![allow(warnings)]

// extern crate web_sys;

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
mod new_render;
mod page;
mod pdf;
mod render;
mod setup;

use area::*;
use grid::*;
use new_render::*;
use page::*;
use pdf::*;
use render::*;
use setup::*;

use std::f32::consts::PI;

//unused:
//- bezier
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
    balance: Option<String>,
    five: Option<String>,
    plus: Option<String>,
    figure: Option<String>,
    empty_pages: Option<String>,
    square: Option<String>,
    hal: Option<String>,
    sink: Option<String>,
}

#[derive(Deserialize, Serialize)]
struct Input123 {
    action: String,
    title: String,
    line_thickness: String,
    grid_color: String,
    font_color: String,
}

#[derive(Deserialize, Serialize)]
struct InputTeeth {
    teeth_pages: Option<String>,
    hal_pages: Option<String>,
    sandworm_pages: Option<String>,
    action: String,
    title: String,
    line_thickness: String,
    grid_color: String,
    font_color: String,
}
// t { teeth_pages: "on", title: "", line_thickness: "0.5", grid_color: "444444", font_color: "000000", action: "" }

type PageData = Option<String>;

#[wasm_bindgen]
pub fn create(given: JsValue) -> JsValue {
    use serde_wasm_bindgen::from_value;

    let input: Input = from_value(given).unwrap();

    let data: PageData = None;
    let mut pdf = PDF::new(&input.title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    // main alpha page is existing root page ("-" page)
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

    // delta is "+" page
    let delta_page = pdf.add_page(None);
    render_delta(&pdf, delta_page.clone(), grid.clone(), &input);

    #[derive(Default)]
    struct Planned {
        timetable: Option<bool>,
        balance: Option<bool>,
        five: Option<bool>,
        plus: Option<bool>,
        figure: Option<bool>,
        target: Option<bool>,
        arrows: Option<bool>,
        empty: Option<bool>,
        square: Option<bool>,
        hal: Option<bool>,
        sink: Option<bool>,
    }
    let mut plan: Vec<Planned> = vec![];

    // (ordered these things, optimizing to not have double-jumps in key use cases)
    // - time decomposition (goes first since it could have appointment entries)
    // first)
    // - faculties decomposition (balance, habits type of thing)
    // - focus pages (target/arrows) (goes as review page, if previous are used, they should be
    // more valuable as overview/summary since they are single pages and are detailed,
    // not to say that drawing an arrow can be done on any page given RM-PRO colors and transparent
    // tools)
    //
    if input.timetable.is_some() {
        plan.push(Planned {
            timetable: Some(true),
            ..Default::default()
        });
    }
    if input.balance.is_some() {
        plan.push(Planned {
            balance: Some(true),
            ..Default::default()
        });
    }
    if input.five.is_some() {
        plan.push(Planned {
            five: Some(true),
            ..Default::default()
        });
    }
    if input.plus.is_some() {
        plan.push(Planned {
            plus: Some(true),
            ..Default::default()
        });
    }
    if input.figure.is_some() {
        plan.push(Planned {
            figure: Some(true),
            ..Default::default()
        });
    }
    if input.square.is_some() {
        plan.push(Planned {
            square: Some(true),
            ..Default::default()
        });
    }
    if input.hal.is_some() {
        plan.push(Planned {
            hal: Some(true),
            ..Default::default()
        });
    }
    if input.target.is_some() {
        plan.push(Planned {
            target: Some(true),
            ..Default::default()
        });
    }
    if input.arrows.is_some() {
        plan.push(Planned {
            arrows: Some(true),
            ..Default::default()
        });
    }
    if input.sink.is_some() {
        plan.push(Planned {
            sink: Some(true),
            ..Default::default()
        });
    }
    if input.empty_pages.is_some() {
        let count_goal = 11;
        for x in (plan.len() + 1)..=count_goal {
            plan.push(Planned {
                empty: Some(true),
                ..Default::default()
            });
        }
    }

    // delta pages that make 6x6=36 entries grid
    for yy in 0..6 {
        for xx in 0..6 {
            let mut pages = vec![];
            let count_consecutive = plan.len();
            for (ii, planned) in plan.iter().enumerate() {
                let i = ii + 1;
                let subheader = (xx + yy * 6 + 1).to_string();
                let subheader = renamings(&subheader, &input.renamings).to_string();
                let page = pdf.add_page(Some(subheader));
                pages.push(page.clone());

                if planned.timetable.is_some() {
                    render_delta_entry(&pdf, page.clone(), grid.clone(), &input, false, true);
                } else if planned.balance.is_some() {
                    let mut render = Render::new(&pdf, page.clone(), grid.clone());
                    render.line_color_hex(&input.grid_color);
                    render.font_color_hex(&input.font_color);
                    render.thickness(parse_thickness(&input.line_thickness));
                    let mut page = page.clone();
                    render_faculties(&mut page, render);
                } else if planned.five.is_some() {
                    render_five(page.clone(), &mut pdf, &input, grid.clone());
                } else if planned.figure.is_some() {
                    render_figure(page.clone(), &mut pdf, &input, grid.clone());
                } else if planned.plus.is_some() {
                    render_plus(page.clone(), &mut pdf, &input, grid.clone());
                } else if planned.square.is_some() {
                    let mut render = Render::new(&pdf, page.clone(), grid.clone());
                    render.line_color_hex(&input.grid_color);
                    render.font_color_hex(&input.font_color);
                    render.thickness(parse_thickness(&input.line_thickness));

                    let mut page = page.clone();
                    render_square(&mut page, render);
                } else if planned.hal.is_some() {
                    let mut render = Render::new(&pdf, page.clone(), grid.clone());
                    render.line_color_hex(&input.grid_color);
                    render.font_color_hex(&input.font_color);
                    render.thickness(parse_thickness(&input.line_thickness));

                    let mut page = page.clone();
                    render_hal(&mut page, render);
                } else if planned.sink.is_some() {
                    let mut render = Render::new(&pdf, page.clone(), grid.clone());
                    render.line_color_hex(&input.grid_color);
                    render.font_color_hex(&input.font_color);
                    render.thickness(parse_thickness(&input.line_thickness));

                    let mut page = page.clone();
                    render_sink(&mut page, render);
                } else if planned.target.is_some() {
                    render_single_target(&pdf, page.clone(), grid.clone(), &input);
                } else if planned.arrows.is_some() {
                    render_targets(&pdf, page.clone(), grid.clone(), &input);
                    render_delta_entry(&pdf, page.clone(), grid.clone(), &input, true, false);
                } else if planned.empty.is_some() {
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
// omg ratio does not allow to not-render conditionally on single tick
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

#[wasm_bindgen]
pub fn create_balance_log(given: JsValue) -> JsValue {
    let data: PageData = None;
    let title = "Balance log";

    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    let mut page = pdf.page(0);
    let mut render = Render::new(&pdf, page.clone(), grid.clone());
    let grid_color = "ffbf00";
    let font_color = "000000";
    render.line_color_hex(grid_color);
    render.font_color_hex(font_color);
    render.thickness(0.5);

    render_faculties(&mut page, render);

    for x in 2..=30 {
        let mut page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        let grid_color = "ffbf00";
        let font_color = "000000";
        render.line_color_hex(grid_color);
        render.font_color_hex(font_color);
        render.thickness(0.5);

        render_faculties(&mut page, render);
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

#[wasm_bindgen]
pub fn create_balance_detail(given: JsValue) -> JsValue {
    let data: PageData = None;
    let title = "Balance detail";

    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    // main alpha page is existing root page ("-" page)
    let page = pdf.page(0);
    let alpha_page = page.clone();
    let input = Input {
        arrows: None,
        grid_color: "ffbf00".into(), // into by macro idea
        font_color: "000000".into(),
        line_thickness: "1".into(),
        renamings: "".into(),
        title: "".into(),
        balance: Some("".into()),
        empty_pages: Some("checked".into()),
        target: None,
        timetable: None,
        square: None,
        hal: None,
        sink: None,
        five: None,
        plus: None,
        figure: None,
    };

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

    let mut whole_page = pdf.add_page(None); // whole: man/actions/...
    let mut render = Render::new(&pdf, whole_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));
    render_faculties(&mut whole_page, render.clone());

    // nested pages for faculties
    let mut produce_nested =
        |pdf: &mut PDF<PageData>, subheader: String, x: f32, y: f32, sizex: f32, sizey: f32| {
            let count_consecutive = 11;
            let mut pages = vec![];
            for i in 1..=count_consecutive {
                let page = pdf.add_page(Some(subheader.clone()));
                pages.push(page.clone());
                render_big_grid(&pdf, page.clone(), grid.clone(), &input);

                render_tick(
                    &pdf,
                    page,
                    grid.clone(),
                    &input,
                    i as f32 / (count_consecutive as f32 + 1.),
                );
            }
            let page = &pages[0];

            let door = Area::xywh(x * 2., y * 2., sizex, sizey);
            let mut render = Render::new(&pdf, whole_page.clone(), grid.clone());
            render.link(&page, door.clone());
            (page.clone(), door)
        };

    // nice to have A-D before in the title - it is like "hidden"/assumed context of action, intent that one may
    // not be avare of at times

    let mut produce_faculty = |name: &str, x: f32, y: f32| {
        // star is fun, since the whole faculties page is like a human too
        let base: String = format!("*-{}", name).into();
        let mut dx = 0.;
        let mut dy = 0.;
        if name == "think" {
            dx = 0.25;
        }
        produce_nested(&mut pdf, base.clone(), x + dx, y + 0.5, 4. - dx * 2., 2.);
        // mitigating A's is important, no order issues here :train:
        let mut shift = 0.;
        if name == "think" {
            shift = 1.5 / 2.; // omf
        }
        produce_nested(
            &mut pdf,
            format!("A-{}", name).into(),
            x + 1. + shift,
            y,
            2. - shift * 2.,
            1.,
        );
        let mut w = 2.;
        if name == "think" {
            w = 1.;
        }
        produce_nested(&mut pdf, format!("B-{}", name).into(), x, y + 1.5, w, 1.);
        let mut w = 2.;
        if name == "think" {
            w = 0.5;
        }
        produce_nested(&mut pdf, format!("C-{}", name).into(), x, y, w, 1.);
        let mut shift = 0.;
        if name == "think" {
            shift = 1.0 / 2.; // omf
        }
        produce_nested(
            &mut pdf,
            format!("D-{}", name).into(),
            x + 1. + shift,
            y + 1.5,
            2. - shift * 2.,
            1.,
        );

        if name == "think" {
            // omf: / 2.
            produce_nested(
                &mut pdf,
                format!("{}-r(cog)", name).into(),
                4.5 / 2.,
                4. / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-u(cog)", name).into(),
                5.0 / 2.,
                4. / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-ap(cog)", name).into(),
                5.5 / 2.,
                4. / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-an(cog)", name).into(),
                6.0 / 2.,
                4. / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-e(cog)", name).into(),
                6.5 / 2.,
                4. / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-cr(cog)", name).into(),
                7.0 / 2.,
                4. / 2.,
                0.5,
                0.5,
            );

            produce_nested(
                &mut pdf,
                format!("{}-f(kn)", name).into(),
                4.0 / 2.,
                5. / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-con(kn)", name).into(),
                4.0 / 2.,
                5.5 / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-p(kn)", name).into(),
                4.0 / 2.,
                6.0 / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-m(kn)", name).into(),
                4.0 / 2.,
                6.5 / 2.,
                0.5,
                0.5,
            );

            // imagination/memory
            // no problem in naming, gotta record mapping anyway
            produce_nested(
                &mut pdf,
                format!("{}-VIS", name).into(),
                5.0 / 2.,
                7.5 / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-VER", name).into(),
                5.5 / 2.,
                7.5 / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-INT", name).into(),
                6.0 / 2.,
                7.5 / 2.,
                0.5,
                0.5,
            );
            produce_nested(
                &mut pdf,
                format!("{}-KIN", name).into(),
                6.5 / 2.,
                7.5 / 2.,
                0.5,
                0.5,
            );
        }
    };
    produce_faculty("scan", 2., 4.);
    produce_faculty("think", 2., 2.);
    produce_faculty("move", 2., 0.);
    produce_faculty("express", 0., 2.);
    produce_faculty("roll", 4., 2.);

    produce_nested(&mut pdf, "express-OPT".into(), 0.0 / 2., 8.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "express-SON".into(), 1.0 / 2., 8.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "express-CHE".into(), 2.0 / 2., 8.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "express-HAP".into(), 3.0 / 2., 8.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "scan-OPT".into(), 4.0 / 2., 12.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "scan-SON".into(), 5.0 / 2., 12.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "scan-CHE".into(), 6.0 / 2., 12.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "scan-HAP".into(), 7.0 / 2., 12.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "move-A".into(), 8.0 / 2., 3.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "move-PP".into(), 8.0 / 2., 2.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "move-L".into(), 8.0 / 2., 1.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "move-E".into(), 8.0 / 2., 0.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "Day".into(), 1.5 / 2., 2.5 / 2., 1., 1.);
    produce_nested(&mut pdf, "Night".into(), 1.5 / 2., 0.5 / 2., 1., 1.);

    produce_nested(&mut pdf, "roll-C".into(), 8.0 / 2., 14.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "roll-D".into(), 8.0 / 2., 13.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "roll-E".into(), 8.0 / 2., 12.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "roll-F".into(), 8.0 / 2., 11.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "roll-G".into(), 8.0 / 2., 10.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "roll-A".into(), 8.0 / 2., 9.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "roll-B".into(), 8.0 / 2., 8.0 / 2., 1., 1.);

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
        render.header_link(&whole_page, "+", Area::xywh(12., 16., -1.5, -1. + 0.02));
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

fn render_square(page: &mut Page<Option<String>>, mut render: Render<PageData>) {
    render.hline(15., None, None);
    render.hline(12., None, None);
    render.hline(9., None, None);
    render.hline(6., None, None);
    render.hline(3., None, None);
    //render.hline(2., None, None);
    //render.hline(1., None, None);

    render.vline(3., Some(3.), Some(15.));
    render.vline(6., Some(3.), Some(15.));
    render.vline(9., Some(3.), Some(15.));
}

fn render_hal(page: &mut Page<Option<String>>, mut render: Render<PageData>) {
    for i in 1..=15 {
        render.hline(i as f32, None, None);
    }

    let y = 4.;
    render.vline(6., Some(y - 1.), Some(y + 1.));

    render.circle_omg(6., y, 6.);
    render.circle_omg(6., y, 5.);
    render.circle_omg(6., y, 4.);
    render.circle_omg(6., y, 3.);
    render.circle_omg(6., y, 2.);
    render.circle_omg(6., y, 1.);
}

fn render_sink(page: &mut Page<Option<String>>, mut render: Render<PageData>) {
    for i in 1..=15 {
        render.hline(i as f32, None, None);
    }

    let d = 5.5;
    render.line(0., 16., d, 16. - d);
    render.line(12., 16., 12. - d, 16. - d);

    render.line(d, 16. - d, d, 0.);
    render.line(12. - d, 16. - d, 12. - d, 0.);
}

// shitty in old version used by fork, duplicates image data in pdf
fn add_states_image(doc: &PdfDocumentReference, shit: (PdfPageIndex, PdfLayerIndex), x: Mm, y: Mm) {
    use image_crate::codecs::png::PngDecoder;
    use printpdf::*;
    use std::fs::File;
    use std::io::BufWriter;
    use std::io::Cursor;

    let image_bytes = include_bytes!("../ruby/ready.png");
    let mut reader = Cursor::new(image_bytes.as_ref());
    let decoder = PngDecoder::new(&mut reader).unwrap();

    let image = Image::try_from(decoder).unwrap();

    let rotation_center_x = Px((image.image.width.0 as f32 / 2.0) as usize);
    let rotation_center_y = Px((image.image.height.0 as f32 / 2.0) as usize);

    let current_layer = doc.get_page(shit.0).get_layer(shit.1);

    image.add_to_layer(
        current_layer.clone(),
        ImageTransform {
            translate_x: Some(x),
            translate_y: Some(y),
            ..Default::default()
        },
    );
}

fn render_faculties(page: &mut Page<Option<String>>, mut render: Render<PageData>) {
    let w = render.grid.w;

    let x = render.mm(render.x(0.0));
    let y = render.mm(render.y(0.0));
    add_states_image(&render.pdf.doc, (page.page, page.layer), x, y);

    render.line(0., 4., render.grid.w, 4.);
    render.line(0., 8., render.grid.w, 8.);
    render.line(4., 12., render.grid.w - 4., 12.);

    render.line(4., 0., 4., 12.);
    render.line(w - 4., 0., w - 4., 12.);

    let render_quadrant = |cx, cy| {
        render.line(cx + 1., cy, cx + 2., cy);
        render.line(cx - 1., cy, cx - 2., cy);
        render.line(cx, cy + 1., cx, cy + 2.);
        render.line(cx, cy - 1., cx, cy - 2.);

        render.line_text("A", cx + 2. - 0.05, cy - 2.);
        render.line_text("C", cx - 2. + 0.25, cy - 2.);
        render.line_text("B", cx - 2. + 0.25, cy + 2. - 0.33);
        render.line_text("D", cx + 2. - 0.05, cy + 2. - 0.33);
    };
    render_quadrant(2., 6.);
    render_quadrant(6., 2.);
    render_quadrant(6., 6.);
    render_quadrant(10., 6.);
    render_quadrant(6., 10.);

    //render.line(0., 0.5, 4., 0.5);
    //render.line(0., 1., 4., 1.);
    //render.line(0., 1.5, 4., 1.5);
    //render.line(0., 2., 4., 2.);
    //render.line(0., 2.5, 4., 2.5);
    //render.line(0., 3., 4., 3.);
    //render.line(0., 3.5, 4., 3.5);

    render.line(9., 0.5, w, 0.5);
    render.line(8., 1., w, 1.);
    render.line(9., 1.5, w, 1.5);
    render.line(8., 2., w, 2.);
    render.line(9., 2.5, w, 2.5);
    render.line(8., 3., w, 3.);
    render.line(9., 3.5, w, 3.5);

    let dy = 8.;

    //render.line(0., dy + 0.5, 4., dy + 0.5);
    render.line(0., dy + 1., 4., dy + 1.);

    let doc = &render.pdf.doc;
    let current_layer = doc.get_page(render.page.page).get_layer(render.page.layer);

    let mut dash_pattern = LineDashPattern::default();
    dash_pattern.dash_1 = Some(5); // Length of dash
    dash_pattern.gap_1 = Some(5); // Length of gap
    current_layer.set_line_dash_pattern(dash_pattern);

    //render.line(0., dy + 1.5, 4., dy + 1.5);
    render.line(0., dy + 2., 4., dy + 2.);
    //render.line(0., dy + 2.5, 4., dy + 2.5);
    render.line(0., dy + 3., 4., dy + 3.);
    //render.line(0., dy + 3.5, 4., dy + 3.5);
    render.line(0., dy + 4.0, 4., dy + 4.0);

    current_layer.set_line_dash_pattern(LineDashPattern::default());

    //render.line(8., dy + 0.5, w, dy + 0.5);
    render.line(8., dy + 1., w, dy + 1.);
    //render.line(8., dy + 1.5, w, dy + 1.5);
    render.line(8., dy + 2., w, dy + 2.);
    //render.line(8., dy + 2.5, w, dy + 2.5);
    render.line(8., dy + 3., w, dy + 3.);
    //render.line(8., dy + 3.5, w, dy + 3.5);
    render.line(8., dy + 4.0, w, dy + 4.0);

    let dy = 12.;
    //render.line(0., dy + 0.5, w, dy + 0.5);
    render.line(4., dy + 1.0, w, dy + 1.0);
    render.line(8., dy + 2.0, w, dy + 2.0);
    render.line(8., dy + 3.0, w, dy + 3.0);
    //render.line(0., dy + 3.5, w, dy + 3.5);

    current_layer.set_line_dash_pattern(dash_pattern);

    render.line(0., dy + 1.0, 4., dy + 1.0);
    render.line(0., dy + 2.0, 4.27, dy + 2.0);

    //render.line(0., dy + 1.5, w, dy + 1.5);
    //render.line(0., dy + 2.0, w, dy + 2.0);
    ////render.line(0., dy + 2.5, w, dy + 2.5);

    current_layer.set_line_dash_pattern(LineDashPattern::default());
    render.line(0., dy + 3.0, 4., dy + 3.0);

    //render.line_color_hex(&input.grid_color);
    //render.font_color_hex(&input.font_color);
    //render.thickness(parse_thickness(&input.line_thickness));

    //render.circle_omg(2., 2., 2.);
    //render.circle_omg(2., 3., 0.5);
    //render.half_circle(2., 1., 0.5);

    render.line(8., 13., 8., 15.);
    render.line(9., 15., 9., 8.);

    //render.line_start_text("exercise/rest", 0., 0.);
    //render.line_text("inventory", 12., 0.); // L generally speaking is about moving things up/down
    //
    // "sea" of special is move, express is ~charisma but also cognitive summary expression for memory/intelligence-sake
    render.center_text("express", 2., 6. - 0.125);
    render.center_text("think", 6., 6. - 0.125); // i
    render.center_text("roll", 10., 6. - 0.125); // luck/shot/roll/use/external-unknown discovery
                                                 // rool more than shot captures sequential
                                                 // type of long action sequence between
                                                 // faculties and such unknowable effects too!
                                                 // also dice+table is medium, roll is against
                                                 // medium since it is very much
                                                 // lucky-encounters-oriented
                                                 // roll as hand and tool action
    render.center_text("scan", 6., 10. - 0.125); // p
    render.center_text("move", 6., 2. - 0.125);

    // scan features:
    render.line(4., 12., 4., 13.);
    render.center_text("OPT", 4.5, 12.5 - 0.125);

    render.line(5., 12., 5., 13.);
    render.center_text("SON", 5.5, 12.5 - 0.125);

    render.line(6., 12., 6., 13.);
    render.center_text("CHE", 6.5, 12.5 - 0.125);

    render.line(7., 12., 7., 13.);
    render.center_text("HAP", 7.5, 12.5 - 0.125);

    render.line(8., 12., 8., 13.);

    // express features: (mirroring scan features, but mirror neurons allow indirect HAP for example by
    // observing another's dance as expression)
    render.center_text("OPT", 0.5, 8.5 - 0.125);

    render.line(1., 8., 1., 9.);
    render.center_text("SON", 1.5, 8.5 - 0.125);

    render.line(2., 8., 2., 9.);
    render.center_text("CHE", 2.5, 8.5 - 0.125);

    render.line(3., 8., 3., 9.);
    render.center_text("HAP", 3.5, 8.5 - 0.125);

    // move features:
    render.line(9., 0., 9., 4.);
    render.center_text("A", 8.5, 3.5 - 0.125);
    render.center_text("PP", 8.5, 2.5 - 0.125);
    render.center_text("L", 8.5, 1.5 - 0.125);
    render.center_text("E", 8.5, 0.5 - 0.125);

    // int. training framework
    render.hline(4.5, Some(4.5), Some(7.5));
    render.vline(4.5, Some(4.), Some(4.5));
    render.vline(5.0, Some(4.), Some(4.5));
    render.vline(5.5, Some(4.), Some(4.5));
    render.vline(6.5, Some(4.), Some(4.5));
    render.vline(7.0, Some(4.), Some(4.5));
    render.vline(7.5, Some(4.), Some(4.5));

    render.sm_center_text("r", 4.5 + 0.25, 4.0 + 0.25 - 0.125);
    render.sm_center_text("u", 5.0 + 0.25, 4.0 + 0.25 - 0.125);
    render.sm_center_text("a", 5.5 + 0.25, 4.0 + 0.25 - 0.125);
    render.sm_center_text("a", 6.0 + 0.25, 4.0 + 0.25 - 0.125);
    render.sm_center_text("e", 6.5 + 0.25, 4.0 + 0.25 - 0.125);
    render.sm_center_text("c", 7.0 + 0.25, 4.0 + 0.25 - 0.125);

    render.sm_center_text("f", 4.0 + 0.25, 5.0 + 0.25 - 0.125);
    render.sm_center_text("c", 4.0 + 0.25, 5.5 + 0.25 - 0.125);
    render.sm_center_text("p", 4.0 + 0.25, 6.0 + 0.25 - 0.125);
    render.sm_center_text("m", 4.0 + 0.25, 6.5 + 0.25 - 0.125);

    render.vline(4.5, Some(5.), Some(7.));
    render.hline(5., Some(4.), Some(4.5));
    render.hline(5.5, Some(4.), Some(4.5));
    render.hline(6.5, Some(4.), Some(4.5));
    render.hline(7., Some(4.), Some(4.5));

    // imagination/memory mapped to senses visuospatial,verbal, (chemical goes as intuition of states(own/social), h as
    // kinestetic/motor imagination.
    //
    // there is way more to add somehow: episodic/semantic/conditioned, association goes into
    // episodic I assume, different layers involved

    render.sm_center_text("o", 5.0 + 0.25, 8.0 - 0.25 - 0.125);
    render.sm_center_text("s", 5.5 + 0.25, 8.0 - 0.25 - 0.125);
    render.sm_center_text("c", 6.0 + 0.25, 8.0 - 0.25 - 0.125);
    render.sm_center_text("h", 6.5 + 0.25, 8.0 - 0.25 - 0.125);

    render.hline(7.5, Some(5.0), Some(7.0));
    render.vline(5.0, Some(8.), Some(7.5));
    render.vline(5.5, Some(8.), Some(7.5));
    render.vline(6.5, Some(8.), Some(7.5));
    render.vline(7.0, Some(8.), Some(7.5));

    render.circle_omg(6., 15., 2.);
    render.circle_omg(6., 14., 1.);
    render.circle_omg(6., 13.5, 0.5);

    render.vline(10., Some(8.0), Some(10.0));
    render.vline(11., Some(8.0), Some(10.0));

    // no use yet? (right side of think - interesting, maybe temporal aspect)
    //
    //render.vline(7.5, Some(5.), Some(7.));
    //render.hline(5., Some(8.), Some(7.5));
    //render.hline(5.5, Some(8.), Some(7.5));
    //render.hline(6.5, Some(8.), Some(7.5));
    //render.hline(7., Some(8.), Some(7.5));
}

// big grid has faster transition from my faculties page
fn render_big_grid(pdf: &PDF<PageData>, page: Page<PageData>, grid: Grid, input: &Input) {
    let mut render = Render::new(pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    let mut max_y = render.grid.h;

    for i in 1..=((max_y - 1.) as i32) {
        let y = i as f32;
        render.line(0., y, render.grid.w, y);
    }
    for i in 1..=((render.grid.w) as i32 - 1) {
        let x = i as f32;
        render.line(x, 0., x, max_y - 1.);
    }
}

#[wasm_bindgen]
pub fn create_123(given: JsValue) -> JsValue {
    use serde_wasm_bindgen::from_value;
    let input: Input123 = from_value(given.clone()).unwrap();
    if input.action == "log" {
        create_123_log(input)
    } else if input.action == "columns_log" {
        create_123_columns_log(input)
    } else {
        create_123_detail(given)
    }
}

pub fn create_123_columns_log(input: Input123) -> JsValue {
    let data: PageData = None;

    let mut pdf = PDF::new(&input.title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    let mut page = pdf.page(0);
    let mut render = Render::new(&pdf, page.clone(), grid.clone());

    render_123_columns(&mut page, render, &input);

    for x in 2..=100 {
        let mut page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render_123_columns(&mut page, render, &input);
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
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

pub fn create_123_log(input: Input123) -> JsValue {
    let data: PageData = None;

    let mut pdf = PDF::new(&input.title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    let mut page = pdf.page(0);
    let mut render = Render::new(&pdf, page.clone(), grid.clone());

    render_123(&mut page, render, &input);

    for x in 2..=100 {
        let mut page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render_123(&mut page, render, &input);
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
        //render.header_link(
        //    &alpha_page,
        //    "-",
        //    Area::xywh(12. - 1.5, 16., -1.5, -1. + 0.02),
        //);
        //render.header_link(&delta_page, "+", Area::xywh(12., 16., -1.5, -1. + 0.02));
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

#[wasm_bindgen]
pub fn create_123_detail(given: JsValue) -> JsValue {
    use serde_wasm_bindgen::from_value;
    let input: Input123 = from_value(given).unwrap();

    let data: PageData = None;
    let title = input.title.clone();

    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    // main alpha page is existing root page ("-" page)
    let mut page = pdf.page(0);
    let alpha_page = page.clone();

    // shitty fix, actually styles should apply separately
    let shit_input = Input {
        arrows: None,
        grid_color: input.grid_color.clone().into(), // into by macro idea
        font_color: input.font_color.clone().into(),
        line_thickness: input.line_thickness.clone().into(),
        renamings: "".into(),
        title: input.title.clone().into(),
        balance: None,
        empty_pages: None,
        target: None,
        timetable: None,
        square: None,
        hal: None,
        sink: None,
        five: None,
        plus: None,
        figure: None,
    };

    let count_consecutive = 23;
    render_alpha(&pdf, page.clone(), grid.clone(), &shit_input);
    render_tick(
        &pdf,
        page.clone(),
        grid.clone(),
        &shit_input,
        1. / (count_consecutive as f32 + 1.),
    );
    // consecutive alpha pages
    for i in 2..=count_consecutive {
        let page = pdf.add_page(None);
        render_alpha(&pdf, page.clone(), grid.clone(), &shit_input);
        render_tick(
            &pdf,
            page,
            grid.clone(),
            &shit_input,
            i as f32 / (count_consecutive as f32 + 1.),
        );
    }

    let mut whole_page = pdf.add_page(None); // whole: three levels of 123 decomposition on one page
    let mut render = Render::new(&pdf, whole_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    render_123(&mut page, render, &input);

    let mut produce_nested =
        |pdf: &mut PDF<PageData>, subheader: String, x: f32, y: f32, sizex: f32, sizey: f32| {
            let count_consecutive = 11;
            let mut pages = vec![];
            for i in 1..=count_consecutive {
                let page = pdf.add_page(Some(subheader.clone()));
                pages.push(page.clone());
                render_big_grid(&pdf, page.clone(), grid.clone(), &shit_input);

                render_tick(
                    &pdf,
                    page,
                    grid.clone(),
                    &shit_input,
                    i as f32 / (count_consecutive as f32 + 1.),
                );
            }
            let page = &pages[0];

            let door = Area::xywh(x * 2., y * 2., sizex, sizey);
            let mut render = Render::new(&pdf, whole_page.clone(), grid.clone());
            render.link(&page, door.clone());
            (page.clone(), door)
        };

    produce_nested(&mut pdf, "1.1.1".into(), 0.0 / 2., 12.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "1.1.2".into(), 0.0 / 2., 11.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "1.1.3".into(), 0.0 / 2., 10.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "1.2.1".into(), 4.0 / 2., 12.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "1.2.2".into(), 4.0 / 2., 11.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "1.2.3".into(), 4.0 / 2., 10.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "1.3.1".into(), 8.0 / 2., 12.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "1.3.2".into(), 8.0 / 2., 11.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "1.3.3".into(), 8.0 / 2., 10.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "2.1.1".into(), 0.0 / 2., 7.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "2.1.2".into(), 0.0 / 2., 6.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "2.1.3".into(), 0.0 / 2., 5.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "2.2.1".into(), 4.0 / 2., 7.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "2.2.2".into(), 4.0 / 2., 6.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "2.2.3".into(), 4.0 / 2., 5.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "2.3.1".into(), 8.0 / 2., 7.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "2.3.2".into(), 8.0 / 2., 6.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "2.3.3".into(), 8.0 / 2., 5.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "3.1.1".into(), 0.0 / 2., 2.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "3.1.2".into(), 0.0 / 2., 1.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "3.1.3".into(), 0.0 / 2., 0.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "3.2.1".into(), 4.0 / 2., 2.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "3.2.2".into(), 4.0 / 2., 1.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "3.2.3".into(), 4.0 / 2., 0.0 / 2., 1., 1.);

    produce_nested(&mut pdf, "3.3.1".into(), 8.0 / 2., 2.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "3.3.2".into(), 8.0 / 2., 1.0 / 2., 1., 1.);
    produce_nested(&mut pdf, "3.3.3".into(), 8.0 / 2., 0.0 / 2., 1., 1.);

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
        render.header_link(&whole_page, "+", Area::xywh(12., 16., -1.5, -1. + 0.02));
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

fn render_123(page: &mut Page<Option<String>>, mut render: Render<PageData>, input: &Input123) {
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    render.hline(15., None, None);
    render.sm_center_text("1.", 0.0 + 0.5, 14.0 + 0.5 - 0.125);

    render.hline(14., None, None);
    render.sm_center_text("1.1", 0.0 + 0.5, 13.0 + 0.5 - 0.125);
    render.sm_center_text("1.2", 4.0 + 0.5, 13.0 + 0.5 - 0.125);
    render.sm_center_text("1.3", 8.0 + 0.5, 13.0 + 0.5 - 0.125);

    render.vline(1., Some(13.), Some(10.));
    render.sm_center_text("1.1.1", 0.0 + 0.5, 12.0 + 0.5 - 0.125);
    render.sm_center_text("1.1.2", 0.0 + 0.5, 11.0 + 0.5 - 0.125);
    render.sm_center_text("1.1.3", 0.0 + 0.5, 10.0 + 0.5 - 0.125);

    render.vline(4., Some(14.), Some(10.));
    render.vline(5., Some(13.), Some(10.));
    render.sm_center_text("1.2.1", 4.0 + 0.5, 12.0 + 0.5 - 0.125);
    render.sm_center_text("1.2.2", 4.0 + 0.5, 11.0 + 0.5 - 0.125);
    render.sm_center_text("1.2.3", 4.0 + 0.5, 10.0 + 0.5 - 0.125);

    render.vline(8., Some(14.), Some(10.));
    render.vline(9., Some(13.), Some(10.));
    render.sm_center_text("1.3.1", 8.0 + 0.5, 12.0 + 0.5 - 0.125);
    render.sm_center_text("1.3.2", 8.0 + 0.5, 11.0 + 0.5 - 0.125);
    render.sm_center_text("1.3.3", 8.0 + 0.5, 10.0 + 0.5 - 0.125);
    render.hline(13., None, None);
    render.hline(12., None, None);
    render.hline(11., None, None);

    // 2.

    render.hline(10., None, None);
    render.sm_center_text("2.", 0.0 + 0.5, 9.0 + 0.5 - 0.125);

    render.hline(9., None, None);
    render.sm_center_text("2.1", 0.0 + 0.5, 8.0 + 0.5 - 0.125);
    render.sm_center_text("2.2", 4.0 + 0.5, 8.0 + 0.5 - 0.125);
    render.sm_center_text("2.3", 8.0 + 0.5, 8.0 + 0.5 - 0.125);

    render.vline(1., Some(8.), Some(5.));
    render.sm_center_text("2.1.1", 0.0 + 0.5, 7.0 + 0.5 - 0.125);
    render.sm_center_text("2.1.2", 0.0 + 0.5, 6.0 + 0.5 - 0.125);
    render.sm_center_text("2.1.3", 0.0 + 0.5, 5.0 + 0.5 - 0.125);

    render.vline(4., Some(9.), Some(5.));
    render.vline(5., Some(8.), Some(5.));
    render.sm_center_text("2.2.1", 4.0 + 0.5, 7.0 + 0.5 - 0.125);
    render.sm_center_text("2.2.2", 4.0 + 0.5, 6.0 + 0.5 - 0.125);
    render.sm_center_text("2.2.3", 4.0 + 0.5, 5.0 + 0.5 - 0.125);

    render.vline(8., Some(9.), Some(5.));
    render.vline(9., Some(8.), Some(5.));
    render.sm_center_text("2.3.1", 8.0 + 0.5, 7.0 + 0.5 - 0.125);
    render.sm_center_text("2.3.2", 8.0 + 0.5, 6.0 + 0.5 - 0.125);
    render.sm_center_text("2.3.3", 8.0 + 0.5, 5.0 + 0.5 - 0.125);
    render.hline(8., None, None);
    render.hline(7., None, None);
    render.hline(6., None, None);

    // 3.

    render.hline(5., None, None);
    render.sm_center_text("3.", 0.0 + 0.5, 4.0 + 0.5 - 0.125);

    render.hline(4., None, None);
    render.sm_center_text("3.1", 0.0 + 0.5, 3.0 + 0.5 - 0.125);
    render.sm_center_text("3.2", 4.0 + 0.5, 3.0 + 0.5 - 0.125);
    render.sm_center_text("3.3", 8.0 + 0.5, 3.0 + 0.5 - 0.125);

    render.vline(1., Some(3.), Some(0.));
    render.sm_center_text("3.1.1", 0.0 + 0.5, 2.0 + 0.5 - 0.125);
    render.sm_center_text("3.1.2", 0.0 + 0.5, 1.0 + 0.5 - 0.125);
    render.sm_center_text("3.1.3", 0.0 + 0.5, 0.0 + 0.5 - 0.125);

    render.vline(4., Some(4.), Some(0.));
    render.vline(5., Some(3.), Some(0.));
    render.sm_center_text("3.2.1", 4.0 + 0.5, 2.0 + 0.5 - 0.125);
    render.sm_center_text("3.2.2", 4.0 + 0.5, 1.0 + 0.5 - 0.125);
    render.sm_center_text("3.2.3", 4.0 + 0.5, 0.0 + 0.5 - 0.125);

    render.vline(8., Some(4.), Some(0.));
    render.vline(9., Some(3.), Some(0.));
    render.sm_center_text("3.3.1", 8.0 + 0.5, 2.0 + 0.5 - 0.125);
    render.sm_center_text("3.3.2", 8.0 + 0.5, 1.0 + 0.5 - 0.125);
    render.sm_center_text("3.3.3", 8.0 + 0.5, 0.0 + 0.5 - 0.125);
    render.hline(3., None, None);
    render.hline(2., None, None);
    render.hline(1., None, None);
}

fn render_123_columns(
    page: &mut Page<Option<String>>,
    mut render: Render<PageData>,
    input: &Input123,
) {
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    render.center_text("1.", 2., 14.5 - 0.125);
    render.center_text("2.", 6., 14.5 - 0.125);
    render.center_text("3.", 10., 14.5 - 0.125);

    for i in 1..=13 {
        render.hline(i as f32, None, None);
    }

    //render.line_color_hex("000000");
    //render.thickness(parse_thickness("1"));
    render.vline(4., None, Some(15.));
    render.vline(8., None, Some(15.));
    render.hline(14., None, None);
    render.hline(15., None, None);
}

#[wasm_bindgen]
pub fn create_wip(given: JsValue) -> JsValue {
    use serde_wasm_bindgen::from_value;
    let input: Input123 = from_value(given.clone()).unwrap();

    let data: PageData = None;

    let mut pdf = PDF::new(&input.title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    let mut page = pdf.page(0);
    let mut render = Render::new(&pdf, page.clone(), grid.clone());

    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    let count_consecutive = 11;
    let x = 0.;
    let xx = 2. / (count_consecutive as f32 + 1.) * (x as f32 + 1.);
    render.line(xx, 16., xx, 16. - 0.1);

    render_wip_header(&mut page, render, &input, Some(0), None, None);

    let mut menu: Vec<(Page<PageData>, Area)> = vec![];
    let row_index = 0;
    let size = 2.;
    menu.push((
            page.clone(),
            Area::xywh((row_index as f32) * 2., 16. - size, size, size),
    ));

    for row_index in 0..6 {
        let start = if row_index == 0 {
            1 // having root page already
        } else {
            0
        };
        for x in start..count_consecutive {
            let mut page = pdf.add_page(None);
            let mut render = Render::new(&pdf, page.clone(), grid.clone());
            render_wip_header(
                &mut page,
                render.clone(),
                &input,
                Some(row_index),
                None,
                None,
            );

            render.line_color_hex(&input.grid_color);
            render.font_color_hex(&input.font_color);
            render.thickness(parse_thickness(&input.line_thickness));

            let xx = 2. / (count_consecutive as f32 + 1.) * (x as f32 + 1.) + row_index as f32 * 2.;
            render.line(xx, 16., xx, 16. - 0.1);

            if x == 0 {
                menu.push((
                        page.clone(),
                        Area::xywh((row_index as f32) * 2., 16. - size, size, size),
                ));
            }
        }
    }

    let count_consecutive = 12;
    for x in 0..count_consecutive {
        let mut page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render_wip_header(&mut page, render.clone(), &input, None, Some(x), None);

        let size = 1.;
        menu.push((
                page.clone(),
                Area::xywh((x as f32) * size, 14. - size, size, size),
        ));
    }

    for x in 0..count_consecutive {
        let mut page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render_wip_header(&mut page, render.clone(), &input, None, None, Some(x));

        let size = 1.;
        menu.push((
                page.clone(),
                Area::xywh((x as f32) * size, 13. - size, size, size),
        ));
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

        for (page, door) in &menu {
            render.link(&page, door.clone());
        }
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

fn render_wip_header(
    page: &mut Page<Option<String>>,
    mut render: Render<PageData>,
    input: &Input123,
    focus1: Option<usize>, // focus on first row at the top
    focus2: Option<usize>,
    focus3: Option<usize>,
) {
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    // just same grid to have - simple and fine for 90 pages total
    for i in 0..=11 {
        render.hline(i as f32, None, None);
        //render.hline(i as f32 + 0.5, None, None);
    }

    render.hline(14., None, None);
    render.hline(13., None, None);
    render.hline(12., None, None);

    for i in 1..=11 {
        render.vline(i as f32, Some(12.), Some(14.));
    }
    render.vline(2., Some(14.), None);
    render.vline(4., Some(14.), None);
    render.vline(6., Some(14.), None);
    render.vline(8., Some(14.), None);
    render.vline(10., Some(14.), None);

    render.line_color_hex("000000");
    render.thickness(2.);

    let mr = 0.125; // main-r
    render.circle_omg(11., 15., mr);

    render.vline(5. - mr, Some(15. - mr), Some(15. + mr));
    render.vline(5. + mr, Some(15. - mr), Some(15. + mr));
    render.hline(15. - mr, Some(5. - mr), Some(5. + mr));
    render.hline(15. + mr, Some(5. - mr), Some(5. + mr));

    render.vline(9. - mr / 2., Some(15. - mr), Some(15. + mr));
    render.vline(9. + mr / 2., Some(15. - mr), Some(15. + mr));

    let x = 1.;
    let y = 15.;

    let tr = mr * 1.33; // triangle radius, arbitrary

    use std::f32::consts::PI;

    let angle1 = PI / 3. * 2. - PI / 6.;
    let dx1 = angle1.cos() * tr;
    let dy1 = angle1.sin() * tr;

    let angle2 = PI / 3. * 4. - PI / 6.;
    let dx2 = angle2.cos() * tr;
    let dy2 = angle2.sin() * tr;

    let angle3 = PI / 3. * 6. - PI / 6.;
    let dx3 = angle3.cos() * tr;
    let dy3 = angle3.sin() * tr;

    render.line(x + dx2, y + dy2, x + dx1, y + dy1);
    render.line(x + dx3, y + dy3, x + dx1, y + dy1);

    let angle1 = PI / 3. * 2. - PI / 6. - PI / 2.;
    let dx1 = angle1.cos() * tr;
    let dy1 = angle1.sin() * tr;

    let angle2 = PI / 3. * 4. - PI / 6. - PI / 2.;
    let dx2 = angle2.cos() * tr;
    let dy2 = angle2.sin() * tr;

    let angle3 = PI / 3. * 6. - PI / 6. - PI / 2.;
    let dx3 = angle3.cos() * tr;
    let dy3 = angle3.sin() * tr;

    let x = 3.;
    let y = 15.;
    render.line(x + dx2, y + dy2, x + dx1, y + dy1);
    render.line(x + dx3, y + dy3, x + dx1, y + dy1);

    let angle1 = PI / 3. * 2. - PI / 6. + PI;
    let dx1 = angle1.cos() * tr;
    let dy1 = angle1.sin() * tr;

    let angle2 = PI / 3. * 4. - PI / 6. + PI;
    let dx2 = angle2.cos() * tr;
    let dy2 = angle2.sin() * tr;

    let angle3 = PI / 3. * 6. - PI / 6. + PI;
    let dx3 = angle3.cos() * tr;
    let dy3 = angle3.sin() * tr;

    let shift = 0.05;
    let x = 7. - shift;
    let y = 15.;
    render.line(x + dx2, y + dy2, x + dx1, y + dy1);
    render.line(x + dx3, y + dy3, x + dx1, y + dy1);

    let x = 7. + shift;
    render.line(x + dx2, y + dy2, x + dx1, y + dy1);
    render.line(x + dx3, y + dy3, x + dx1, y + dy1);

    // current page focus marker on the top menu

    // top-most row has item selected
    if let Some(dx) = focus1 {
        let x = (dx as f32) * 2. + 1.;
        let mr = 0.125 * 2.; // main-r
        render.circle_omg(x, 15., mr);
    }

    if let Some(dx) = focus2 {
        let x = dx as f32 + 0.5;
        let r = 0.125 / 5.;
        render.circle_omg(x, 13.5, r); // seems filled
    }

    if let Some(dx) = focus3 {
        let x = dx as f32 + 0.5;
        let rr = 0.125;
        render.vline(x, Some(12.5 - rr), Some(12.5 + rr));
        render.hline(12.5, Some(x - rr), Some(x + rr));
    }
}

#[wasm_bindgen]
pub fn create_four(given: JsValue) -> JsValue {
    use serde_wasm_bindgen::from_value;
    let input: Input123 = from_value(given).unwrap();

    let data: PageData = None;
    let title = input.title.clone();

    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    // main alpha page is existing root page ("-" page)
    let mut page = pdf.page(0);
    let alpha_page = page.clone();

    // shitty fix, actually styles should apply separately
    let shit_input = Input {
        arrows: None,
        grid_color: input.grid_color.clone().into(), // into by macro idea
        font_color: input.font_color.clone().into(),
        line_thickness: input.line_thickness.clone().into(),
        renamings: "".into(),
        title: input.title.clone().into(),
        balance: None,
        empty_pages: None,
        target: None,
        timetable: None,
        square: None,
        hal: None,
        sink: None,
        five: None,
        plus: None,
        figure: None,
    };

    let count_consecutive = 23;
    render_alpha(&pdf, page.clone(), grid.clone(), &shit_input);
    render_tick(
        &pdf,
        page.clone(),
        grid.clone(),
        &shit_input,
        1. / (count_consecutive as f32 + 1.),
    );
    // consecutive alpha pages
    for i in 2..=count_consecutive {
        let page = pdf.add_page(None);
        render_alpha(&pdf, page.clone(), grid.clone(), &shit_input);
        render_tick(
            &pdf,
            page,
            grid.clone(),
            &shit_input,
            i as f32 / (count_consecutive as f32 + 1.),
        );
    }

    let mut whole_page = pdf.add_page(None); // whole: three levels of 123 decomposition on one page
    let mut render = Render::new(&pdf, whole_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    render_four(whole_page.clone(), &mut pdf, &input, grid.clone());

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
        render.header_link(&whole_page, "+", Area::xywh(12., 16., -1.5, -1. + 0.02));
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

fn render_four(
    page: Page<Option<String>>,
    pdf: &mut PDF<Option<String>>,
    input: &Input123,
    grid: Grid,
) {
    use new_render::*;

    line_color_hex(pdf, &page, &input.grid_color);
    font_color_hex(pdf, &page, &input.font_color);
    thickness(pdf, &page, parse_thickness(&input.line_thickness));

    let mid = 6.;

    vline(pdf, &page, mid - 0.5, Some(0.), Some(12.));
    vline(pdf, &page, mid + 0.5, Some(0.), Some(12.));

    vline(pdf, &page, mid - 1.5, Some(1.), Some(2.));
    vline(pdf, &page, mid + 1.5, Some(1.), Some(2.));
    vline(pdf, &page, mid - 1.5, Some(1. + 3.), Some(2. + 3.));
    vline(pdf, &page, mid + 1.5, Some(1. + 3.), Some(2. + 3.));
    vline(pdf, &page, mid - 1.5, Some(1. + 6.), Some(2. + 6.));
    vline(pdf, &page, mid + 1.5, Some(1. + 6.), Some(2. + 6.));
    vline(pdf, &page, mid - 1.5, Some(1. + 9.), Some(2. + 9.));
    vline(pdf, &page, mid + 1.5, Some(1. + 9.), Some(2. + 9.));

    circle(pdf, &page, 5.5 + 0.5, 1.5, 0.5);
    circle(pdf, &page, 5.5 + 0.5, 1.5 + 3., 0.5);
    circle(pdf, &page, 5.5 + 0.5, 1.5 + 6., 0.5);
    circle(pdf, &page, 5.5 + 0.5, 1.5 + 9., 0.5);

    circle(pdf, &page, 5.5 + 0.5, 1.5 + 9., 4.0);
    circle(pdf, &page, 5.5 + 0.5, 1.5 + 9., 3.0);

    let mut produce_nested = |pdf: &mut PDF<PageData>,
    whole_page: &Page<PageData>,
    subheader: String,
    x: f32,
    y: f32,
    sizex: f32,
    sizey: f32| {
        let count_consecutive = 11;
        let mut pages = vec![];
        for i in 1..=count_consecutive {
            let page = pdf.add_page(Some(subheader.clone()));
            pages.push(page.clone());
            line_color_hex(pdf, &page, &input.grid_color);
            font_color_hex(pdf, &page, &input.font_color);
            thickness(pdf, &page, parse_thickness(&input.line_thickness));
            have_big_grid(pdf, &page);
            have_tick(pdf, &page, i, count_consecutive); // as f32 / (count_consecutive as f32 + 1.));
        }
        let page = &pages[0];

        let door = Area::xywh(x, y, sizex, sizey);
        link(pdf, &whole_page, door.clone(), &page);
    };

    let mut produce_four =
        |pdf: &mut PDF<PageData>, whole_page: &Page<PageData>, category: &str, x: f32, y: f32| {
            let dx = 0.;
            let dy = -1.;
            let name = "0";
            let title: String = format!("{}.{}", category, name).into();
            produce_nested(pdf, &page, title.clone(), x + dx, y + dy, 1., 1.);

            let dx = 1.;
            let dy = 0.;
            let name = "1";
            let title: String = format!("{}.{}", category, name).into();
            produce_nested(pdf, &page, title.clone(), x + dx, y + dy, 1., 1.);

            let dx = 0.;
            let dy = 1.;
            let name = "2";
            let title: String = format!("{}.{}", category, name).into();
            produce_nested(pdf, &page, title.clone(), x + dx, y + dy, 1., 1.);

            let dx = -1.;
            let dy = 0.;
            let name = "3";
            let title: String = format!("{}.{}", category, name).into();
            produce_nested(pdf, &page, title.clone(), x + dx, y + dy, 1., 1.);
        };

    //Ⅰ 	Ⅱ 	Ⅲ 	Ⅳ
    //wxyz has terminality - has a point
    center_text(pdf, &page, "Z", 5.5 + 0.5, 10.0 + 0.5 - 0.125);
    center_text(pdf, &page, "Y", 5.5 + 0.5, 7.0 + 0.5 - 0.125);
    center_text(pdf, &page, "X", 5.5 + 0.5, 4.0 + 0.5 - 0.125);
    center_text(pdf, &page, "W", 5.5 + 0.5, 1.0 + 0.5 - 0.125);
    produce_four(pdf, &page, "W", 5.5, 1.);
    produce_four(pdf, &page, "X", 5.5, 4.);
    produce_four(pdf, &page, "Y", 5.5, 7.);
    produce_four(pdf, &page, "Z", 5.5, 10.);

    hline(pdf, &page, 1., None, None);
    hline(pdf, &page, 2., None, None);
    hline(pdf, &page, 3., None, None);
    hline(pdf, &page, 4., None, None);
    hline(pdf, &page, 5., None, None);
    hline(pdf, &page, 6., None, None);
    hline(pdf, &page, 7., None, None);
    hline(pdf, &page, 8., None, None);
    hline(pdf, &page, 9., None, None);
    hline(pdf, &page, 10., None, None);
    hline(pdf, &page, 11., None, None);
    hline(pdf, &page, 12., None, None);
}

fn render_five(
    page: Page<Option<String>>,
    pdf: &mut PDF<Option<String>>,
    input: &Input,
    grid: Grid,
) {
    use new_render::*;

    line_color_hex(pdf, &page, &input.grid_color);
    font_color_hex(pdf, &page, &input.font_color);
    thickness(pdf, &page, parse_thickness(&input.line_thickness));

    let mut produce_nested =
        |pdf: &mut PDF<PageData>, page: &Page<PageData>, dx: f32, dy: f32, size: f32| {
            let part_size = size / 3.;

            hline(pdf, &page, 1. * part_size, Some(dx), Some(dx + size));
            hline(pdf, &page, 2. * part_size, Some(dx), Some(dx + part_size));
            hline(pdf, &page, 3. * part_size, Some(dx), Some(dx + size));

            vline(pdf, &page, dx + 0. * part_size, Some(dy), Some(dy + size));
            vline(pdf, &page, dx + 1. * part_size, Some(dy), Some(dy + size));
            vline(
                pdf,
                &page,
                dx + 2. * part_size,
                Some(dy + 2. * part_size),
                Some(dy + size),
            );

            let step = part_size / 4.;
            vline(
                pdf,
                &page,
                -step + dx + 2. * part_size,
                Some(dy + 2. * part_size + step),
                Some(dy + size - step),
            );
            vline(
                pdf,
                &page,
                3. * -step + dx + 2. * part_size,
                Some(dy + 2. * part_size + step),
                Some(dy + size - step),
            );

            hline(
                pdf,
                &page,
                dy + 2. * part_size + step,
                Some(-step + dx + 2. * part_size),
                Some(3. * -step + dx + 2. * part_size),
            );

            hline(
                pdf,
                &page,
                dy + size - step,
                Some(-step + dx + 2. * part_size),
                Some(3. * -step + dx + 2. * part_size),
            );
        };

    produce_nested(pdf, &page, 0., 4., 12.);
    produce_nested(pdf, &page, 0. * 3., 1., 3.);
    produce_nested(pdf, &page, 1. * 3., 1., 3.);
    produce_nested(pdf, &page, 2. * 3., 1., 3.);
    produce_nested(pdf, &page, 3. * 3., 1., 3.);

    vline(pdf, &page, 3., None, Some(1.));
    vline(pdf, &page, 6., None, Some(1.));
    vline(pdf, &page, 9., None, Some(1.));

    center_text(pdf, &page, "think", 2., 14. - 0.125);
    center_text(pdf, &page, "express", 4. + 2., 14. - 0.125);
    center_text(pdf, &page, "roll", 8. + 2., 14. - 0.125);
    center_text(pdf, &page, "scan", 2., 10. - 0.125);
    center_text(pdf, &page, "move", 2., 6. - 0.125);
}

fn render_plus(
    page: Page<Option<String>>,
    pdf: &mut PDF<Option<String>>,
    input: &Input,
    grid: Grid,
) {
    use new_render::*;

    line_color_hex(pdf, &page, &input.grid_color);
    font_color_hex(pdf, &page, &input.font_color);
    thickness(pdf, &page, parse_thickness(&input.line_thickness));

    let mut produce_nested =
        |pdf: &mut PDF<PageData>, page: &Page<PageData>, dx: f32, dy: f32, size: f32| {
            let part_size = size / 3.;

            // whole thing border
            hline(pdf, &page, dy + 0. * part_size, Some(dx), Some(dx + size));
            //hline(pdf, &page, dy + 3. * part_size, Some(dx), Some(dx + size));
            //vline(pdf, &page, dx + 0. * part_size, Some(dy), Some(dy + size));
            vline(pdf, &page, dx + 3. * part_size, Some(dy), Some(dy + size));

            // structure
            hline(pdf, &page, dy + 1. * part_size, Some(dx), Some(dx + size));
            hline(pdf, &page, dy + 2. * part_size, Some(dx), Some(dx + size));
            // border
            //hline(
            //    pdf,
            //    &page,
            //    dy + 0. * part_size,
            //    Some(dx + 1. * part_size),
            //    Some(dx + 2. * part_size),
            //);
            //hline(
            //    pdf,
            //    &page,
            //    dy + 3. * part_size,
            //    Some(dx + 1. * part_size),
            //    Some(dx + 2. * part_size),
            //);

            vline(pdf, &page, dx + 1. * part_size, Some(dy), Some(dy + size));
            vline(pdf, &page, dx + 2. * part_size, Some(dy), Some(dy + size));
            vline(
                pdf,
                &page,
                dx + 0. * part_size,
                Some(dy + 1. * part_size),
                Some(dy + 2. * part_size),
            );
            vline(
                pdf,
                &page,
                dx + 3. * part_size,
                Some(dy + 1. * part_size),
                Some(dy + 2. * part_size),
            );

            let step = part_size / 3.;
            let dxx = dx + 1. * part_size;
            let dyy = dy;

            vline(pdf, &page, dxx + step, Some(dy), Some(dy + part_size));
            vline(
                pdf,
                &page,
                dxx + 2. * step,
                Some(dy + part_size),
                Some(dy + part_size - step),
            );
            hline(
                pdf,
                &page,
                dyy + part_size - step,
                Some(dx + 1. * part_size),
                Some(dx + 2. * part_size),
            );
            hline(
                pdf,
                &page,
                dyy + part_size - 2. * step,
                Some(dx + 1. * part_size),
                Some(dx + 1. * part_size + step),
            );

            // insides
            hline(
                pdf,
                &page,
                dy + part_size + 1. * step,
                Some(dx + 0. * part_size),
                Some(dx + 1. * part_size),
            );
            hline(
                pdf,
                &page,
                dy + part_size + 2. * step,
                Some(dx + 0. * part_size),
                Some(dx + 1. * part_size),
            );
            vline(
                pdf,
                &page,
                dx + 2.5 * part_size,
                Some(dy + 1. * part_size),
                Some(dy + 2. * part_size),
            );
            let a = (dx + 1.5 * part_size, dy + 1.0 * part_size);
            let b = (dx + 1.5 * part_size, dy + 2.0 * part_size);
            let c = (dx + 1.0 * part_size, dy + 1.5 * part_size);
            let d = (dx + 2.0 * part_size, dy + 1.5 * part_size);
            line(pdf, &page, a.0, a.1, Some(c.0), Some(c.1));
            line(pdf, &page, b.0, b.1, Some(c.0), Some(c.1));
            line(pdf, &page, b.0, b.1, Some(d.0), Some(d.1));
            line(pdf, &page, a.0, a.1, Some(d.0), Some(d.1));
            circle(pdf, &page, a.0, dy + 0.5 * part_size, part_size / 2.);

            let ps = vec![
                (0. * part_size, 0. * part_size),
                (2. * part_size, 0. * part_size),
                (0. * part_size, 2. * part_size),
                (2. * part_size, 2. * part_size),
            ];
            for p in ps {
                line(
                    pdf,
                    &page,
                    p.0 + dx,
                    p.1 + dy,
                    Some(p.0 + dx + part_size),
                    Some(p.1 + dy + part_size),
                );
                line(
                    pdf,
                    &page,
                    p.0 + dx,
                    p.1 + dy + part_size,
                    Some(p.0 + dx + part_size),
                    Some(p.1 + dy),
                );
                hline(
                    pdf,
                    &page,
                    dy + p.1 + part_size / 2.,
                    Some(dx + p.0),
                    Some(dx + p.0 + part_size),
                );
            }
        };

    produce_nested(pdf, &page, 0., 4., 12.);

    produce_nested(pdf, &page, 0. * 3., 1., 3.);
    produce_nested(pdf, &page, 1. * 3., 1., 3.);
    produce_nested(pdf, &page, 2. * 3., 1., 3.);
    produce_nested(pdf, &page, 3. * 3., 1., 3.);
}

#[wasm_bindgen]
pub fn create_maze(given: JsValue) -> JsValue {
    let data: PageData = None;
    let title = "Maze";

    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    let mut page = pdf.page(0);
    let mut render = Render::new(&pdf, page.clone(), grid.clone());
    let grid_color = "ffbf00";
    let font_color = "000000";
    render.line_color_hex(grid_color);
    render.font_color_hex(font_color);
    render.thickness(0.5);

    use serde_wasm_bindgen::from_value;
    let input: Input123 = from_value(given).unwrap();

    let data: PageData = None;
    let mut pdf = PDF::new(&input.title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    render_maze(page.clone(), &mut pdf, &input, grid.clone());

    for x in 2..=100 {
        let mut page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        let grid_color = "ffbf00";
        let font_color = "000000";
        render.line_color_hex(grid_color);
        render.font_color_hex(font_color);
        render.thickness(0.5);

        render_maze(page.clone(), &mut pdf, &input, grid.clone());
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

fn render_maze(
    page: Page<Option<String>>,
    pdf: &mut PDF<Option<String>>,
    input: &Input123,
    grid: Grid,
) {
    use new_render::*;

    line_color_hex(pdf, &page, &input.grid_color);
    font_color_hex(pdf, &page, &input.font_color);
    thickness(pdf, &page, parse_thickness(&input.line_thickness));

    let mut produce_nested =
        |pdf: &mut PDF<PageData>, page: &Page<PageData>, dx: f32, dy: f32, size: f32| {
            let part_size = size / 3.;

            use rand::rngs::OsRng;
            use rand::seq::SliceRandom; // or StdRng with a seed

            let mut values = [0., 1., 2.];
            values.shuffle(&mut OsRng); // or StdRng::from_entropy()
            let [square_order, circle_order, angled_order] = values;

            // perpendicular
            vline(
                pdf,
                &page,
                dx + 2.5 * part_size,
                Some(dy + 1. * part_size),
                Some(dy + 2. * part_size),
            );
            hline(
                pdf,
                &page,
                dy + 1.5 * part_size,
                Some(dx + 2. * part_size),
                Some(dx + 3. * part_size),
            );

            // square
            hline(
                pdf,
                &page,
                dy + square_order * part_size,
                Some(dx + 1. * part_size),
                Some(dx + 2. * part_size),
            );
            hline(
                pdf,
                &page,
                dy + (square_order + 1.) * part_size,
                Some(dx + 1. * part_size),
                Some(dx + 2. * part_size),
            );
            vline(
                pdf,
                &page,
                dx + 1. * part_size,
                Some(dy + square_order * part_size),
                Some(dy + (square_order + 1.) * part_size),
            );
            vline(
                pdf,
                &page,
                dx + 2. * part_size,
                Some(dy + square_order * part_size),
                Some(dy + (square_order + 1.) * part_size),
            );

            let step = part_size / 3.;
            let dxx = dx + 1. * part_size;
            let dyy = dy;

            //vline(pdf, &page, dxx + step, Some(dy), Some(dy + part_size));
            //vline(
            //    pdf,
            //    &page,
            //    dxx + 2. * step,
            //    Some(dy + part_size),
            //    Some(dy + part_size - step),
            //);
            //hline(
            //    pdf,
            //    &page,
            //    dyy + part_size - step,
            //    Some(dx + 1. * part_size),
            //    Some(dx + 2. * part_size),
            //);
            //hline(
            //    pdf,
            //    &page,
            //    dyy + part_size - 2. * step,
            //    Some(dx + 1. * part_size),
            //    Some(dx + 1. * part_size + step),
            //);
            //
            // circle + insides
            //let a = (dx + 1.5 * part_size, dy + 1.0 * part_size);
            circle(
                pdf,
                &page,
                dx + 1.5 * part_size,
                dy + (circle_order + 0.5) * part_size,
                part_size / 2.,
            );

            // angled shape
            let a = (dx + 1.5 * part_size, dy + angled_order * part_size);
            let b = (dx + 1.5 * part_size, dy + (angled_order + 1.0) * part_size);
            let c = (dx + 1.0 * part_size, dy + (angled_order + 0.5) * part_size);
            let d = (dx + 2.0 * part_size, dy + (angled_order + 0.5) * part_size);
            line(pdf, &page, a.0, a.1, Some(c.0), Some(c.1));
            line(pdf, &page, b.0, b.1, Some(c.0), Some(c.1));
            line(pdf, &page, b.0, b.1, Some(d.0), Some(d.1));
            line(pdf, &page, a.0, a.1, Some(d.0), Some(d.1));

            // parallels
            hline(
                pdf,
                &page,
                dy + part_size + 1.5 * step,
                Some(dx + 0. * part_size),
                Some(dx + 1. * part_size),
            );
            //hline(
            //    pdf,
            //    &page,
            //    dy + part_size + 1. * step,
            //    Some(dx + 0. * part_size),
            //    Some(dx + 1. * part_size),
            //);
            //hline(
            //    pdf,
            //    &page,
            //    dy + part_size + 2. * step,
            //    Some(dx + 0. * part_size),
            //    Some(dx + 1. * part_size),
            //);

            //let ps = vec![
            //    (0. * part_size, 0. * part_size),
            //    (2. * part_size, 0. * part_size),
            //    (0. * part_size, 2. * part_size),
            //    (2. * part_size, 2. * part_size),
            //];
            //for p in ps {
            //    line(
            //        pdf,
            //        &page,
            //        p.0 + dx,
            //        p.1 + dy,
            //        Some(p.0 + dx + part_size),
            //        Some(p.1 + dy + part_size),
            //    );
            //    line(
            //        pdf,
            //        &page,
            //        p.0 + dx,
            //        p.1 + dy + part_size,
            //        Some(p.0 + dx + part_size),
            //        Some(p.1 + dy),
            //    );
            //    hline(
            //        pdf,
            //        &page,
            //        dy + p.1 + part_size / 2.,
            //        Some(dx + p.0),
            //        Some(dx + p.0 + part_size),
            //    );
            //}
        };

    for ax in -3..=3 {
        for ay in -3..=3 {
            let x = ax * 2 + ay;
            let y = ax - 2 * ay; // reverse y but it's indifferent

            let size = 2.;
            let wtf_size = 3. * size;

            produce_nested(pdf, &page, (x as f32) * size, (y as f32) * size, wtf_size);
        }
    }
}

fn render_figure(
    page: Page<Option<String>>,
    pdf: &mut PDF<Option<String>>,
    input: &Input,
    grid: Grid,
) {
    use new_render::*;

    line_color_hex(pdf, &page, &input.grid_color);
    font_color_hex(pdf, &page, &input.font_color);
    thickness(pdf, &page, parse_thickness(&input.line_thickness));

    let part_size = 12. / 3.;

    let r = part_size / 2.;
    circle(pdf, &page, 0. + r, 15. - part_size - r, r);

    let dy = 15. - part_size;
    let a = (1.5 * part_size, dy + 0.0 * part_size);
    let b = (1.5 * part_size, dy + 1.0 * part_size);
    let c = (1.0 * part_size, dy + 0.5 * part_size);
    let d = (2.0 * part_size, dy + 0.5 * part_size);
    line(pdf, &page, a.0, a.1, Some(c.0), Some(c.1));
    line(pdf, &page, b.0, b.1, Some(c.0), Some(c.1));
    line(pdf, &page, b.0, b.1, Some(d.0), Some(d.1));
    line(pdf, &page, a.0, a.1, Some(d.0), Some(d.1));

    let dy = 15. - 2. * part_size;
    let a = (part_size, dy + 0.0 * part_size);
    let b = (part_size, dy + 1.0 * part_size);
    let c = (2.0 * part_size, dy + 0. * part_size);
    let d = (2.0 * part_size, dy + 1. * part_size);
    line(pdf, &page, a.0, a.1, Some(c.0), Some(c.1));
    line(pdf, &page, b.0, b.1, Some(c.0), Some(c.1));
    line(pdf, &page, b.0, b.1, Some(d.0), Some(d.1));
    line(pdf, &page, a.0, a.1, Some(d.0), Some(d.1));

    let height = part_size;
    let side = 2. / (3. as f32).sqrt() * part_size;
    line(pdf, &page, part_size * 2.5, 15. - part_size,
        Some(part_size * 2.5 - side / 2.), Some(15. - part_size * 2.)
    );
    line(pdf, &page, part_size * 2.5, 15. - part_size,
        Some(part_size * 2.5 + side / 2.), Some(15. - part_size * 2.)
    );
    line(pdf, &page,
        part_size * 2.5 - side / 2.,
        15. - part_size * 2.,
        Some(part_size * 2.5 + side / 2.),
        Some(15. - part_size * 2.),
    );

    for yy in 1..=7 {
        let y = yy as f32;
        line(pdf, &page, 0., y, Some(12.), Some(y));
    }
}

#[wasm_bindgen]
pub fn make_teeth(given: JsValue) -> JsValue {
    let data: PageData = None;
    let title = "Teeth";

    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    use serde_wasm_bindgen::from_value;
    let input: InputTeeth = from_value(given).unwrap();

    let mut page = pdf.page(0);
    let mut render = Render::new(&pdf, page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    let data: PageData = None;
    let mut pdf = PDF::new(&input.title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    // front page belongs to "-" pages
    let root = pdf.page(0);
    let page = root.clone();
    let minus_page = root.clone();
    let count_consecutive = 23;

    let mut render = Render::new(&pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));
    render.tick(1, count_consecutive);

    for y in 1..=(render.grid.h - 1.) as usize {
        render.line(0., y as f32, render.grid.w, y as f32);
    }

    for i in 2..=count_consecutive {
        let page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page, grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
        render.tick(i, count_consecutive);

        for y in 1..=(render.grid.h - 1.) as usize {
            render.line(0., y as f32, render.grid.w, y as f32);
        }
    }

    // + page
    let page = pdf.add_page(None);
    let plus_page = page.clone();
    let mut render = Render::new(&pdf, page, grid.clone());
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

    // + nested pages generation
    for yy in 0..6 {
        for xx in 0..6 {
            let number = xx + yy * 6 + 1;
            let subheader = number.to_string();
            let mut first_item_page: Option<Page<Option<String>>> = None;

            if input.teeth_pages.is_none() && input.hal_pages.is_none() && input.sandworm_pages.is_none() { panic!("alaaaarm!"); }

            if (input.teeth_pages.is_some()) {
                let page = pdf.add_page(Some(subheader.clone()));
                first_item_page = Some(page.clone());

                // todo-list page
                let mut render = Render::new(&pdf, page.clone(), grid.clone());
                render.line_color_hex(&input.grid_color);
                render.font_color_hex(&input.font_color);
                render.thickness(parse_thickness(&input.line_thickness));

                // omg it is, just keeping the space, can use any side as start now
                // render.circle_omg(6., 0., 2.);
                // render.circle_omg(2., 0., 2.);
                // render.circle_omg(10., 0., 2.);

                let tooth_depth = 2.;
                let tooth_gap = 4.;

                let step = 2.; // hardcoded in ↓ too
                for ay in vec![2., 4., 6., 8., 10., 12., 14.] {
                    let ay = ay + 1.; // to center? then shark has both ends...

                    if ay == 3. {
                        render.line(0., ay, tooth_gap, ay);
                        render.line(12., ay, 12. - tooth_gap, ay);
                    }

                    // todo-square
                    render.rect(1., ay + 1., 2., ay + 2.);


                    // let items = vec![0.5, 1., 1.5];
                    let items = vec![0.25, 0.5, 0.75, 1., 1.25, 1.5];
                    use rand::seq::SliceRandom;
                    use rand::thread_rng;
                    use rand::Rng;
                    use wasm_bindgen::prelude::*;
                    let mut rng = thread_rng();
                    let dy = items.choose(&mut rng).unwrap();
                    render.line(tooth_gap, ay, tooth_gap - tooth_depth, ay + dy);
                    render.line(tooth_gap - tooth_depth, ay + dy, tooth_gap, ay + step);

                    // let dy = items.choose(&mut rng).unwrap();
                    render.line(12. - tooth_gap, ay, 12. - tooth_gap + tooth_depth, ay + dy);
                    render.line(12. - tooth_gap + tooth_depth, ay + dy, 12. - tooth_gap, ay + step);
                }
            }
            if (input.sandworm_pages.is_some()) {
                let page = pdf.add_page(Some(subheader.clone()));
                if first_item_page.is_none() {
                    first_item_page = Some(page.clone());
                }
                let mut render = Render::new(&pdf, page.clone(), grid.clone());
                render.line_color_hex(&input.grid_color);
                render.font_color_hex(&input.font_color);
                render.thickness(parse_thickness(&input.line_thickness));

                let worm = |midx: f32, midy: f32, radius: f32| {
                    let side = radius * 2.;
                    let part_size = side / 4.;
                    // let mid_size = part_size * 2.;

                    // inside worm part goes first
                    let x0 = midx - radius;
                    let y0 = midy - radius;
                    let x1 = midx + radius;
                    let y1 = midy + radius;

                    render.line(midx - part_size, midy - part_size, midx + part_size, midy + part_size);
                    render.line(midx - part_size, midy + part_size, midx + part_size, midy - part_size);
                    render.line(midx, midy - part_size, midx, midy + part_size);

                    let lines_inside = 8;
                    let step = (part_size * 2.) / lines_inside as f32;
                    for i in 0..=16 {
                        let y = y0 + i as f32 * step;
                        render.line(x0, y, x1, y);
                        // render.line(x0 + part_size, y, x1 - part_size, y);
                    }
                    render.draw_worm_teeth(midx, midy, part_size*1.4142, 0.);

                    render.square(midx, midy, radius);
                    // render.square(midx, midy, radius / 2.);


                    let x = x0 + part_size;
                    render.line(x, y0, x, y0 + part_size);
                    render.line(x, y1, x, y1 - part_size);
                    let x = x0 + 2. * part_size;
                    render.line(x, y0, x, y0 + part_size);
                    render.line(x, y1, x, y1 - part_size);
                    let x = x0 + 3. * part_size;
                    render.line(x, y0, x, y0 + part_size);
                    render.line(x, y1, x, y1 - part_size);

                    let y = y0 + part_size;
                    render.line(x0, y, x0 + part_size, y);
                    render.line(x1, y, x1 - part_size, y);
                    let y = y0 + 2. * part_size;
                    render.line(x0, y, x0 + part_size, y);
                    render.line(x1, y, x1 - part_size, y);
                    let y = y0 + 3. * part_size;
                    render.line(x0, y, x0 + part_size, y);
                    render.line(x1, y, x1 - part_size, y);

                    let cx = 1.;
                    let cy = 1.;
                    // render.line_text("I", cx + 2. - 0.05, cy - 2.);
                    render.line_start_text("6", 3., 2.);
                    render.line_start_text("7", 0., 2.);
                    render.line_start_text("8", 0., 5.);
                    render.line_start_text("9", 0., 8.);
                    render.line_start_text("10", 0., 11.);
                    let pad = 0.05;
                    render.line_text("5", 9. - pad, 2.);
                    render.line_text("4", 12. - pad, 2.);
                    render.line_text("3", 12. - pad, 5.);
                    render.line_text("2", 12. - pad, 8.);
                    render.line_text("1", 12. - pad, 11.);

                    render.line_start_text("11", 3., 14. - 0.35);
                    render.line_text("12", 9. - pad, 14. - 0.35);
                };

                worm(6., 8., 6.);

            }
            if (input.hal_pages.is_some()) {
                let page = pdf.add_page(Some(subheader.clone()));
                if first_item_page.is_none() {
                    first_item_page = Some(page.clone());
                }

                // hal-review page
                let mut render = Render::new(&pdf, page.clone(), grid.clone());
                render.line_color_hex(&input.grid_color);
                render.font_color_hex(&input.font_color);
                render.thickness(parse_thickness(&input.line_thickness));

                // let dx = 0;
                // let dy = 0;

                for y in 1..=(render.grid.h - 1.) as usize {
                    if y != 7 && y != 8 && y != 1 && y != 2 {
                        render.line(0., y as f32, render.grid.w, y as f32);
                    } else if y == 7 || y == 8 {
                        render.line(3., y as f32, render.grid.w - 3., y as f32);
                    } else if y == 1 || y == 2 {
                        render.line(0., y as f32, 3., y as f32);
                        render.line(12. - 0., y as f32, 12. - 3., y as f32);
                    }
                }
                render.line(3., 0., 3., render.grid.h - 1.);
                render.line(12. - 3., 0., 12. - 3., render.grid.h - 1.);

                for x in vec![1. ,2., 12. - 1., 12. - 2.] {
                    for y0 in vec![0. ,9.] {
                        render.line(x, y0 + 0., x, y0 + 6.);
                    }
                }

                render.line(1.5, 6., 1.5, 9.);
                render.line(12. - 1.5, 6., 12. - 1.5, 9.);
                render.line(0., 7.5, 3., 7.5);
                render.line(12. - 0., 7.5, 12. - 3., 7.5);

                render.line(3. + 1.5, 0., 3. + 1.5, 3.);
                render.line(4.5 + 1.5, 0., 4.5 + 1.5, 3.);
                render.line(6. + 1.5, 0., 6. + 1.5, 3.);

                render.line(3., 1.5, 12. - 3., 1.5);

                render.circle_omg(6., 3., 3.);

                let icons = |dx: f32, dy: f32| {
                    let r_span = 0.66 / 2.;
                    // render.circle_omg(dx + 1.5, dy + 1.5, r_span);

                    let triangle = |center_x, center_y, r_span| {
                        // Calculate points for equilateral triangle
                        // Angle between points is 120 degrees (2π/3 radians)
                        let angle_offset = std::f32::consts::PI / 2.0; // Start from top point

                        // Point 1 (top)
                        let x1 = center_x + r_span * angle_offset.cos();
                        let y1 = center_y + r_span * angle_offset.sin();

                        // Point 2 (bottom right)
                        let x2 = center_x + r_span * (angle_offset + 2.0 * std::f32::consts::PI / 3.0).cos();
                        let y2 = center_y + r_span * (angle_offset + 2.0 * std::f32::consts::PI / 3.0).sin();

                        // Point 3 (bottom left)
                        let x3 = center_x + r_span * (angle_offset + 4.0 * std::f32::consts::PI / 3.0).cos();
                        let y3 = center_y + r_span * (angle_offset + 4.0 * std::f32::consts::PI / 3.0).sin();

                        let ys = 0.;
                        // let y_shift_1: f32 = r_span * (std::f32::consts::PI / 2.0).sin();
                        // let y_shift_2: f32 = r_span * (std::f32::consts::PI / 3.0).sin();
                        // let ys = (y_shift_1 - y_shift_2).round().abs() * 10.;

                        // Draw the triangle
                        render.line(x1, y1 - ys, x2, y2 - ys);
                        render.line(x2, y2 - ys, x3, y3 - ys);
                        render.line(x3, y3 - ys, x1, y1 - ys);
                    };
                    let inverse_triangle = |center_x, center_y, r_span| {
                        // Calculate points for equilateral triangle
                        // Angle between points is 120 degrees (2π/3 radians)
                        let angle_offset = 3. * std::f32::consts::PI / 2.0;

                        // Point 1 (bottom)
                        let x1 = center_x + r_span * angle_offset.cos();
                        let y1 = center_y + r_span * angle_offset.sin();

                        // Point 2
                        let x2 = center_x + r_span * (angle_offset + 2.0 * std::f32::consts::PI / 3.0).cos();
                        let y2 = center_y + r_span * (angle_offset + 2.0 * std::f32::consts::PI / 3.0).sin();

                        // Point 3
                        let x3 = center_x + r_span * (angle_offset + 4.0 * std::f32::consts::PI / 3.0).cos();
                        let y3 = center_y + r_span * (angle_offset + 4.0 * std::f32::consts::PI / 3.0).sin();

                        let half_x = (x2 + x3) / 2.;

                        // Draw the triangle
                        render.line(x1, y1, x2, y2);
                        // render.line(x2, y2, x3, y3);
                        render.line(x2, y2, half_x, y3);
                        render.line(x3, y3, x1, y1);
                    };

                    // let center_x = dx + 1.5;
                    // let center_y = dy + 1.5;
                    // render.circle_omg(center_x, center_y, r_span);
                    // triangle(center_x, center_y, r_span);

                    triangle(dx + 2.5, dy + 3. + 2.5, r_span);
                    inverse_triangle(dx + 1.5, dy + 3. + 2.5, r_span);

                    let cx = dx + 2.5;
                    let cy = dy + 3.5;
                    let span = r_span / 2.;
                    render.line(cx - span, cy, cx + span, cy);
                    render.line(cx, cy - span, cx, cy + span);

                    // # / =
                    // let cx = dx + 1.5;
                    // let cy = dy + 4.5;
                    // let shift = r_span / 3.;
                    // let span = r_span / 3. * 2.;
                    // render.line(cx - span, cy - shift, cx + span, cy - shift);
                    // render.line(cx - span, cy + shift, cx + span, cy + shift);
                    // render.line(cx - shift, cy - span, cx - shift, cy + span);
                    // render.line(cx + shift, cy - span, cx + shift, cy + span);

                    // square
                    let span = r_span / 2.;
                    let cx = dx + 1.5;
                    let cy = dy + 3.5;
                    let x1 = cx - span;
                    let x2 = cx + span;
                    let y1 = cy - span;
                    let y2 = cy + span;
                    render.line(x1, y1, x2, y1);
                    render.line(x1, y1, x1, y2);
                    render.line(x2, y2, x1, y2);
                    render.line(x2, y2, x2, y1);

                    // x
                    let span = r_span / 2.;
                    let cx = dx + 2.5;
                    let cy = dy + 4.5;
                    let x1 = cx - span;
                    let x2 = cx + span;
                    let y1 = cy - span;
                    let y2 = cy + span;
                    render.line(x1, y1, x2, y2);
                    render.line(x2, y1, x1, y2);

                    // // square with circle
                    // let span = r_span / 2.;
                    // let cx = dx + 2.5;
                    // let cy = dy + 1.5;
                    // let x1 = cx - span;
                    // let x2 = cx + span;
                    // let y1 = cy - span;
                    // let y2 = cy + span;
                    // render.line(x1, y1, x2, y1);
                    // render.line(x1, y1, x1, y2);
                    // render.line(x2, y2, x1, y2);
                    // render.line(x2, y2, x2, y1);
                    // render.circle_omg(cx, cy, span * 0.8);

                    let span = r_span / 2.;
                    let cx = dx + 0.5;
                    let cy = dy + 5.5;
                    let x1 = cx - span;
                    let y1 = cy - span;
                    render.draw_tilde(x1, y1+span, span*2., span*2.);

                    let spanx = r_span * 0.66; // / 2.;i * 1.33;
                    let spany = r_span / 2.;
                    let cx = dx + 0.5;
                    let cy = dy + 4.5;
                    // render.draw_spiral(cx, cy, 0., 0., span, span, 3., Some(0.), Some(true));
                    // render.draw_spiral(cx, cy, 0., 0., span, span, 2., Some(0.), Some(true));
                    // render.draw_spiral(cx, cy, 0., 0., span, span, 1., Some(0.), Some(true));
                    render.draw_spiral(cx, cy, 0., 0., spanx, span, 1.5, Some(0.), Some(true));

                    let spanx = r_span * 0.5;
                    let spany = r_span * 0.66;
                    let cx = dx + 0.5;
                    let cy = dy + 3.5;
                    render.draw_gate(cx, cy, spanx, spany);

                    let cx = dx + 1.5;
                    let cy = dy + 2.5;
                    render.circle_omg(cx, cy, span);
                    render.line(cx, cy - span, cx, cy + span);

                    let cx = dx + 0.5;
                    let cy = dy + 2.5;
                    render.circle_omg(cx, cy, span);
                    render.line(cx - span, cy, cx + span, cy);

                    let cx = dx + 0.5;
                    let cy = dy + 1.5;
                    render.circle_omg(cx, cy, span);
                    render.line(cx - span, cy, cx + span, cy);
                    render.line(cx, cy - span, cx, cy + span);

                    let cx = dx + 0.5;
                    let cy = dy + 0.5;
                    render.circle_omg(cx, cy, span);
                    let delta = span * 0.25;
                    render.line(cx - span, cy - delta, cx + span, cy - delta);
                    render.line(cx - span, cy + delta, cx + span, cy + delta);

                    // cog / atlas
                    let cx = dx + 1.5;
                    let cy = dy + 0.5;
                    render.circle_omg(cx, cy, span);
                    // render.square(cx, cy, span * 0.66);
                    // render.square(cx, cy, span * 0.8);
                    // render.square(cx, cy, span * 0.9);
                    render.square(cx, cy, span * 0.85);

                    let cx = dx + 1.5;
                    let cy = dy + 1.5;
                    render.circle_omg(cx, cy, span);
                    render.circle_omg(cx, cy, span * 0.5);

                    let cx = dx + 2.5;
                    let cy = dy + 2.5;
                    render.diamond(cx, cy, span * 0.85);
                    let s = span * 0.33;
                    render.line(cx - s, cy, cx + s, cy);
                    render.line(cx, cy - s, cx, cy + s);

                    let cx = dx + 2.5;
                    let cy = dy + 1.5;
                    render.diamond(cx, cy, span * 0.85);
                    let delta = span * 0.50;
                    let s = span * 0.7;
                    render.line(cx - delta, cy - s, cx - delta, cy + s);
                    render.line(cx + delta, cy - s, cx + delta, cy + s);

                    let cx = dx + 2.5;
                    let cy = dy + 0.5;
                    render.diamond(cx, cy, span * 0.85);
                    // let s = span * 0.7;
                    let s = span * 0.6;
                    render.line(cx - s, cy - s, cx + s, cy + s);
                    render.line(cx - s, cy + s, cx + s, cy - s);
                };

                icons(0., 0.);
                icons(9., 0.);
                icons(0., 9.);
                icons(9., 9.);
            }

            if let Some(first_item_page) = first_item_page {
                // link from grid into the entry
                let mut render = Render::new(&pdf, plus_page.clone(), grid.clone());
                render.line_color_hex(&input.grid_color);
                render.font_color_hex(&input.font_color);
                render.thickness(parse_thickness(&input.line_thickness));

                let size = 2.;
                let x = xx as f32;
                let y = yy as f32;
                let door = Area::xywh(x * size, 13. - y * size, size, size);
                render.link(&first_item_page, door.clone());

                let tooth = 0.66 * 0.5 * size;
                let area = door;
                let odd_number = number & 1 != 0;
                let odd_x = xx & 1 != 0;
                let odd_y = yy & 1 != 0;

                let saw_ltr = (odd_y && odd_number) || (!odd_y && !odd_number);

                if saw_ltr {
                    render.line(area.x1, area.y1, area.x1 + tooth, (area.y2 + area.y1) / 2.);
                    render.line(area.x1, area.y2, area.x1 + tooth, (area.y2 + area.y1) / 2.);
                    render.line(area.x2, area.y1, area.x2 - tooth, (area.y2 + area.y1) / 2.);
                    render.line(area.x2, area.y2, area.x2 - tooth, (area.y2 + area.y1) / 2.);
                } else {
                    render.line(area.x1, area.y1, (area.x1 + area.x2) / 2., area.y1 + tooth);
                    render.line(area.x2, area.y1, (area.x1 + area.x2) / 2., area.y1 + tooth);
                    render.line(area.x1, area.y2, (area.x1 + area.x2) / 2., area.y2 - tooth);
                    render.line(area.x2, area.y2, (area.x1 + area.x2) / 2., area.y2 - tooth);
                }

                render.corner_text(&first_item_page.data.clone().unwrap(), area.x2, area.y1);
            }
        }
    }

    let page = pdf.add_page(None);
    let maze_page = page.clone();

    let mut render = Render::new(&pdf, page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    let zigzag = |y_low, odd| {
        let y_high = y_low + 1.;
        let mut xs = vec![
            (1., y_high),
            (2., y_high),
            (2., y_low),
            (3., y_low),
            (3., y_high),
            (4., y_high),
            (4., y_low),
            (5., y_low),
            (5., y_high),
            (6., y_high),
            (6., y_low),
            (7., y_low),
            (7., y_high),
            (8., y_high),
            (8., y_low),
            (9., y_low),
            (9., y_high),
            (10., y_high),
            (10., y_low),
            (11., y_low),
            // (11., y_high),
        ];
        if odd {
            xs.remove(0);
            xs.remove(0);
            xs.push((11., y_high));
            xs.push((12., y_high));
            xs.iter_mut().for_each(|x|
                x.0 = x.0 - 1.
            );
            xs.reverse();
        }

        xs
    };

    let mut poly = vec![];
    poly.append(&mut zigzag(13.0, false));
    poly.append(&mut zigzag(11.0, true));
    poly.append(&mut zigzag(9.0, false));
    poly.append(&mut zigzag(7.0, true));
    poly.append(&mut zigzag(5.0, false));
    poly.append(&mut zigzag(3.0, true));
    poly.append(&mut zigzag(1.0, false));
    render.poly(poly);

    let mut places: Vec<(f32, f32)> = vec![];

    for xx in vec![2, 4, 6, 8, 10] {
        for yy in vec![1, 3, 5, 7, 9, 11, 13] {
            let x = xx as f32 + 0.5;
            let y = yy as f32 + 0.5;
            places.push((x, y));
            let side = 0.5;

            let height = (3.0_f32).sqrt() * side / 2.0;
            let radius = height * (2.0 / 3.0);

            let a = (x, y + radius);
            let b = (x - side / 2.0, y - radius / 2.0);
            let c = (x + side / 2.0, y - radius / 2.0);
            render.poly(
                vec![
                    a, b, c, a
                ]
            );
        }
    }

    let mut pages: Vec<Page<Option<String>>> = vec![];

    for (xx, yy) in &places {
        let page = pdf.add_page(None);
        pages.push(page.clone());

        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
        // // render.circle_omg(12., 0., 2.);
        // render.circle_omg(10., 0., 2.);
        // // render.circle_omg(8., 0., 2.);
        // // render.circle_omg(6., 0., 2.);
        // // render.circle_omg(4., 0., 2.);
        // render.circle_omg(2., 0., 2.);
        // // render.circle_omg(0., 0., 2.);

        let high_y = 5.;
        let low_y = 1.;

        render.poly(vec![
            (0., high_y),
            (4., high_y),
            (4., 16.),
        ]);
        render.poly(vec![
            (12. - 0., high_y),
            (12. - 4., high_y),
            (12. - 4., 16.),
        ]);

        render.poly(vec![
            (0., low_y),
            (4., low_y),
            (4., 0.),
        ]);
        render.poly(vec![
            (12. - 0., low_y),
            (12. - 4., low_y),
            (12. - 4., 0.),
        ]);
    }

    let mut render = Render::new(&pdf, maze_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    use rand::rngs::OsRng;
    use rand::seq::SliceRandom; // or StdRng with a seed
    places.shuffle(&mut OsRng); // or StdRng::from_entropy()
    // maze is not for multi-page nonsense

    for i in 0..places.len() {
        let place = places[i];
        let page = pages[i].clone();

        let size = 1.;
        let x = place.0 - size / 2.;
        let y = place.1 - size / 2.;
        let door = Area::xywh(x * size, y * size, size, size);
        render.link(&page, door.clone());
    }

    // after all pages are there,
    // render header and navigation for all pages
    //
    for page in pdf.pages.iter() {
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
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
            &maze_page,
            "#",
            Area::xywh(12. - 1.5*2., 16., -1.5, -1. + 0.02),
        );
        render.header_link(
            &minus_page,
            "-",
            Area::xywh(12. - 1.5, 16., -1.5, -1. + 0.02),
        );
        render.header_link(&plus_page, "+", Area::xywh(12., 16., -1.5, -1. + 0.02));
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}



#[wasm_bindgen]
pub fn make_radar(given: JsValue) -> JsValue {
    let data: PageData = None;
    let title = "Radar";

    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    use serde_wasm_bindgen::from_value;
    let input: Input123 = from_value(given).unwrap();

    let max_depth = 7; // count of steps user can do before page with no further navigation
    
    let render_page = |mut render: Render<Option<String>>, path: &str| {
        for y in 1..=(render.grid.h - 1.) as usize {
            render.line(0., y as f32, render.grid.w, y as f32);
            render.line(0., -0.5 + y as f32, render.grid.w, -0.5 + y as f32);
        }
        for x in 1..=(render.grid.w) as usize {
            render.line(x as f32, 0., x as f32, render.grid.h - 1.);
            render.line(x as f32 - 0.5, 0., x as f32 - 0.5, render.grid.h - 1.);
        }

        let x0 = 6.;
        let y0 = 0.5;
        let scale = 6.;
        render.thickness(2.);
        render.circle_omg(x0, y0, scale);

        use std::f32::consts::PI;
        let mut point: (f32, f32) = (0., 0.);
        let mut trace: Vec<(f32, f32)> = vec![];
        trace.push(point.clone());
        for (index, ch) in path.chars().enumerate() {
            let mut angle = PI / 2.; // could be top if it didn't lie
            let mut step = 0.;
            match ch {
                'l' => {
                    angle += PI / 4.;
                    step = 1. / max_depth as f32;
                }
                'r' => {
                    angle -= PI / 4.;
                    step = 1. / max_depth as f32;
                }
                'u' => {
                    step = 1. / max_depth as f32;
                }
                _ => { panic!("alaaaaaaaaaaam!"); }
            }
            let dx = step * angle.cos();
            let dy = step * angle.sin();
            point.0 += dx;
            point.1 += dy;
            trace.push(point.clone());
        }

        let mut prev: Option<(f32, f32)> = None;
        trace.iter().for_each(|p|{
            if let Some(got_prev) = prev {
                render.line(x0 + got_prev.0 * scale, y0 + got_prev.1 * scale, x0 + p.0 * scale, y0 + p.1 * scale);
                render.circle_omg(x0 + p.0 * scale, y0 + p.1 * scale, 0.03);
            } else {
                render.circle_omg(x0 + p.0 * scale, y0 + p.1 * scale, 0.03);
            }
            prev = Some(p.clone());
        });

        let count = path.chars().count();
        render.thickness(4.); //parse_thickness(&input.line_thickness));
        let x = x0 + point.0 * scale;
        let y = y0 + point.1 * scale;
        if count == max_depth {
            let r = 0.25;
            render.circle_omg(x, y, r);
            render.circle_omg(x, y, r * 1.5);
            render.circle_omg(x, y, r * 2.);
            render.circle_omg(x, y, r * 2.5);
            render.circle_omg(x, y, r * 3.);
        } else {
            let r = 0.125;
            render.square(x, y, r);
        }
    };

    let mut page = pdf.page(0);
    let mut render = Render::new(&pdf, page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));
    render_page(render, "");

    let mut paths = generate_radar_combinations(max_depth);
    use rand::rngs::OsRng;
    use rand::seq::SliceRandom; // or StdRng with a seed
    paths.shuffle(&mut OsRng); // or StdRng::from_entropy()

    use std::collections::HashMap;
    let mut hash: HashMap<String, Page<Option<String>>> = HashMap::new();
    hash.insert("".into(), page);
    paths.iter().for_each(|path| {
        let page = pdf.add_page(Some(path.into()));
        // let page = pdf.add_page(None);
        hash.insert(path.into(), page.clone());

        let mut render = Render::new(&pdf, page, grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
        render_page(render, &path);
    });

    paths.iter().for_each(|path| {
        let page: Page<Option<String>> = hash.get(path).unwrap().clone();
        let parent_path = &path[..path.len() - 1];
        let parent: Page<Option<String>> = hash.get(parent_path).unwrap().clone();
        let step = path.chars().last().unwrap();

        let mut render = Render::new(&pdf, parent.clone(), grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));

        match step {
            'l' => {
                render.header_link(
                    &page,
                    "<",
                    Area::xywh(5., 16., -2., -1. + 0.02),
                );
            }
            'u' => {
                render.header_link(
                    &page,
                    "|",
                    Area::xywh(5., 16., 2., -1. + 0.02),
                );
            }
            'r' => {
                render.header_link(
                    &page,
                    ">",
                    Area::xywh(7., 16., 2., -1. + 0.02),
                );
            }

                _ => { panic!("alaaaaaaaaaaam!"); }
        }
    });

    for page in pdf.pages.iter() {
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
        let data = page.data.clone();
        let title = input.title.clone();

        render.header(&title);
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

// l u r - directions
static RADAR_MOVE_OPTIONS: [&str; 3] = ["l", "u", "r"];

fn generate_radar_combinations(max_len: usize) -> Vec<String> {
    let mut combinations = Vec::new();
    
    // Pre-allocate capacity to reduce reallocations
    let total_combinations = (3usize.pow(max_len as u32 + 1) - 3) / 2;
    combinations.reserve(total_combinations);
    
    // Start with base combinations
    let mut current = RADAR_MOVE_OPTIONS.iter()
        .map(|&s| s.to_string())
        .collect::<Vec<_>>();
    
    combinations.extend(current.clone());
    
    // Build up combinations iteratively
    for _ in 1..max_len {
        let mut next = Vec::new();
        for combo in current {
            for &option in RADAR_MOVE_OPTIONS.iter() {
                let mut new_combo = combo.clone();
                // new_combo.push(' ');
                new_combo.push_str(option);
                next.push(new_combo);
            }
        }
        combinations.extend(next.clone());
        current = next;
    }
    
    combinations
}

// fn distance(p1: (f32, f32), p2: (f32, f32)) -> f32 {
//     let dx = p1.0 - p2.0;
//     let dy = p1.1 - p2.1;
//     (dx * dx + dy * dy).sqrt()
// }

#[wasm_bindgen]
pub fn make_rolls(given: JsValue) -> JsValue {
    let data: PageData = None;
    let title = "Rolls";

    use serde_wasm_bindgen::from_value;
    let input: Input123 = from_value(given).unwrap();

    let data: PageData = None;
    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    // front page belongs to "-" pages
    let root = pdf.page(0);
    let page = root.clone();
    let minus_page = root.clone();
    let count_consecutive = 23;

    let mut render = Render::new(&pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));
    render.tick(1, count_consecutive);

    for y in 1..=(render.grid.h - 1.) as usize {
        render.line(0., y as f32, render.grid.w, y as f32);
    }

    for i in 2..=count_consecutive {
        let page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page, grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
        render.tick(i, count_consecutive);

        for y in 1..=(render.grid.h - 1.) as usize {
            render.line(0., y as f32, render.grid.w, y as f32);
        }
    }

    // + page
    let page = pdf.add_page(None);
    let plus_page = page.clone();
    let mut render = Render::new(&pdf, page, grid.clone());
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

    // + nested pages generation
    let mut pages_24: Vec<Page<Option<String>>> = vec![];
    for yy in 0..6 {
        for xx in 0..6 {
            let number = xx + yy * 6 + 1;
            let subheader = number.to_string();

            let page = pdf.add_page(Some(subheader.clone()));
            pages_24.push(page.clone());
            let first_item_page = page.clone();

            // hours 24 squares mostly
            let mut render = Render::new(&pdf, page.clone(), grid.clone());
            render.line_color_hex(&input.grid_color);
            render.font_color_hex(&input.font_color);
            render.thickness(parse_thickness(&input.line_thickness));

            render_24(render.clone());

            for y in vec![1.5, 2., 2.5, 3., 3.5, 4., 4.5, 5., 5.5, 6., 6.5, 7., 7.5, 8., 8.5, 9., 9.5, 10., 10.5, 11., 11.5, 12., 12.5] {
                render.line(2., y, 12. - 2., y);
            }

            // link from grid into the entry
            let mut render = Render::new(&pdf, plus_page.clone(), grid.clone());
            render.line_color_hex(&input.grid_color);
            render.font_color_hex(&input.font_color);
            render.thickness(parse_thickness(&input.line_thickness));

            let size = 2.;
            let x = xx as f32;
            let y = yy as f32;
            let door = Area::xywh(x * size, 13. - y * size, size, size);
            render.link(&first_item_page, door.clone());
            let area = door;

            render.corner_text(&first_item_page.data.clone().unwrap(), area.x2, area.y1);
        }
    }

    // nested hour pages
    let mut cells: Vec<(f32, f32, String)> = vec![];
    cells.push((0., 1., "6".into()));
    cells.push((0., 3., "7".into()));
    cells.push((0., 5., "8".into()));
    cells.push((0., 7., "9".into()));
    cells.push((0., 9., "10".into()));
    cells.push((0., 11., "11".into()));
    cells.push((0., 13., "12".into()));

    cells.push((2., 13., "13".into()));
    cells.push((4., 13., "14".into()));
    cells.push((6., 13., "15".into()));
    cells.push((8., 13., "16".into()));
    cells.push((10., 13., "17".into()));

    cells.push((10., 11., "18".into()));
    cells.push((10., 9., "19".into()));
    cells.push((10., 7., "20".into()));
    cells.push((10., 5., "21".into()));
    cells.push((10., 3., "22".into()));
    cells.push((10., 1., "23".into()));

    let mut hour_pages: Vec<Page<Option<String>>> = vec![];

    for page in pages_24 {
        for (x, y, text) in &cells {
            let data = page.data.clone().map(|x| format!("{} >> {}", x, text));
            let hour_page = pdf.add_page(data);
            hour_pages.push(hour_page.clone());

            let mut render = Render::new(&pdf, hour_page.clone(), grid.clone());
            render.line_color_hex(&input.grid_color);
            render.font_color_hex(&input.font_color);
            render.thickness(parse_thickness(&input.line_thickness));
            render_24(render.clone());
            for y in vec![1.5, 2., 2.5, 3., 3.5, 4., 4.5, 5., 5.5, 6., 6.5, 7., 7.5, 8., 8.5, 9., 9.5, 10., 10.5, 11., 11.5, 12., 12.5] {
                render.line(2., y, 12. - 2., y);
            }
            for x in vec![2.5, 3., 3.5, 4., 4.5, 5., 5.5, 6., 6.5, 7., 7.5, 8., 8.5, 9., 9.5] {
                render.line(x, 1., x, 15. - 2.);
            }

            for r in vec![1., 0.9, 0.5, 0.75] {
                render.circle_omg(*x + 0.4, *y + 1., 0.3 * r);
            }

            let door = Area::xywh(1., 15., 5., 1.);
            render.link(&page, door.clone());

            // parent has link
            let mut render = Render::new(&pdf, page.clone(), grid.clone());
            render.line_color_hex(&input.grid_color);
            render.font_color_hex(&input.font_color);
            render.thickness(parse_thickness(&input.line_thickness));
            let door = Area::xywh(*x, *y, 2., 2.);
            render.link(&hour_page, door.clone());
        }
    }

    for page in &hour_pages {
        let header = page.data.clone().unwrap();
        let pos = header.find(">>").unwrap();
        let template = format!("{} ", &header[..pos + 2]);

        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));

        for (x, y, text) in &cells {
            let query = format!("{}{}", template, text);
            let cell_page = hour_pages.iter().find(|x| x.data.clone().unwrap() == query).unwrap();
            let door = Area::xywh(*x, *y, 2., 2.);
            render.link(&cell_page, door.clone());
        }
    }

    // (scratchpad) maze pages part

    let page = pdf.add_page(None);
    let maze_page = page.clone();

    let mut render = Render::new(&pdf, page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    let mut places: Vec<(f32, f32)> = vec![];

    for xx in 1..=10 {
        for yy in 1..=13 {
            let x = xx as f32 + 0.5;
            let y = yy as f32 + 0.5;
            places.push((x, y));
            let side = 0.5;

            render.circle_omg(x, y, side);
        }
    }

    let mut pages: Vec<Page<Option<String>>> = vec![];

    for (xx, yy) in &places {
        let page = pdf.add_page(None);
        pages.push(page.clone());
    }

    let mut render = Render::new(&pdf, maze_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    use rand::rngs::OsRng;
    use rand::seq::SliceRandom;
    places.shuffle(&mut OsRng);
    // maze is not for multi-page nonsense

    for i in 0..places.len() {
        let place = places[i];
        let page = pages[i].clone();

        let size = 1.;
        let x = place.0 - size / 2.;
        let y = place.1 - size / 2.;
        let door = Area::xywh(x * size, y * size, size, size);
        render.link(&page, door.clone());
    }

    let triangle_page = pdf.add_page(None);

    let mut render = Render::new(&pdf, triangle_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    render_plain_triangle_page(render);
    // render_ternary_plot_page(render);

    // render.tick(1, 3);
    // render_triangle_page(render, 0, 10);
    //
    // let next_triangle_page = pdf.add_page(None);
    // let mut render = Render::new(&pdf, next_triangle_page.clone(), grid.clone());
    // render.line_color_hex(&input.grid_color);
    // render.font_color_hex(&input.font_color);
    // render.thickness(parse_thickness(&input.line_thickness));
    // render.tick(2, 3);
    // render_triangle_page(render, 10, 10);
    //
    // let next_triangle_page = pdf.add_page(None);
    // let mut render = Render::new(&pdf, next_triangle_page.clone(), grid.clone());
    // render.line_color_hex(&input.grid_color);
    // render.font_color_hex(&input.font_color);
    // render.thickness(parse_thickness(&input.line_thickness));
    // render.tick(3, 3);
    // render_triangle_page(render, 20, 10);

    // after all pages are there,
    // render header and navigation for all pages
    //
    for page in pdf.pages.iter() {
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
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
            &maze_page,
            // "#",
            "",
            Area::xywh(12. - 1.5*3., 16., -1.5, -1. + 0.02),
        );
        render.thickness(1.5);
        render.line_color_hex(&input.font_color);
        render.circle_omg(
          8.25 - 1.5, 15.5, 0.15
        );
        render.header_link(
            &minus_page,
            "-",
            Area::xywh(12. - 1.5 * 2., 16., -1.5, -1. + 0.02),
        );
        render.header_link(&plus_page, "+", Area::xywh(12. - 1.5, 16., -1.5, -1. + 0.02));

        let x = 8.25 + 3.;
        let y = 15.5 - 0.025;

        let side = 0.33;
        let height = (3.0_f32).sqrt() * side / 2.0;
        let radius = height * (2.0 / 3.0);
        let a = (x, y + radius);
        let b = (x - side / 2.0, y - radius / 2.0);
        let c = (x + side / 2.0, y - radius / 2.0);
        render.closed_poly(
            vec![
                a, b, c, a
            ]
        );
        render.header_link(
            &triangle_page,
            "",
            Area::xywh(12., 16., -1.5, -1. + 0.02),
        );
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

#[wasm_bindgen]
pub fn make_rue(given: JsValue) -> JsValue {
    let data: PageData = None;
    let title = "RUE";

    use serde_wasm_bindgen::from_value;
    let input: Input123 = from_value(given).unwrap();

    let data: PageData = None;
    let mut pdf = PDF::new(&title, Setup::rm_pro(), data);
    let grid = Grid::new(12., 16.);

    // front page belongs to "-" pages
    let root = pdf.page(0);
    let page = root.clone();
    let minus_page = root.clone();
    let count_consecutive = 23;

    let mut render = Render::new(&pdf, page, grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));
    render.tick(1, count_consecutive);

    for y in 1..=(render.grid.h - 1.) as usize {
        render.line(0., y as f32, render.grid.w, y as f32);
    }

    for i in 2..=count_consecutive {
        let page = pdf.add_page(None);
        let mut render = Render::new(&pdf, page, grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
        render.tick(i, count_consecutive);

        for y in 1..=(render.grid.h - 1.) as usize {
            render.line(0., y as f32, render.grid.w, y as f32);
        }
    }

    // + page
    let page = pdf.add_page(None);
    let plus_page = page.clone();
    let mut render = Render::new(&pdf, page, grid.clone());
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

    // + nested pages generation
    let mut pages_24: Vec<Page<Option<String>>> = vec![];
    for yy in 0..6 {
        for xx in 0..6 {
            let number = xx + yy * 6 + 1;
            let subheader = number.to_string();

            let page = pdf.add_page(Some(subheader.clone()));
            pages_24.push(page.clone());
            let first_item_page = page.clone();

            // hours 24 squares mostly
            let mut render = Render::new(&pdf, page.clone(), grid.clone());
            render.line_color_hex(&input.grid_color);
            render.font_color_hex(&input.font_color);
            render.thickness(parse_thickness(&input.line_thickness));

            render_simple_plus_page(render.clone());

            // link from grid into the entry
            let mut render = Render::new(&pdf, plus_page.clone(), grid.clone());
            render.line_color_hex(&input.grid_color);
            render.font_color_hex(&input.font_color);
            render.thickness(parse_thickness(&input.line_thickness));

            let size = 2.;
            let x = xx as f32;
            let y = yy as f32;
            let door = Area::xywh(x * size, 13. - y * size, size, size);
            render.link(&first_item_page, door.clone());
            let area = door;

            render.corner_text(&first_item_page.data.clone().unwrap(), area.x2, area.y1);
        }
    }

    // (scratchpad) maze pages part

    let page = pdf.add_page(None);
    let maze_page = page.clone();

    let mut render = Render::new(&pdf, page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    let mut places: Vec<(f32, f32)> = vec![];

    for xx in 1..=10 {
        for yy in 1..=13 {
            let x = xx as f32 + 0.5;
            let y = yy as f32 + 0.5;
            places.push((x, y));
            let side = 0.5;

            render.circle_omg(x, y, side);
        }
    }

    let mut pages: Vec<Page<Option<String>>> = vec![];

    for (xx, yy) in &places {
        let page = pdf.add_page(None);
        pages.push(page.clone());
    }

    let mut render = Render::new(&pdf, maze_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    use rand::rngs::OsRng;
    use rand::seq::SliceRandom;
    places.shuffle(&mut OsRng);
    // maze is not for multi-page nonsense

    for i in 0..places.len() {
        let place = places[i];
        let page = pages[i].clone();

        let size = 1.;
        let x = place.0 - size / 2.;
        let y = place.1 - size / 2.;
        let door = Area::xywh(x * size, y * size, size, size);
        render.link(&page, door.clone());
    }

    let triangle_page = pdf.add_page(None);

    let mut render = Render::new(&pdf, triangle_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    // top x, y for triangle plot
    let ax = 6.;
    let ay = 16. - 4.;
    let step = 1.; // step distance for each shift in coordinate value
    let count = 10; // sum of values in ternary plot is how many steps each triangle side contains
    render_ternary_plot(ax, ay, step, count, render.clone());

    let another_triangle_page = pdf.add_page(None);

    let mut render = Render::new(&pdf, another_triangle_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    // top x, y for triangle plot
    let ax = 6.;
    let ay = 14.;
    let step = 1.; // step distance for each shift in coordinate value
    let count = 8; // sum of values in ternary plot is how many steps each triangle side contains
    render_ternary_plot(ax, ay, step, count, render.clone());

    let ax = 6.;
    let ay = 6.;
    let step = 1.; // step distance for each shift in coordinate value
    let count = 6; // sum of values in ternary plot is how many steps each triangle side contains
    render_ternary_plot(ax, ay, step, count, render.clone());


    // yet another
    let another_triangle_page = pdf.add_page(None);

    let mut render = Render::new(&pdf, another_triangle_page.clone(), grid.clone());
    render.line_color_hex(&input.grid_color);
    render.font_color_hex(&input.font_color);
    render.thickness(parse_thickness(&input.line_thickness));

    // top x, y for triangle plot
    let ax = 6.;
    let ay = 14.;
    let step = 1.; // step distance for each shift in coordinate value
    let count = 4; // sum of values in ternary plot is how many steps each triangle side contains
    render_ternary_plot(ax, ay, step, count, render.clone());

    let ax = 6.;
    let ay = 8.;
    let step = 1.; // step distance for each shift in coordinate value
    let count = 2; // sum of values in ternary plot is how many steps each triangle side contains
    render_ternary_plot(ax, ay, step, count, render.clone());

    let ax = 6.;
    let ay = 4.;
    let step = 1.; // step distance for each shift in coordinate value
    let count = 0; // sum of values in ternary plot is how many steps each triangle side contains
    render_ternary_plot(ax, ay, step, count, render.clone());



    // after all pages are there,
    // render header and navigation for all pages
    //
    for page in pdf.pages.iter() {
        let mut render = Render::new(&pdf, page.clone(), grid.clone());
        render.line_color_hex(&input.grid_color);
        render.font_color_hex(&input.font_color);
        render.thickness(parse_thickness(&input.line_thickness));
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
            &maze_page,
            // "#",
            "",
            Area::xywh(12. - 1.5*3., 16., -1.5, -1. + 0.02),
        );
        render.thickness(1.5);
        render.line_color_hex(&input.font_color);
        render.circle_omg(
          8.25 - 1.5, 15.5, 0.15
        );
        render.header_link(
            &minus_page,
            "-",
            Area::xywh(12. - 1.5 * 2., 16., -1.5, -1. + 0.02),
        );
        render.header_link(&plus_page, "+", Area::xywh(12. - 1.5, 16., -1.5, -1. + 0.02));

        let x = 8.25 + 3.;
        let y = 15.5 - 0.025;

        let side = 0.33;
        let height = (3.0_f32).sqrt() * side / 2.0;
        let radius = height * (2.0 / 3.0);
        let a = (x, y + radius);
        let b = (x - side / 2.0, y - radius / 2.0);
        let c = (x + side / 2.0, y - radius / 2.0);
        render.closed_poly(
            vec![
                a, b, c, a
            ]
        );
        render.header_link(
            &triangle_page,
            "",
            Area::xywh(12., 16., -1.5, -1. + 0.02),
        );
    }

    let bytes: Vec<u8> = pdf.doc.save_to_bytes().unwrap();
    let m = Message { payload: bytes };
    serde_wasm_bindgen::to_value(&m).unwrap()
}

fn render_ternary_plot(ax: f32, ay: f32, step: f32, count: usize, render: Render<Option<String>>) {
    //
    //  a
    // b c
    //

    let a_base_angle = 0.;
    let a_angle_right = a_base_angle - PI / 3.;
    let a_angle_left = a_base_angle - 2. * PI / 3.;

    let bx = ax + a_angle_left.cos() * count as f32;
    let by = ay + a_angle_left.sin() * count as f32;
    let b_base_angle = 0.;
    let b_angle_right = b_base_angle;
    let b_angle_left = b_base_angle + PI / 3.;

    let cx = ax + a_angle_right.cos() * count as f32;
    let cy = ay + a_angle_right.sin() * count as f32;
    let c_base_angle = 2. * PI / 3.;
    let c_angle_right = c_base_angle;
    let c_angle_left = c_base_angle + PI / 3.;

    // lines from a corner
    for aa in 0..=count {
        let x = ax;
        let y = ay;
        let angle_right = a_angle_right;
        let angle_left = a_angle_left;
        let x1 = x + angle_left.cos() * aa as f32;
        let y1 = y + angle_left.sin() * aa as f32;
        let x2 = x + angle_right.cos() * aa as f32;
        let y2 = y + angle_right.sin() * aa as f32;
        render.line(x1, y1, x2, y2);

        let xx = (x1 + x2) / 2.;
        let yy = (y1 + y2) / 2.;
        let text = format!("{}", count - aa);
        render.sm_center_text(&text, xx, yy);
    }
    for bb in 0..=count {
        let x = bx;
        let y = by;
        let angle_right = b_angle_right;
        let angle_left = b_angle_left;
        let x1 = x + angle_left.cos() * bb as f32;
        let y1 = y + angle_left.sin() * bb as f32;
        let x2 = x + angle_right.cos() * bb as f32;
        let y2 = y + angle_right.sin() * bb as f32;
        render.line(x1, y1, x2, y2);

        let xx = (x1 + x2) / 2.;
        let yy = (y1 + y2) / 2.;
        let text = format!("{}", count - bb);
        render.sm_center_text(&text, xx, yy);
    }
    for cc in 0..=count {
        let x = cx;
        let y = cy;
        let angle_right = c_angle_right;
        let angle_left = c_angle_left;
        let x1 = x + angle_left.cos() * cc as f32;
        let y1 = y + angle_left.sin() * cc as f32;
        let x2 = x + angle_right.cos() * cc as f32;
        let y2 = y + angle_right.sin() * cc as f32;
        render.line(x1, y1, x2, y2);

        let xx = (x1 + x2) / 2.;
        let yy = (y1 + y2) / 2.;
        let text = format!("{}", count - cc);
        render.sm_center_text(&text, xx, yy);
    }

    // let angle = base_angle + PI / 3. * i as f32;
    // let x = p.0 + angle.cos() * step;
    // let y = p.1 + angle.sin() * step;

}

// connectivity between days loops, after the day to the next
fn render_plain_triangle_page(render: Render<Option<String>>) {
    let y_items = 1..=30; // simplicity may work, or can add more for symmetry of numbers later
    let yStart = 14.;
    let yRange = -13.; // minus for direction? vector...
    // x spread to be dynamic on levels but can be static before/early
    let xStart = 6.;
    let xRange = 10.;

    let xStep = 10. / 30.;
    let yStep = -13. / 30.;

    for (index, xCount) in y_items.enumerate() {
        let xStart = xStart - (xCount as f32 * xStep) / 2.;
        for i in 0..xCount {
            // let r = 0.2;
            let r = 0.17;
            let x = xStart + xStep * i as f32 + r;
            let y = yStart + yStep * index as f32 - r;
            render.circle_omg(x, y, r);
            if i as f32 == (xCount as f32 / 2.).floor() {
                render.sm_center_text(&format!("{}", index + 1), x, y - r*0.7);
            }
        }
    }
}

fn render_triangle_page(render: Render<Option<String>>, value: usize, count: usize) {
    use std::f32::consts::PI;
    let base_angle = PI / 6.;
    let step = 0.5;
    let point = (6., 8.);
    let mut located: Vec<((f32, f32), usize)> = vec![];
    located.push((point, value));

    for v in (value+1)..=(value+count) {
        let options: Vec<(f32, f32)> = located.iter().filter(|(p,vv)|
            *vv == v - 1
        ).flat_map(|(p,_)|
            (0..=5).map(move |i| {
                let angle = base_angle + PI / 3. * i as f32;
                let x = p.0 + angle.cos() * step;
                let y = p.1 + angle.sin() * step;
                (x, y)
            })
        ).collect();
        options.into_iter().for_each(|p| {
            if located.iter().find(|(pp,vv)|
                (pp.0 - p.0).abs() < step / 10. && (pp.1 - p.1).abs() < step / 10.
            ).is_none() {
                located.push((p, v));
            }
        });
        // reduce to not override already known within step/10 distance by x and y
    }

    located.iter().for_each(|(p, value)|{
        render.sm_center_text(&format!("{}", value), p.0, p.1);
    });
}
fn render_simple_plus_page(render: Render<Option<String>>) {
    for y in 1..=15 {
        render.line(0., y as f32, 12., y as f32);
        // render.line(0., y as f32 - 0.5, 12., y as f32 - 0.5);
    }

    for x in 1..=11 {
        render.line(x as f32, 0., x as f32, 15.);
        // render.line(x as f32 - 0.5, 0., x as f32 - 0.5, 14.);
    }
    // let x = 12;
    // render.line(x as f32 - 0.5, 0., x as f32 - 0.5, 14.);
}
fn render_24(render: Render<Option<String>>) {
    render.line(2., 1., 2., 15.);
    render.line(12. - 2., 1., 12. - 2., 15.);

    render.line(0., 1., 12., 1.);
    render.line(0., 15., 12., 15.);
    render.line(0., 13., 12., 13.);

    for y in vec![3, 5, 7, 9, 11] {
        render.line(0., y as f32, 2., y as f32);
        render.line(12. - 0., y as f32, 12. - 2., y as f32);
    }

    for x in vec![4, 6, 8] {
        render.line(x as f32, 13., x as f32, 15.);
    }

    let shift = -0.5;
    for x in vec![2, 4, 6, 8, 10] {
        render.line(x as f32, 0., shift + x as f32, 0.5);
        render.line(shift + x as f32, 0.5, x as f32, 1.);
    }

    let dx = -0.25;
    render.center_text("5", 1., 0.5 - 0.125);
    render.center_text("4", dx + 2. + 1., 0.5 - 0.125);
    render.center_text("3", dx + 4. + 1., 0.5 - 0.125);
    render.center_text("2", dx + 6. + 1., 0.5 - 0.125);
    render.center_text("1", dx + 8. + 1., 0.5 - 0.125);
    render.center_text("24", 10. + 1., 0.5 - 0.125);

    let mut cells: Vec<(f32, f32, String)> = vec![];
    cells.push((0., 1., "6".into()));
    cells.push((0., 3., "7".into()));
    cells.push((0., 5., "8".into()));
    cells.push((0., 7., "9".into()));
    cells.push((0., 9., "10".into()));
    cells.push((0., 11., "11".into()));
    cells.push((0., 13., "12".into()));

    cells.push((2., 13., "13".into()));
    cells.push((4., 13., "14".into()));
    cells.push((6., 13., "15".into()));
    cells.push((8., 13., "16".into()));
    cells.push((10., 13., "17".into()));

    cells.push((10., 11., "18".into()));
    cells.push((10., 9., "19".into()));
    cells.push((10., 7., "20".into()));
    cells.push((10., 5., "21".into()));
    cells.push((10., 3., "22".into()));
    cells.push((10., 1., "23".into()));

    for (x, y, text) in cells {
        render.center_text(&text, x + 1., y + 1. - 0.125);
    }
}
