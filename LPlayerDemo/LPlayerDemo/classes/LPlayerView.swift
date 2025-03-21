//
//  LPlayerView.swift
//  LPlayerDemo
//
//  Created by 杨益凡 on 2025/3/21.
//
import UIKit
import Foundation
import AVFoundation

@objcMembers
/// 播放层处理成View，否则layer无法自适应
class LPlayerView: UIView {
    
    private var _player:AVPlayer
    
    override init(frame: CGRect) {
        _player = AVPlayer()
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass{
        LCustomLayer.self
    }
    var player :AVPlayer{
        get{
            return _player
        }
        set{
            let playerLayer = self.layer as! LCustomLayer
            playerLayer.videoGravity = .resizeAspect
            playerLayer.player = newValue
            _player = playerLayer.player!
        }
    }
}
class LCustomLayer: AVPlayerLayer {
    
}

