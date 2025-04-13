use crate::*;

pub struct PDF<T: Clone> {
    pub setup: Setup,
    pub pages: Vec<Page<T>>, // root page is already there after init
    pub doc: PdfDocumentReference,
    pub grid: Grid,
}

impl<T: Clone> PDF<T> {
    pub fn add_page(&mut self, data: T) -> Page<T> {
        let width = Mm(self.setup.mm(self.setup.width));
        let height = Mm(self.setup.mm(self.setup.height));
        let (page, layer) = self.doc.add_page(width, height, "");
        let one = Page {
            page: page,
            layer: layer,
            data: data,
        };
        self.pages.push(one.clone());
        one
    }
    pub fn page(&self, index: usize) -> Page<T> {
        self.pages.get(index).unwrap().clone()
    }
    pub fn new(title: &str, setup: Setup, root_data: T) -> PDF<T> {
        let width = Mm(setup.mm(setup.width));
        let height = Mm(setup.mm(setup.height));
        let (doc, page, layer) = PdfDocument::new(title, width, height, "");
        let root = Page {
            page: page,
            layer: layer,
            data: root_data,
        };
        let grid = Grid::new(12., 16.);
        PDF {
            setup: setup,
            pages: vec![root],
            doc: doc,
            grid: grid,
        }
    }

    pub fn mm(&self, value: f32) -> Mm {
        Mm(self.setup.mm(value))
    }

    pub fn xx(&self, value: f32) -> Mm {
        self.mm(self.x(value))
    }

    pub fn yy(&self, value: f32) -> Mm {
        self.mm(self.y(value))
    }

    pub fn x(&self, value: f32) -> f32 {
        let cell_w = self.setup.width as f32 / self.grid.w;
        value * cell_w
    }

    pub fn y(&self, value: f32) -> f32 {
        let cell_h = self.setup.height as f32 / self.grid.h;
        value * cell_h
    }
}
