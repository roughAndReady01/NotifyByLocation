//
//  SANLocationAlarmEngine.swift
//  Madika
//
//  Created by 花形春輝 on 2021/09/25.
//

import UserNotifications
import MapKit

class LocationEngine : NSObject {
    /// シェアインスタンス
    static var instance = LocationEngine()
    /// アプリケーション名
    var appName = "NotifyByLocation"
    /// ロケーションマネージャー
    let locationManager = CLLocationManager()
    /// 更新時メソッド
    var updateFunciton:(CLLocation)->Void = {_ in }
    
    /// 状態管理
    enum Status{
        case start
        case stop
    }
    /// 状態
    var status:Status = .stop
    
    /// 通知の許可
    func requestAuthorization(){
        // 通知の許可
        UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .sound]){
            (granted, _) in
            if granted{
                // 使用中に位置情報の取得を許可
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    /// 場所通知
    /// - Parameters:
    ///   - latitude: 緯度
    ///   - longitude: 軽度
    ///   - radius: 半径
    ///   - identifier: identifier
    ///   - sound: サウンドファイル名
    ///   - message: メッセージ
    func locateNotification(latitude:Double , longitude:Double , radius:Double ,identifier :String
                            , sound:String , message : String){
        print("Notification latitude:\(latitude) , longitude:\(longitude) , radius:\(radius), sound:\(sound) , message:\(message)")
        
        // ロケーション作成
        let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        //　範囲を作成
        let region = CLCircularRegion.init(center: coordinate, radius: radius, identifier: identifier)
        // 範囲の中から外への移動は通知しないが、範囲の外から中へは通知する設定
        region.notifyOnExit = false
        region.notifyOnEntry = true
        // 作成した範囲に入った時に通知をするトリガーを作成
        let trigger = UNLocationNotificationTrigger(region: region, repeats: false)

        //通知する内容を作成
        let content = UNMutableNotificationContent()
        let notificationSound = UNNotificationSoundName(rawValue: sound)
        
        content.title = self.appName
        content.body = message
        content.sound = UNNotificationSound(named: notificationSound)
        content.categoryIdentifier = appName

        // 通知要求
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content,
                                            trigger: trigger)
        
        // 通知追加
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

        /// モニタリング開始
        startUpdatingLocation(region)
    }
    
    /// ロケーション監視開始
    func startUpdatingLocation(_ region:CLCircularRegion? = nil){
        // 既に開始済みの場合、開始しない
        if status == .start { return }
        // ステータス設定
        status = .start
        // Backgroundでの位置情報の更新を許可する
        locationManager.allowsBackgroundLocationUpdates = true
        // 精度-10m以内
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        // 更新頻度(m)
        locationManager.distanceFilter = 10
        // 移動タイプ
        locationManager.activityType = .automotiveNavigation
        // 位置情報の監視開始
        locationManager.startUpdatingLocation()

        if let region = region {
            locationManager.startMonitoring(for: region)
        }
    }

    /// ロケーション監視停止
    func stopUpdatingLocation() {
        // ロケーションの監視停止
        locationManager.stopUpdatingLocation()
        // ステータス変更
        status = .stop
    }
        
    /// リージョンに対する監視停止
    /// - Parameter identifier: 監視対象のidentifier
    func stopRegionMonitoring(_ identifier:String){
        for region in locationManager.monitoredRegions {
            if region.identifier == identifier {
                // モニタリング停止
                locationManager.stopMonitoring(for: region)
                break
            }
        }
        
        // 監視対象がない場合、全体の監視停止
        if locationManager.monitoredRegions.count == 0 {
            // ロケーションの監視停止
            stopUpdatingLocation()
        }
    }
    
    /// 通知一覧の取得
    func getAll() ->[String]{
        // 返却領域
        var identifiers:[String] = []
        
        // ペンディング中通知一覧の取得
        identifiers = getPendingNotifications()
            
        // 通知済通知一覧の取得
        identifiers += getDeliveredNotifications()
        
        return identifiers
    }
    
    /// ペンディング中通知一覧の取得
    func getPendingNotifications() ->[String]{
        // 非同期オブジェクト
        let group = DispatchGroup()
        
        // 返却領域
        var identifiers:[String] = []
        
        group.enter()
        // ペンディング状態の通知
        UNUserNotificationCenter.current().getPendingNotificationRequests (
            completionHandler: { requests in
                for request in requests {
                    identifiers.append(request.identifier)
                }
                group.leave()
            }
        )
        group.wait()
        
        return identifiers
    }
    
    /// 通知済通知一覧の取得
    func getDeliveredNotifications()->[String]{
        // 非同期オブジェクト
        let group = DispatchGroup()
        
        // 返却領域
        var identifiers:[String] = []
        
        group.enter()
        // 通知したが、ユーザーが見ていない通知
        UNUserNotificationCenter.current().getDeliveredNotifications (
            completionHandler: { notifications in
                for notification in notifications {
                    print("DeliveredNotification identifiers:" + notification.request.identifier)
                    identifiers.append(notification.request.identifier)
                }
                group.leave()
            }

        )
        group.wait()
        
        return identifiers
    }
    
    // 通知の削除
    func remove(_ id : String){
        print("remove notification identifier:" + String(id))

        // 通知の取得
        for identifier in getAll(){
            // 文字列の部分一致
            if(identifier.hasPrefix(id)){
                print("remove notification identifier:" + String(identifier))
                
                // ペンディング中の通知の削除
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                // 通知済の通知の削除
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
            }
        }
        
        // ロケーション監視の停止
        stopRegionMonitoring(id)
    }
}
