const INCH_TO_MM: f32 = 25.4;

#[derive(Clone)]
pub struct Setup {
    pub width: f32,
    pub height: f32,
    pub ppi: f32,
}

impl Setup {
    pub fn rm_pro() -> Setup {
        Setup {
            width: 1_620.,
            height: 2_160.,
            ppi: 229.0,
        }
    }

    pub fn mm(&self, value: f32) -> f32 {
        value / self.ppi * INCH_TO_MM
    }
}
