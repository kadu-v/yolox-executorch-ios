use berry_executorch::{module::Module, ExecutorchError, Tensor};
use imageproc::image::{
    imageops::{self, FilterType},
    ImageBuffer, Rgb,
};
use jamtrack_rs::{object::Object, rect::Rect};
use std::{path::PathBuf, vec};

#[derive(Debug)]
pub struct YoloX {
    module: Module,
    input_sizes: Vec<usize>,
}

impl YoloX {
    pub fn new(model_path: &PathBuf, input_sizes: Vec<usize>) -> Self {
        let module = Module::new(&model_path.display().to_string()).unwrap();
        Self {
            module,
            input_sizes,
        }
    }

    pub fn load(&mut self) -> Result<(), ExecutorchError> {
        self.module.load()
    }

    pub fn forward(
        &mut self,
        image: &[f32],
    ) -> Result<Tensor, ExecutorchError> {
        let input_sizes = self
            .input_sizes
            .iter()
            .map(|x| *x as i32)
            .collect::<Vec<_>>();
        self.module.forward(image, &input_sizes)
    }

    pub fn pre_processing(
        &self,
        image: &ImageBuffer<Rgb<u8>, Vec<u8>>,
    ) -> ImageBuffer<Rgb<u8>, Vec<u8>> {
        let (h, w) = (self.input_sizes[2], self.input_sizes[3]);
        let image_buffer = self.padding_image(image);
        let image_buffer = imageops::resize(
            &image_buffer,
            w as u32,
            h as u32,
            FilterType::Nearest,
        );
        image_buffer
    }

    pub fn convert_to_channel_first(&self, image: &[f32]) -> Vec<f32> {
        let (_, channels, height, width) = (
            self.input_sizes[0],
            self.input_sizes[1],
            self.input_sizes[2],
            self.input_sizes[3],
        );
        let mut new_image = vec![0.0; channels * height * width];
        for c in 0..channels {
            for h in 0..height {
                for w in 0..width {
                    let idx = c * height * width + h * width + w;
                    new_image[idx] =
                        image[h * width * channels + w * channels + c];
                }
            }
        }
        new_image
    }

    fn padding_image(
        &self,
        image: &ImageBuffer<Rgb<u8>, Vec<u8>>,
    ) -> ImageBuffer<Rgb<u8>, Vec<u8>> {
        let (width, height) = image.dimensions();
        let target_size = if width > height { width } else { height };
        let mut new_image =
            ImageBuffer::new(target_size as u32, target_size as u32);
        let x_offset = (target_size as u32 - width) / 2;
        let y_offset = (target_size as u32 - height) / 2;
        for j in 0..height {
            for i in 0..width {
                let pixel = image.get_pixel(i, j);
                new_image.put_pixel(i + x_offset, j + y_offset, *pixel);
            }
        }
        new_image
    }

    fn sigmoid(x: f32) -> f32 {
        1.0 / (1.0 + (-x).exp())
    }

    pub fn post_processing(
        &self,
        preds: &Tensor,
    ) -> (/*class_id=*/ Vec<i32>, /*object=*/ Vec<Object>) {
        let preds = &preds.data;
        let mut positions = vec![];
        let mut classes = vec![];
        let mut scores = vec![];
        for i in 0..preds.len() / 85 {
            let offset = i * 85;
            let objectness = preds[offset + 4];
            let objectness = Self::sigmoid(objectness);

            let (class, _) = preds[offset + 5..offset + 85]
                .iter()
                .enumerate()
                .max_by(|a, b| a.1.partial_cmp(&(b.1)).unwrap())
                .unwrap();
            let x1 = preds[offset];
            let y1 = preds[offset + 1];
            let x2 = preds[offset + 2];
            let y2 = preds[offset + 3];
            classes.push(class);
            positions.push((x1, y1, x2, y2));
            scores.push(objectness);
        }
        let locs = self.calc_loc(&positions, &self.input_sizes);

        let mut class_idx = vec![];
        let mut objs = vec![];
        // filter by objectness
        let indices =
            self.multiclass_nms_class_agnostic(&locs, &scores, 0.4, 0.4);
        for (i, score, x1, y1, x2, y2) in indices {
            let obj = Object::new(
                Rect::new(x1, y1, (x2 - x1).abs(), (y2 - y1).abs()),
                0,
                score,
            );
            class_idx.push(classes[i] as i32);
            objs.push(obj);
        }
        (class_idx, objs)
    }

