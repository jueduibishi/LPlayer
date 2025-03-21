//
//  LSlider.swift
//  LPlayerDemo
//
//  Created by 杨益凡 on 2025/3/21.
//
import UIKit
import Foundation

/// 播放器进度条，高度处理一下，默认的太细了。
public class LSlider: UISlider {
    
    private let height = 10.0
    /// 控制slider的宽和高，这个方法才是真正的改变slider滑道的高的
    /// - Parameter bounds: CGRect
    /// - Returns: CGRect
    public override func trackRect(forBounds bounds:CGRect) -> CGRect {
        CGRectMake(0, 0, bounds.size.width, height)
    }
    
    public override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        var r:CGRect = rect
        r.origin.x = rect.origin.x - 12;
        r.size.width = rect.size.width + 10;
        return CGRectInset(super.thumbRect(forBounds: bounds, trackRect: r, value: value), height/2, height/2)
    }
}
