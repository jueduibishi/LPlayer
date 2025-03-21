//
//  ViewController.swift
//  LPlayerDemo
//
//  Created by 杨益凡 on 2025/3/21.
//

import UIKit

class ViewController: UIViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.title = "播放器Demo"
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("测试")
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        addPlayerNotify(NSNotification.Name(Notification_PlayerStatusChange).rawValue,#selector(statusChange(_:)),self,nil)
        
        Test.playVideo(self)
    }
    
    /// 通过通知来处理UI
    /// - Parameter noti: noti
    @objc func statusChange(_ noti:Notification){
        print("当前状态:"+LPlayerManager.instance.status.description)
    }


}

