#[derive(Clone)]
pub struct Area {
    pub x1: f32,
    pub y1: f32,
    pub x2: f32,
    pub y2: f32,
}

impl Area {
    pub fn xywh(x1: f32, y1: f32, w: f32, h: f32) -> Area {
        let x2 = x1 + w;
        let y2 = y1 + h;

        let ax: f32;
        let bx: f32;
        let ay: f32;
        let by: f32;

        if x1 < x2 {
            ax = x1;
            bx = x2;
        } else {
            bx = x1;
            ax = x2;
        }

        if y1 < y2 {
            ay = y1;
            by = y2;
        } else {
            by = y1;
            ay = y2;
        }

        Area {
            x1: ax,
            y1: ay,
            x2: bx,
            y2: by,
        }
    }

    pub fn w(&self) -> f32 {
        self.x2 - self.x1
    }

    #[allow(dead_code)]
    pub fn h(&self) -> f32 {
        self.y2 - self.y1
    }
}
