pub mod c_interface;
mod yolox;

use berry_executorch::{error::ExecutorchError, Tensor};
use imageproc::image::{ImageBuffer, Rgb};
use jamtrack_rs::byte_tracker;
use std::path::PathBuf;

#[derive(Debug)]
pub struct Detector {
    yolox: yolox::YoloX,
    byte_tracker: byte_tracker::ByteTracker,
}

impl Detector {
    pub fn new(
        model_path: &PathBuf,
        input_sizes: Vec<usize>, // [B, C, H, W]
        classes: Vec<String>,
    ) -> Self {
        let yolox = yolox::YoloX::new(model_path, input_sizes.clone(), classes);
        let byte_tracker =
            byte_tracker::ByteTracker::new(30, 30, 0.5, 0.6, 0.8);
        Self {
            yolox,
            byte_tracker,
        }
    }

    pub fn load(&mut self) -> Result<(), ExecutorchError> {
        self.yolox.load()
    }

    pub fn reset(&mut self) {
        self.byte_tracker =
            byte_tracker::ByteTracker::new(30, 30, 0.5, 0.6, 0.8);
    }

    pub fn detect(
        &mut self,
        image: &[f32],
    ) -> Vec<(String, f32, f32, f32, f32, f32)> {
        let tensor = self.yolox.forward(image).unwrap();
        let preds = self.yolox.post_processing(&tensor);
        return preds;
    }

    pub fn pre_processing(
        &self,
        image: &ImageBuffer<Rgb<u8>, Vec<u8>>,
    ) -> Vec<f32> {
        self.yolox.pre_processing(image)
    }
}
