#![allow(warnings)]

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
