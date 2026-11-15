import Flutter
import UIKit
import AutomaticAssessmentConfiguration

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var assessment: AnyObject?
  override func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  override func application(_ application: UIApplication,
    shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
    // Custom exam keyboard is rendered by Flutter; never load a third-party IME.
    if #available(iOS 13.4, *), extensionPointIdentifier == .keyboard,
       let controller = assessment as? MarkazAssessment, controller.isRestricted { return false }
    return true
  }
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MarkazExam") {
      let channel = FlutterMethodChannel(name: "markaz/exam", binaryMessenger: registrar.messenger())
      if #available(iOS 13.4, *) {
        let controller = MarkazAssessment(channel: channel)
        assessment = controller
        channel.setMethodCallHandler { [weak controller] call, reply in
          controller?.handle(call, reply: reply)
        }
      } else {
        channel.setMethodCallHandler { _, reply in
          reply(FlutterError(code: "unsupported", message: "Ujian memerlukan iOS 13.4 atau lebih baru.", details: nil))
        }
      }
    }
  }
}

@available(iOS 13.4, *)
final class MarkazAssessment: NSObject, AEAssessmentSessionDelegate {
  private let channel: FlutterMethodChannel
  private var session: AEAssessmentSession?
  private var beginReply: FlutterResult?
  private var ending = false
  private var endReply: FlutterResult?
  var isRestricted: Bool { session != nil || beginReply != nil }
  init(channel: FlutterMethodChannel) { self.channel = channel; super.init() }
  func handle(_ call: FlutterMethodCall, reply: @escaping FlutterResult) {
    switch call.method {
    case "active": reply(session?.isActive == true)
    case "begin":
      if session?.isActive == true { reply(true); return }
      guard beginReply == nil && endReply == nil && !ending else {
        reply(FlutterError(code: "busy", message: "Mode ujian sedang disiapkan.", details: nil)); return
      }
      beginReply = reply
      let next = AEAssessmentSession(configuration: AEAssessmentConfiguration())
      session = next; next.delegate = self; next.begin()
    case "end":
      guard let current = session else { reply(nil); return }
      guard endReply == nil else { reply(FlutterError(code: "busy", message: "Sedang menutup mode ujian.", details: nil)); return }
      endReply = reply
      if !ending { ending = true; current.end() }
    default: reply(FlutterMethodNotImplemented)
    }
  }
  func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
    UIApplication.shared.isIdleTimerDisabled = true
    let reply = beginReply; beginReply = nil; reply?(true)
  }
  func assessmentSession(_ session: AEAssessmentSession, failedToBeginWithError error: Error) {
    let reply = beginReply; beginReply = nil; self.session = nil
    reply?(FlutterError(code: "assessment_denied", message: "Assessment Mode gagal. Periksa entitlement Apple dan konfigurasi perangkat. \(error.localizedDescription)", details: nil))
  }
  func assessmentSession(_ session: AEAssessmentSession, wasInterruptedWithError error: Error) {
    channel.invokeMethod("interrupted", arguments: nil)
    if !ending { ending = true; session.end() }
  }
  func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
    UIApplication.shared.isIdleTimerDisabled = false
    self.session = nil; ending = false
    let reply = endReply; endReply = nil; reply?(nil)
    let start = beginReply; beginReply = nil
    start?(FlutterError(code: "interrupted", message: "Persiapan ujian terhenti.", details: nil))
  }
}
