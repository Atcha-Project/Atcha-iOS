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
        var isOtherInputVisible: Bool { selected == .other }
        var canSubmit = false
        var isSubmitting = false
    }

    /// Set by the ViewController; always invoked on the main actor.
    var onStateChange: ((State) -> Void)?
    var onToast: ((String) -> Void)?

    private(set) var state = State() {
        didSet { if state != oldValue { onStateChange?(state) } }
    }

    private var otherText = ""
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
        refreshCanSubmit()
    }

    func otherTextDidChange(_ text: String) {
        otherText = text
        refreshCanSubmit()
    }

    /// 확인 팝업을 통과한 뒤에만 호출된다. 성공하면 앱의 세션 만료 관찰이 로그인으로 보낸다.
    func withdrawConfirmed() {
        guard state.canSubmit, !state.isSubmitting, let reason = reasonText() else { return }
        state.isSubmitting = true
        refreshCanSubmit()
        submitTask = Task { [weak self] in
            guard let useCase = self?.withdrawUseCase else { return }
            do {
                try await useCase.execute(reason: reason)
            } catch {
                // 실패 시 세션이 보존된다(UseCase 계약) — 같은 화면에서 재시도할 수 있다.
                guard !Task.isCancelled else { return }
                self?.state.isSubmitting = false
                self?.refreshCanSubmit()
                self?.onToast?("탈퇴에 실패했어요. 다시 시도해 주세요")
            }
        }
    }

    private func reasonText() -> String? {
        guard let selected = state.selected else { return nil }
        guard selected == .other else { return selected.title }
        let trimmed = otherText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func refreshCanSubmit() {
        state.canSubmit = !state.isSubmitting && reasonText() != nil
    }
}
