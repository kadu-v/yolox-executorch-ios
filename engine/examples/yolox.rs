use engine::Detector;
use imageproc::image;
use std::fs;
use std::io::{BufRead, BufReader};
use std::path::PathBuf;

fn get_coco_labels(base_path: &PathBuf) -> Vec<String> {
    // Download the ImageNet class labels, matching SqueezeNet's classes.
    let labels_path = base_path.join("models").join("coco-classes.txt");
    let file = BufReader::new(fs::File::open(labels_path).unwrap());

    file.lines().map(|line| line.unwrap()).collect()
}
fn main() {
    let base_path = dinghy_test::test_project_path();
    let model_path = base_path.join("models/yolox_tiny_coreml.pte");
    let classes = get_coco_labels(&base_path);
    let input_sizes = vec![1, 3, 416, 416];
    let mut detector = Detector::new(&model_path, input_sizes);
    detector.load().unwrap();

    let image_path = base_path.join("examples/dog.jpg");
    let image = image::open(image_path).unwrap().to_rgb8();
    let resized_image = detector.pre_processing(&image);
    let (cls_idx, objs, _, _, _) = detector.detect(&resized_image, false, 0);
    for (i, obj) in objs.iter().enumerate() {
        let cls = &classes[cls_idx[i]];
        println!(
            "{}: (x = {}, y = {}, w = {}, h = {}), prob = {:.3}",
            cls,
            obj.get_x(),
            obj.get_y(),
            obj.get_width(),
            obj.get_height(),
            obj.get_prob()
        );
    }
}
