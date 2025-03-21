//
//  PlayerManager.swift
//  LPlayerDemo
//
//  Created by 杨益凡 on 2025/3/21.
//

import Foundation
import AVFoundation
import MediaPlayer

public let APPName=Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "播放器";
//播放状态变更通知
public let Notification_PlayerStatusChange = "Notification_PlayerStatusChange"
///示例addPlayerNotify(NSNotification.Name(Notification_PlayerStatusChange).rawValue,#selector(statusChange(_:)),self,nil)
public var addPlayerNotify:(_ notifyName:String,_ notifyFunc: Selector,_ targets: Any, _ obj:Any?)->()={
    (name:String, oneFunc: Selector,targets: Any,obj:Any?)->()
    in
    NotificationCenter.default.addObserver(targets, selector: oneFunc, name: Notification.Name(name), object: obj)
}
///示例 sendNotify(Notification_netWorkChange,nil,[netWorkKey:newValue])
public var sendPlarNotify:(_ notifyName: String,_ targets: Any? ,_ userInfo: Any?)->()={(name: String, object: Any? , dic: Any?)->() in
    NotificationCenter.default.post(name: Notification.Name(name), object: object ,userInfo: dic as? [AnyHashable : Any]);
}


public enum YFPlayerStatus {
    case YFPlayerStatusNon//default
    case YFPlayerStatusLoadSongInfo
    case YFPlayerStatusReadyToPlay
    case YFPlayerStatusPlay
    case YFPlayerStatusPause
    case YFPlayerStatusBuffering//缓冲
    case YFPlayerStatusBuffered
    case YFPlayerStatusFail
    case YFPlayerStatusEnd
    
    var description: String {
        switch self {
        case .YFPlayerStatusNon:
            return "Non (Default)"
        case .YFPlayerStatusLoadSongInfo:
            return "Loading Song Info"
        case .YFPlayerStatusReadyToPlay:
            return "Ready to Play"
        case .YFPlayerStatusPlay:
            return "Playing"
        case .YFPlayerStatusPause:
            return "Paused"
        case .YFPlayerStatusBuffering:
            return "Buffering"
        case .YFPlayerStatusBuffered:
            return "Buffered"
        case .YFPlayerStatusFail:
            return "Failed"
        case .YFPlayerStatusEnd:
            return "Play End"
        }
    }
}

//播放状态
public typealias playProgressHandel = (_ timeNow:String?,_ timeDuration:String?,_ progress:CGFloat)->()
//缓冲
public typealias bufferProHandel = (_ bufferProgress:CGFloat)->()
@objcMembers
public class PlayerModel:NSObject{
    public var title:String? = nil
    
    /// 封面url
    public var cover:String? = nil
    
    /// 播放地址
    public var url:String? = nil
}
@objcMembers
/// 播放器管理
public class LPlayerManager:NSObject,URLSessionDataDelegate{
    
    /// 播放器
    public var player:AVPlayer? = nil
    
    /// 播放状态
    public var status:YFPlayerStatus = .YFPlayerStatusNon
    
    /// 循环播放
    public var isLoop:Bool = false
    
    /// 自动连播，默认开启
    public var aotoContinuePlay = true
    
    /// 正在播放
    public var isPlaying:Bool = false
    
    ///本地图片封面
    public var defaultCoverImageName:String = "defaultCover.png"
    
    /// 播放进度
    public var progressBlock :playProgressHandel? = nil
    
    /// 缓冲
    public var bufferBlock : bufferProHandel? = nil
    
    //MARK: 私有属性
    
    private var playerItem:AVPlayerItem? = nil
    
    /// 播放列表
    private var playerList:[PlayerModel]? = nil
    
    /// 当前播放文件
    private var curModel:PlayerModel? = nil
    
    
    /// 音量控件
    private var volumeSlider:UISlider? = nil
    
    /// 监控进度
    private var timeObserve:Any? = nil
    
    /// 尝试缓冲，未成功的话只执行一次
    private var bufferFlag:Bool = false
    
    /// 当前播放时间(秒)-用于通知中心
    private var playTime:String = ""
    
    /// 总时长(秒)-用于通知中心
    private var playDuration:String = ""
    
    
    /// 用来异步加载封面
    private var downLoadTask:URLSessionDataTask? = nil
    
