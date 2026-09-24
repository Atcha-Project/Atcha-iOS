@testable import SettingsFeature
import Testing

@MainActor
struct WithdrawViewModelTests {
    @Test
    func noSelection_cannotSubmit() {
        let sut = WithdrawViewModel(withdrawUseCase: SpyWithdrawUseCase())
        #expect(sut.state.canSubmit == false)
    }

    @Test
    func presetReason_sendsTitleAsReason() async {
        let useCase = SpyWithdrawUseCase()
        let sut = WithdrawViewModel(withdrawUseCase: useCase)

        sut.select(.rarelyUse)
        sut.withdrawConfirmed()
        await waitUntil { useCase.reasons.count == 1 }

        #expect(useCase.reasons == ["막차를 자주 안 타요"])
    }

    /// 기타는 공백만 입력하면 제출할 수 없다(레거시 규칙).
    @Test
    func otherReason_requiresNonBlankText() async {
        let useCase = SpyWithdrawUseCase()
        let sut = WithdrawViewModel(withdrawUseCase: useCase)

        sut.select(.other)
        sut.otherTextDidChange("   ")
        #expect(sut.state.canSubmit == false)

        sut.otherTextDidChange("  알림이 늦어요 ")
        #expect(sut.state.canSubmit)
        sut.withdrawConfirmed()
        await waitUntil { useCase.reasons.count == 1 }

        #expect(useCase.reasons == ["알림이 늦어요"])
    }

    @Test
    func failure_toastsAndAllowsRetry() async {
        let useCase = SpyWithdrawUseCase()
        useCase.fails = true
        let sut = WithdrawViewModel(withdrawUseCase: useCase)
        var toasts: [String] = []
        sut.onToast = { toasts.append($0) }

        sut.select(.timeMismatch)
        sut.withdrawConfirmed()
        await waitUntil { !toasts.isEmpty }

        #expect(toasts == ["탈퇴에 실패했어요. 다시 시도해 주세요"])
        #expect(sut.state.canSubmit)
        #expect(sut.state.isSubmitting == false)
    }
}
