use printpdf::*;

#[derive(Clone)]
pub struct Page<T: Clone> {
    pub page: PdfPageIndex,
    pub layer: PdfLayerIndex,
    pub data: T,
}