    fn calc_loc(
        &self,
        positions: &Vec<(f32, f32, f32, f32)>,
        input_size: &Vec<usize>,
    ) -> Vec<(f32, f32, f32, f32)> {
        let mut locs = vec![];

        // calc girds
        let (h, w) = (input_size[2], input_size[3]);
        let strides = vec![8, 16, 32];
        let mut h_grids = vec![];
        let mut w_grids = vec![];

        for stride in strides.iter() {
            let mut h_grid = vec![0.0; h / stride];
            let mut w_grid = vec![0.0; w / stride];

            for i in 0..h / stride {
                h_grid[i] = i as f32;
            }
            for i in 0..w / stride {
                w_grid[i] = i as f32;
            }
            h_grids.push(h_grid);
            w_grids.push(w_grid);
        }
        let mut acc = vec![0];
        for stride in strides.iter() {
            acc.push(acc.last().unwrap() + h / stride * w / stride);
        }

        for (i, stride) in strides.iter().enumerate() {
            let h_grid = &h_grids[i];
            let w_grid = &w_grids[i];
            let idx = acc[i];

            for (i, y) in h_grid.iter().enumerate() {
                for (j, x) in w_grid.iter().enumerate() {
                    let p = idx + i * w / stride + j;
                    let (px, py, pw, ph) = positions[p];
                    let (x, y) =
                        ((x + px) * *stride as f32, (y + py) * *stride as f32);
                    let (ww, hh) =
                        (pw.exp() * *stride as f32, ph.exp() * *stride as f32);
                    let loc = (
                        x - ww / 2.0,
                        y - hh / 2.0,
                        x + ww / 2.0,
                        y + hh / 2.0,
                    );
                    locs.push(loc);
                }
            }
        }
        locs
    }

    fn non_max_suppression(
        &self,
        boxes: &Vec<(f32, f32, f32, f32)>,
        scores: &Vec<f32>,
        nms_thr: f32,
    ) -> Vec<usize> {
        let mut indices: Vec<usize> = (0..scores.len()).collect();
        indices.sort_unstable_by(|&a, &b| {
            scores[b].partial_cmp(&scores[a]).unwrap()
        });

        let mut keep = Vec::new();

        while !indices.is_empty() {
            let i = indices[0];
            keep.push(i);

            let mut remaining = Vec::new();

            for &j in &indices[1..] {
                let xx1 = f32::max(boxes[i].0, boxes[j].0);
                let yy1 = f32::max(boxes[i].1, boxes[j].1);
                let xx2 = f32::min(boxes[i].2, boxes[j].2);
                let yy2 = f32::min(boxes[i].3, boxes[j].3);

                let w = f32::max(0.0, xx2 - xx1 + 1.0);
                let h = f32::max(0.0, yy2 - yy1 + 1.0);
                let inter = w * h;

                let area_i = (boxes[i].2 - boxes[i].0 + 1.0)
                    * (boxes[i].3 - boxes[i].1 + 1.0);
                let area_j = (boxes[j].2 - boxes[j].0 + 1.0)
                    * (boxes[j].3 - boxes[j].1 + 1.0);
                let ovr = inter / (area_i + area_j - inter);

                if ovr <= nms_thr {
                    remaining.push(j);
                }
            }

            indices = remaining;
        }

        keep
    }

    fn multiclass_nms_class_agnostic(
        &self,
        boxes: &Vec<(f32, f32, f32, f32)>,
        scores: &Vec<f32>,
        nms_thr: f32,
        score_thr: f32,
    ) -> Vec<(usize, f32, f32, f32, f32, f32)> {
        let valid_indices = scores
            .iter()
            .enumerate()
            .filter(|&(_, &score)| score > score_thr)
            .map(|(i, _)| i)
            .collect::<Vec<_>>();

        if valid_indices.is_empty() {
            return Vec::new();
        }

        let valid_boxes =
            valid_indices.iter().map(|&i| boxes[i]).collect::<Vec<_>>();
        let valid_scores =
            valid_indices.iter().map(|&i| scores[i]).collect::<Vec<_>>();

        let keep =
            self.non_max_suppression(&valid_boxes, &valid_scores, nms_thr);
        let mut final_dets = Vec::new();

        for &k in &keep {
            let idx = valid_indices[k];
            let score = scores[idx];
            final_dets.push((
                idx,
                score,
                boxes[idx].0,
                boxes[idx].1,
                boxes[idx].2,
                boxes[idx].3,
            ));
        }

        final_dets
    }
}