    /// 封面
    private var coverImg:UIImage{
        if let curCover = curModel?.cover{
            //外部设置了封面
            if curCover.hasPrefix("http") == true{
                //网络封面
                let path = self.coverSucPath(curModel!)
                if FileManager.default.fileExists(atPath: path){
                    //已下载
                    return UIImage(contentsOfFile: path)!
                }else{
                    self.asynDownload(curModel?.cover)
                }
            }else if curCover.hasPrefix("file") == true{
                return UIImage(contentsOfFile: (curModel?.cover!)!)!
            }else{
                return UIImage(named: curCover)!
            }
        }
        let frameworkBundle = Bundle(for: self.classForCoder)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("cover.bundle")
        if defaultCoverImageName == "defaultCover.png"{
            return UIImage(named: defaultCoverImageName, in: Bundle(url: bundleURL!), compatibleWith: nil)!
        }

        return UIImage(named: defaultCoverImageName)!
    }
    
    /// 图片大小，用来判断是否下载完成
    private var imageSize : Int = 0
    
    /// 接收的图片大小，用来判断是否下载完成
    private var responeImageSize : Int = 0
    
    //MARK: 初始化
    /// 单例模式
    public static let instance=LPlayerManager()
    private override init() {
        super.init()
        for view in MPVolumeView().subviews {
            if view.classForCoder.description() == "MPVolumeSlider"{
                volumeSlider = view as? UISlider
                break
            }
        }
        self.beginReceivingRemoteControl()
    }
    
    /// 数据初始化，停止播放，加载数据
    /// - Parameters:
    ///   - fileModel: curModel
    ///   - list: playerList
    public func setCurFile(_ fileModel:PlayerModel,list:[PlayerModel]){
        curModel = fileModel
        playerList = list
        self.pausePlay()
        self.loadMediaInfo()
    }
    
    //MARK: kvo
    
