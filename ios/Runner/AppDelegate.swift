import Flutter
import UIKit
import GoogleMaps
import flutter_local_notifications
import Firebase
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // تكوين Firebase
    FirebaseApp.configure()
    
    // تكوين إعدادات Firebase Auth لحل مشكلة reCAPTCHA
    configureFirebaseAuth()
    
    // تكوين Google Maps
    GMSServices.provideAPIKey("AIzaSyC8YAMGRKrLJxeMR1uLJm49PZ5xjS_BKoc")
    
    // تكوين الإشعارات
    configureNotifications()
    
    // تسجيل الـ plugins
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  /// تكوين إعدادات Firebase Auth
  private func configureFirebaseAuth() {
    // تعطيل التحقق من التطبيق أثناء التطوير لحل مشكلة reCAPTCHA
    if #available(iOS 14.0, *) {
      // استخدام الطريقة الآمنة للوصول لإعدادات Auth
      if let authSettings = Auth.auth().settings {
        authSettings.isAppVerificationDisabledForTesting = true
      }
    }
    
    // تكوين إعدادات إضافية لـ reCAPTCHA
    #if DEBUG
    if #available(iOS 14.0, *) {
      Auth.auth().settings?.isAppVerificationDisabledForTesting = true
    }
    #endif
  }
  
  /// تكوين الإشعارات
  private func configureNotifications() {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
  }
}