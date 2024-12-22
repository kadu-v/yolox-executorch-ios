pub mod c_interface;
mod yolox;

use berry_executorch::error::ExecutorchError;
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
    ) -> Self {
        let yolox = yolox::YoloX::new(model_path, input_sizes.clone());
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
    ) -> (Vec<(i32, f32, f32, f32, f32, f32)>, f32, f32, f32) {
        let start_time = std::time::Instant::now();
        let converted_image = self.yolox.convert_to_channel_first(image);
        let pre_processing_time = start_time.elapsed().as_millis() as f32;

        let start_time = std::time::Instant::now();
        match self.yolox.forward(&converted_image) {
            Ok(tensor) => {
                let forward_time = start_time.elapsed().as_millis() as f32;

                let start_time = std::time::Instant::now();
                let preds = self.yolox.post_processing(&tensor);
                let post_processing_time =
                    start_time.elapsed().as_millis() as f32;
                return (
                    preds,
                    pre_processing_time,
                    forward_time,
                    post_processing_time,
                );
            }
            Err(err) => {
                eprintln!("Error: {:?}", err);
                return (vec![], 0.0, 0.0, 0.0);
            }
        };
    }

    pub fn pre_processing(
        &self,
        image: &ImageBuffer<Rgb<u8>, Vec<u8>>,
    ) -> Vec<f32> {
        let buffer = self.yolox.pre_processing(image);
        buffer
            .to_vec()
            .into_iter()
            .map(|x| x as f32)
            .collect::<Vec<f32>>()
    }

    pub fn convert_to_channel_first(&self, image: &[f32]) -> Vec<f32> {
        self.yolox.convert_to_channel_first(image)
    }
}
