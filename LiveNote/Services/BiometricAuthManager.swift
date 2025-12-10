
import Foundation
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()

    private init() {}

    /// 생체 인증 또는 기기 암호로 인증
    /// - Parameter completion: 인증 결과 (성공 여부)
    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        // 기기 암호 또는 생체 인증 사용 가능 여부 확인
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = LocalizationManager.shared.string("카테고리를 열기 위해 인증이 필요합니다")

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        print("✅ 인증 성공")
                        completion(true)
                    } else {
                        print("❌ 인증 실패: \(authenticationError?.localizedDescription ?? "알 수 없는 오류")")
                        completion(false)
                    }
                }
            }
        } else {
            // 인증 사용 불가
            print("❌ 인증 사용 불가: \(error?.localizedDescription ?? "알 수 없는 오류")")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}
