use crate::Detector;
use std::ffi::CStr;
use std::os::raw::c_char;
use std::path::PathBuf;
use std::slice;

#[repr(C)]
pub struct CDetector {
    detector: Detector,
}

#[repr(C)]
pub struct DetResult {
    objects: *const f32,
    objects_len: i32,
}

#[no_mangle]
pub unsafe extern "C" fn c_new(
    model_path: *const c_char,
    input_sizes: *const i32, // [B, C, H, W]
    input_sizes_len: i32,
    classes: *const *const c_char, // null-terminated array of strings
    classes_len: i32,
) -> *mut CDetector {
    let model_path = match CStr::from_ptr(model_path).to_str() {
        Ok(s) => s,
        Err(err) => {
            eprintln!("Error: {:?}", err);
            return std::ptr::null_mut();
        }
    };
    let model_path = PathBuf::from(model_path);
    let input_sizes =
        slice::from_raw_parts(input_sizes, input_sizes_len as usize);
    let input_sizes = input_sizes.iter().map(|&x| x as usize).collect();
    let classes = slice::from_raw_parts(classes, classes_len as usize);
    let classes = classes
        .iter()
        .map(|&x| CStr::from_ptr(x).to_str().unwrap().to_string())
        .collect();
    let detector = Detector::new(&model_path, input_sizes, classes);
    Box::into_raw(Box::new(CDetector { detector }))
}

#[no_mangle]
pub unsafe extern "C" fn c_load(detector: *mut CDetector) -> i32 {
    let detector = &mut *detector;
    match detector.detector.load() {
        Ok(_) => 0,
        Err(_) => 1,
    }
}

#[no_mangle]
pub unsafe extern "C" fn c_reset(detector: *mut CDetector) {
    let detector = &mut *detector;
    detector.detector.reset();
}

#[no_mangle]
pub unsafe extern "C" fn c_detect(
    detector: *mut CDetector,
    image: *const f32,
    image_len: i32,
) -> DetResult {
    let detector = &mut *detector;
    let image = slice::from_raw_parts(image, image_len as usize);
    let preds = detector.detector.detect(image);
    let preds_len = preds.len() as i32;
    let preds = preds
        .into_iter()
        .flat_map(|(_label, _score, x, y, w, h)| vec![x, y, w, h])
        .collect::<Vec<_>>();
    let preds_ptr = preds.as_ptr();
    std::mem::forget(preds);
    DetResult {
        objects: preds_ptr,
        objects_len: preds_len,
    }
}

#[no_mangle]
pub unsafe extern "C" fn c_drop_det_result(det_result: DetResult) {
    let _ = Vec::from_raw_parts(
        det_result.objects as *mut f32,
        det_result.objects_len as usize,
        det_result.objects_len as usize,
    );
}
