use engine::Detector;
use imageproc::image;
use std::fs;
use std::io::{BufRead, BufReader};
use std::path::Path;

fn get_coco_labels(base_path: &Path) -> Vec<String> {
    // Download the ImageNet class labels, matching SqueezeNet's classes.
    let labels_path = base_path.join("examples").join("coco-classes.txt");
    let file = BufReader::new(fs::File::open(labels_path).unwrap());

    file.lines().map(|line| line.unwrap()).collect()
}
fn main() {
    let base_path = Path::new(std::env!("CARGO_MANIFEST_DIR"));
    let model_path = base_path.join("../models/yolox_s_coreml.pte");
    let classes = get_coco_labels(base_path);
    let input_sizes = vec![1, 3, 640, 640];
    let mut detector = Detector::new(&model_path, input_sizes, classes);
    detector.load().unwrap();

    let image_path = base_path.join("examples/dog.jpg");
    let image = image::open(image_path).unwrap().to_rgb8();
    let resized_image = detector.pre_processing(&image);
    let preds = detector.detect(&resized_image);
    for pred in preds {
        println!("{:?}", pred);
    }
}
