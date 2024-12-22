//
//  CGSize.swift
//  ET-YOLOX
//
//  Created by kikemori on 2024/12/22.
//

import Foundation

extension CGSize {
    /// Returns `CGAffineTransform` to resize `self` to fit in destination size, keeping aspect ratio
    /// of `self`. `self` image is resized to be inscribe to destination size and located in center of
    /// destination.
    ///
    /// - Parameter toFitIn: destination size to be filled.
    /// - Returns: `CGAffineTransform` to transform `self` image to `dest` image.
    func transformKeepAspect(toFitIn dest: CGSize) -> CGAffineTransform {
        let sourceRatio = self.height / self.width
        let destRatio = dest.height / dest.width

        // Calculates ratio `self` to `dest`.
        var ratio: CGFloat
        var x: CGFloat = 0
        var y: CGFloat = 0
        if sourceRatio > destRatio {
            // Source size is taller than destination. Resized to fit in destination height, and find
            // horizontal starting point to be centered.
            ratio = dest.height / self.height
            x = (dest.width - self.width * ratio) / 2
        } else {
            ratio = dest.width / self.width
            y = (dest.height - self.height * ratio) / 2
        }
        return CGAffineTransform(a: ratio, b: 0, c: 0, d: ratio, tx: x, ty: y)
    }
}
