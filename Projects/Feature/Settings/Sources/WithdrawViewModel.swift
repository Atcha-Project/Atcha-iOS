import Domain
import Foundation

// Convention: every ViewModel in the codebase is @MainActor.
@MainActor
final class WithdrawViewModel {
    /// 레거시 WithdrawOption 실측 순서·문구 그대로 — 서버에는 문구 자체가 사유로 저장된다.
    enum Reason: CaseIterable, Equatable {
        case timeMismatch
        case rarelyUse
        case frequentErrors
        case hardToFind
        case hardToUse
        case mapAppEnough
        case other

        var title: String {
            switch self {
            case .timeMismatch: "막차 시간이 안맞아요"
            case .rarelyUse: "막차를 자주 안 타요"
            case .frequentErrors: "잦은 에러를 겪었어요"
            case .hardToFind: "막차를 찾기가 번거로워요"
            case .hardToUse: "앱 사용법을 모르겠어요"
            case .mapAppEnough: "기존에 쓰던 지도 앱으로 충분해요"
            case .other: "기타"
            }
        }
    }

    struct State: Equatable {
        var selected: Reason?
        /// 기타 사유 입력값. State 밖에 두면 "선택은 기타인데 입력이 비어 있다" 같은
        /// 조합이 상태 타입으로 표현되지 않아, 제출 가능 여부를 따로 계산해 저장하게 된다.
        var otherText = ""
        var isSubmitting = false

        var isOtherInputVisible: Bool { selected == .other }

        /// 파생 — 저장하지 않는다. 저장하면 `selected`/`otherText`/`isSubmitting`이
        /// 바뀔 때마다 갱신을 잊지 않아야 하고, 그 자체가 불일치의 원인이 된다.
        var canSubmit: Bool { !isSubmitting && reasonText != nil }

        /// 서버로 보낼 사유. 기타는 공백만 남으면 미선택과 같다.
        var reasonText: String? {
            guard let selected else { return nil }
            guard selected == .other else { return selected.title }
            let trimmed = otherText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
    }

    /// Set by the ViewController; always invoked on the main actor.
    var onStateChange: ((State) -> Void)?
    var onToast: ((String) -> Void)?

    private(set) var state = State() {
        didSet { if state != oldValue { onStateChange?(state) } }
    }

    private let withdrawUseCase: any WithdrawUseCase
    private var submitTask: Task<Void, Never>?

    init(withdrawUseCase: any WithdrawUseCase) {
        self.withdrawUseCase = withdrawUseCase
    }

    deinit {
        submitTask?.cancel()
    }

    func select(_ reason: Reason) {
        state.selected = reason
    }

    func otherTextDidChange(_ text: String) {
        state.otherText = text
    }

    /// 확인 팝업을 통과한 뒤에만 호출된다. 성공하면 앱의 세션 만료 관찰이 로그인으로 보낸다.
    func withdrawConfirmed() {
        guard state.canSubmit, let reason = state.reasonText else { return }
        state.isSubmitting = true
        submitTask = Task { [weak self] in
            guard let useCase = self?.withdrawUseCase else { return }
            do {
                try await useCase.execute(reason: reason)
            } catch {
                // 실패 시 세션이 보존된다(UseCase 계약) — 같은 화면에서 재시도할 수 있다.
                guard !Task.isCancelled else { return }
                self?.state.isSubmitting = false
                self?.onToast?("탈퇴에 실패했어요. 다시 시도해 주세요")
            }
        }
    }

}
