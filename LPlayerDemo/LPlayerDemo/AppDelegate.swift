//
//  AppDelegate.swift
//  LPlayerDemo
//
//  Created by 杨益凡 on 2025/3/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    internal var window: UIWindow?;

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        window=UIWindow.init(frame: UIScreen.main.bounds);
        window?.backgroundColor=UIColor.white;
        window?.makeKeyAndVisible();
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never;
        window?.rootViewController = UINavigationController(rootViewController: ViewController(nibName: nil, bundle: nil));
        
        return true
    }
    
    //MARK: 控制中心配置
    override func becomeFirstResponder() -> Bool {
        return true
    }
    override func remoteControlReceived(with event: UIEvent?) {
        if event?.type == .remoteControl {
            
            switch event?.subtype {
            case .remoteControlPlay:
                LPlayerManager.instance.startPlay()
            case .remoteControlPause:
                LPlayerManager.instance.pausePlay()
            case .remoteControlNextTrack:
                LPlayerManager.instance.playNext()
            case .remoteControlPreviousTrack:
                LPlayerManager.instance.playLast()
                
            default:
                break
            }
        }
    }


}