    /// 添加播放器监视器和通知
    private func addPlayerObserver(){
        
        if player != nil{
            timeObserve = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: DispatchQueue.main, using: { [self] time in
                let current = CMTimeGetSeconds(time)
                //----注意：此处不用player.currentItem.duration,因为时间偶尔会出错--------------
                let total = CMTimeGetSeconds((playerItem?.asset.duration)!)
                playTime = String(format: "%.f", current)
                playDuration = String(format: "%.2f", total)
                if progressBlock != nil{
                    progressBlock!(self.stingTime(current),self.stingTime(total),current/total)
                }
                
                DispatchQueue.main.async {
                    self.configNowPlayingCenter()
                }
                
            })
        }
        if playerItem != nil{
            //说明:
            //playbackBufferEmpty:播放任何视频都会执行，=1时缓存为空;=0时有缓存,但不一定能播放，需要配合playbackLikelyToKeepUp一起使用
            //playbackLikelyToKeepUp:播放本地视频时不执行。=1时可播放，但状态变化不及时，需要配合loadedTimeRanges一起使用.=0时数据不够，即相当于playbackBufferEmpty=1
            
            //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
            playerItem!.addObserver(self, forKeyPath: "status",options: [.old,.new], context: nil)
            //监控缓冲加载情况属性
            playerItem!.addObserver(self, forKeyPath: "loadedTimeRanges",options: [.old,.new], context: nil)
            //缓存为空
            playerItem!.addObserver(self, forKeyPath: "playbackBufferEmpty",options: [.old,.new], context: nil)
            //缓存有数据
            playerItem!.addObserver(self, forKeyPath: "playbackLikelyToKeepUp",options: [.old,.new], context: nil)
            player!.addObserver(self, forKeyPath: "rate",options: [.old,.new], context: nil)
        }
        //播放器完成通知
        addPlayerNotify(NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue,#selector(self.playbackFinished(_:)),self,nil)
        //通话中断通知
        addPlayerNotify(AVAudioSession.interruptionNotification.rawValue,#selector(self.handleInterruption(_:)),self, nil)
        addPlayerNotify(AVAudioSession.routeChangeNotification.rawValue,#selector(self.handleAudioRouteChangeListener(_:)),self, nil)
        
        status = .YFPlayerStatusLoadSongInfo
        sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
    }
    
    /// 移除播放器监视器和通知
    private func removePlayerObserver(){
        if playerItem != nil {
            playerItem?.removeObserver(self, forKeyPath: "status")
            playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
            playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            player?.removeObserver(self, forKeyPath: "rate")
        }
        if timeObserve != nil {
            player?.removeTimeObserver(timeObserve!)
            timeObserve = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /// 通过KVO监控播放器状态
    /// - Parameters:
    ///   - keyPath: 监控属性
    ///   - object: 监视器
    ///   - change: 状态改变
    ///   - context: 上下文
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status"{
            ///这里不能用player?.status，非常奇怪，因为网络错误的时候，它无法获取failed，所以直接取status的值。
            let statusNumber:NSNumber = change?[.newKey] as! NSNumber
            switch statusNumber {
            case 0:
                status = .YFPlayerStatusNon
                sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
            case 1:
                status = .YFPlayerStatusReadyToPlay
                //                print("readyToPlay")
                sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
            case 2:
                status = .YFPlayerStatusFail
                sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
                player?.pause()
            default:
                break
            }
        }
        else if keyPath == "loadedTimeRanges" {
            //缓冲
            let total = CMTimeGetSeconds((playerItem?.asset.duration)!)
            let array = playerItem?.loadedTimeRanges
            //本次缓冲时间范围
            if let timeRange = array?.first?.timeRangeValue{
                let startSeconds = CMTimeGetSeconds(timeRange.start)
                let durationSeconds = CMTimeGetSeconds(timeRange.duration)
                //缓冲总长度
                let totaoBuffer = startSeconds + durationSeconds
                if bufferBlock != nil {
                    bufferBlock!(totaoBuffer/total)
                }
                if isPlaying && (totaoBuffer - (Double(playTime) ?? 0) > 1){
                    status = .YFPlayerStatusBuffered
                    sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
                    if bufferFlag && isPlaying {
                        //缓冲达到可播放,尝试再播放
                        DispatchQueue.global().async { [self] in
                            player?.play()
                        }
                        bufferFlag = false
                    }
                }
            }
            else if keyPath == "playbackBufferEmpty" {
                //暂不使用
            }
            else if keyPath == "playbackLikelyToKeepUp" {
                //本地视频时不执行
                if let newChangeKey = change?[NSKeyValueChangeKey.newKey] as? String{
                    //数据量不够，正在缓冲
                    if Int(newChangeKey) == 0 && bufferFlag == false && isPlaying{
                        status = .YFPlayerStatusBuffering
                        sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
                        player?.pause()
                        bufferFlag = true
                    }
                }
                
            }
        }else if keyPath == "rate" {
            //播放状态，只要没执行player.pause(）,rate一直是1，网络错误时也是1
            isPlaying = player?.rate ?? 0>0
        }
    }
    
    
    /// 秒转时间
    /// - Parameter time: time
    /// - Returns: String
    private func stingTime(_ time:CGFloat)->String{
        let min = Int(time/60.0)
        let sec = Int(time-CGFloat(min)*60.0)
        let minStr = min > 9 ? "\(min)" : "0\(min)"
        let secStr = sec > 9 ? "\(sec)" : "0\(sec)"
        return minStr+":"+secStr
    }
    
    //MARK: play
    /// 开始播放
    public func startPlay() {
        if status == .YFPlayerStatusFail{
            //网络错误的时候 需要重新加载，不然网络恢复时一直无法播放
            self.loadMediaInfo();
        }
        if status == .YFPlayerStatusEnd{
            //播放结束 重播
            self.loadMediaInfo();
        }
        status = .YFPlayerStatusPlay
        player?.play()
        sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
    }
    
    /// 暂停播放
    public func pausePlay() {
        status = .YFPlayerStatusPause
        player?.pause()
        sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
    }
    
    /// 加载
    func loadMediaInfo(){
        var sourceString = curModel?.url
        sourceString = sourceString?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if sourceString != nil {
            var url = URL(string: (sourceString)!)
            if (sourceString?.hasPrefix("file") == true || sourceString?.hasPrefix("/") == true){
                //本地文件
                url = URL(fileURLWithPath: sourceString!)
            }
            if playerItem != nil{
                self.removePlayerObserver()
            }
            let mediaAsset = AVURLAsset(url: url!)
            playerItem = AVPlayerItem(asset: mediaAsset)
            if player == nil {
                player = AVPlayer(playerItem: playerItem)
            }else{
                player?.replaceCurrentItem(with: playerItem)
            }
            player?.automaticallyWaitsToMinimizeStalling = false
            self.addPlayerObserver()
        }
    }
    
    /// 停止播放
    public func endPlay(){
        if player != nil{
            status = .YFPlayerStatusEnd
            player?.pause()
            sendPlarNotify(Notification_PlayerStatusChange,nil,nil)
        }
    }
    
    /// 上一首
    public func playLast(){
        if playerList?.count ?? 0 > 0 {
            var curIndex = 0
            for (i,item) in playerList!.enumerated(){
                if item.url == curModel?.url {
                    curIndex = i
                    break
                }
            }
            var lastIndex = curIndex - 1
            if curIndex == 0 {
                lastIndex = playerList!.count - 1
            }
            curModel = playerList![lastIndex]
            self.pausePlay()
            self.loadMediaInfo()
            self.startPlay()
        }else{
            self.pausePlay()
        }
    }
    
    /// 下一首
    public func playNext(){
        if playerList?.count ?? 0 > 0 {
            var curIndex = 0
            for (i,item) in playerList!.enumerated(){
                if item.url == curModel?.url {
                    curIndex = i
                    break
                }
            }
            var nextIndex = curIndex + 1
            if curIndex == playerList!.count - 1 {
                nextIndex = 0
            }
            curModel = playerList![nextIndex]
            self.pausePlay()
            self.loadMediaInfo()
            self.startPlay()
        }else{
            self.pausePlay()
        }
    }
    
    /// 视频播放器用到player时，退出播放页面时执行，释放时必须执行
    public func releasePlayer(){
        playerItem?.cancelPendingSeeks()
        playerItem?.asset.cancelLoading()
        player = nil
    }
    //MARK:跳到指定位置播放
    /// 跳到指定位置播放
    /// - Parameter progress: 0-1 比如50%
    public func setCurProgress(_ progress:CGFloat){
        if playerItem != nil && player != nil{
            let curTime = CMTimeGetSeconds((playerItem?.asset.duration)!)*progress
            player?.seek(to: CMTimeMake(value: Int64(curTime), timescale: 1), toleranceBefore: CMTime(value: 1, timescale: 1000), toleranceAfter: CMTimeMake(value: 1, timescale: 1000))

        }
    }
    //MARK: 播放结束
    /// 播放结束
    /// - Parameter notifi: Notification
    func playbackFinished(_ notifi:Notification){
        if isLoop {
            self.pausePlay()
            self.loadMediaInfo()
            self.startPlay()
        }else{
            if aotoContinuePlay {
                self.playNext()
            }else{
                self.endPlay()
            }
        }
    }
    //MARK: 控制中心
    
    /// 控制中心开启
    public func beginReceivingRemoteControl(){
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    /// 控制中心关闭
    public func endReceivingRemote(){
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    /// 配置控制中心和锁屏播放信息
    public func configNowPlayingCenter(){
        //        print(playTime+"总时间:"+playDuration)
        var info:[String:Any] = [:]
        info[MPMediaItemPropertyTitle] = curModel?.title
        info[MPMediaItemPropertyArtist] = curModel?.title ?? APPName
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(playTime)
        info[MPNowPlayingInfoPropertyPlaybackRate] = (isPlaying ? 1:0)
        info[MPMediaItemPropertyPlaybackDuration] = Double(playDuration)
        let coverArtWork = MPMediaItemArtwork(boundsSize: CGSizeMake(480, 800)) { [self] size->UIImage in
            return self.coverImg
        }
        info[MPMediaItemPropertyArtwork] = coverArtWork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    //MARK: 通话中断处理
    func handleInterruption(_ notification:NSNotification) {
        let info = notification.userInfo
        if let type = info?[AVAudioSessionInterruptionTypeKey] as? String,let audioType = Int(type){
            if audioType == AVAudioSession.InterruptionType.began.rawValue{
                //播放被中断，则停止播放
                self.pausePlay()
            }else{
                //如果中断结束会附带一个KEY值，表明是否应该恢复音频
                if let optionType = info?[AVAudioSessionInterruptionOptionKey] as? String,let resumeType = Int(optionType){
                    if resumeType == AVAudioSession.InterruptionOptions.shouldResume.rawValue{
                        //应该恢复
                        self.startPlay()
                    }
                }
            }
        }
    }
    //MARK: 耳机蓝牙中断处理
    func handleAudioRouteChangeListener(_ notification:NSNotification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? NSNumber,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue.uintValue)
        else { return }
        
        switch reason {
        case .newDeviceAvailable: // 新设备接入（如耳机插入）
            self.startPlay()
        case .oldDeviceUnavailable: // 设备断开（如耳机拔出）
            self.pausePlay()
        default: break
        }
    }
    //MARK: URLSessionDataDelegate
    
    //接收到的请求处理
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        imageSize = Int(dataTask.countOfBytesExpectedToReceive)
        //        print("图片大小"+"\(imageSize)")
        completionHandler(.allow)
    }
    //接收到的数据处理
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let response = dataTask.response as? HTTPURLResponse{
            
            if response.statusCode == 200{
                //无断点续传,一直走200
                self.save(data)
            }
            responeImageSize += data.count
            //            print(responeImageSize)
            if responeImageSize >= imageSize {
                //已下载，有时候收到的数据会大于图片本身大小，则转移
                let path = self.coverCachePath(curModel!)
                let fileManage = FileManager.default
                if fileManage.fileExists(atPath: path) {
                    let sucPath = self.coverSucPath(curModel!)
                    do{
                        try fileManage.moveItem(atPath: path, toPath: sucPath)
                        //移动后，重置
                        responeImageSize = 0
                    }catch{
                        
                    }
                }
            }
        }
    }
    
    /// 储存收到的数据
    /// - Parameter data: data
    private func save(_ data:Data){
        if curModel != nil{
            if curModel?.cover != nil{
                let path = self.coverCachePath(curModel!)
                let fileHandle = FileHandle(forUpdatingAtPath: path)
                if #available(iOS 13.4, *) {
                    do{
                        try fileHandle?.seekToEnd()
                        fileHandle?.write(data)
                        try fileHandle?.close()
                    }catch{
                        
                    }
                } else {
                    // Fallback on earlier versions
                    
                    fileHandle?.seekToEndOfFile()
                    fileHandle?.write(data)
                    fileHandle?.closeFile()
                }
            }
        }
    }
    //MARK: 下载相关
    /// 封面缓存路径
    /// - Parameter fileModel: model
    /// - Returns: filePath String
    private func coverCachePath(_ fileModel:PlayerModel)->String{
        let maiPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        let fileName = self.imageFullName(fileModel)
        let fileFolder = maiPath + "/cover"
        let filePath = fileFolder + "/\(String(describing: fileName))"
        if !FileManager.default.fileExists(atPath: fileFolder){
            do{
                try FileManager.default.createDirectory(atPath: fileFolder, withIntermediateDirectories: true)
            }catch{
                
            }
        }
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: nil)
        }
        return filePath
    }
    
    
    
    /// 已下载的路径
    /// - Parameter fileModel: model
    /// - Returns: filePath String
    private func coverSucPath(_ fileModel:PlayerModel)->String{
        let maiPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
        let fileName = self.imageFullName(fileModel)
        let fileFolder = maiPath + "/coverSuc"
        let filePath = fileFolder + "/\(String(describing: fileName))"
        if !FileManager.default.fileExists(atPath: fileFolder){
            do{
                try FileManager.default.createDirectory(atPath: fileFolder, withIntermediateDirectories: true)
            }catch{
                
            }
        }
        return filePath
    }
    
    
    /// 异步下载-用于控制中心展示作品封面
    /// - Parameter urlString: url
    func asynDownload(_ urlString:String?){
        if urlString != nil {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 7.0
            //网络请求策略：URL应该加载源端数据，不使用本地缓存数据
            sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
            let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
            let urlCharString = urlString!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString
            let urlRequest = URLRequest(url: URL(string: urlCharString!)!)
            URLCache.shared.removeCachedResponse(for: urlRequest)
            downLoadTask = session.dataTask(with: urlRequest)
            downLoadTask?.resume()
        }
    }
    
    /// 获取图片完整名称
    /// - Parameter model: model
    /// - Returns: String
    private func imageFullName(_ model:PlayerModel)->String{
        let coverUrl = NSURL(string: model.cover!)
        let name = coverUrl?.lastPathComponent
        
        if let firstComponent = NSURL(string: model.url!)?.lastPathComponent?.split(separator: ".").first {
            //防止图片名称重复，使用文件名（无后缀）+ 图片名 = 最终文件名
            return firstComponent+name!
        }
        return name!
    }
    
    
    deinit {
        self.removePlayerObserver()
    }
}

