//
//  Test.swift
//  LPlayerDemo
//
//  Created by 杨益凡 on 2025/3/21.
//

import Foundation
import UIKit

class Test: NSObject{
    static func playVideo(_ vc:UIViewController){
        let playerView = LPlayerView()
        playerView.frame = CGRectMake(0, 100, 192*2, 108*2)
        vc.view.addSubview(playerView)
        //不设置封面，则用默认
        let model = PlayerModel()
        model.url = "https://v.3839video.com/video/sjyx/app_gonglue/web/202212/167058186063930e64e46d0.mp4"
        model.cover = nil
        let model1 = PlayerModel()
        model1.url = Bundle.main.path(forResource: "001", ofType: "mp4", inDirectory: "video")
        model1.cover = "封面"
        
        let model2 = PlayerModel()
        model2.url = "https://v.3839video.com/video/sjyx/app_gonglue/web/202106/162435388760d1ac5fefd9e.mp4"
        model2.cover = "https://img.71acg.net/kbyx/gicon/148079/20240309-00.png"
        let model3 = PlayerModel()
        model3.url = "https://v.3839video.com/video/sjyx/app_gonglue/web/202405/17161245066649fb5abf953.mp4"
        model3.cover = "https://img.71acg.net/kbyx~sykb/20211029/11565666306"
        let model4 = PlayerModel()
        model4.url = "https://v.3839video.com/video/sjyx/app_gonglue/web/202101/16111379066008037287eb2.mp4"
        model4.cover = Bundle.main.path(forResource: "shws1024", ofType: "png", inDirectory: "video")
        //不设置封面，则用默认
        let manager = LPlayerManager.instance
//        manager.isLoop = true
//        manager.aotoContinuePlay = false;
        manager.setCurFile(model1, list: [model,model1,model2,model3,model4])
        manager.progressBlock = { timeNow,timeDuration,progress in
            print((timeNow ?? "00:00")+"/"+(timeDuration ?? "00:00"))
        }
        manager.bufferBlock = { bufferProgress in
            print("缓冲"+String(format: "%.1f",bufferProgress))
        }
        playerView.player = manager.player!
        manager.startPlay()
    }
}
