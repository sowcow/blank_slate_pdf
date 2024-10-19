#[derive(Clone)]
pub struct Grid {
    pub w: f32,
    pub h: f32,
}

impl Grid {
    pub fn new(w: f32, h: f32) -> Grid {
        Grid { w: w, h: h }
    }
}
