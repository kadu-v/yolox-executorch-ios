#pragma once
#include <stdint.h>

#if __cplusplus
extern "C"
{
#endif
    typedef struct CDetector CDetector;
    typedef struct DetResult
    {
        float *objects;
        int32_t objects_len;
    } DetResult;

    CDetector *c_new(
        const char *model_path,
        const int32_t input_sizes,
        const int32_t input_sizes_len,
        const char **classes,
        const int32_t classes_len);

    // void c_drop(CDetector *detector);

    int32_t c_load(CDetector *detector);

    void c_reset(CDetector *detector);

    DetResult c_detect(CDetector *detector, const float *image, const int32_t image_len);

    void c_drop_det_result(DetResult result);
#if __cplusplus
}
#endif