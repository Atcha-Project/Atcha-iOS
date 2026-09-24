@testable import SettingsFeature
import Testing

/// `sections`가 순수 함수가 되면서 가능해진 검증 — **ViewModel 인스턴스 없이**
/// 상태 조합만으로 렌더 결과를 확인한다. 이전에는 이 조합들을 보려면 UseCase 스텁을
/// 조립하고 비동기 로딩이 끝나기를 기다려야 했다.
struct SettingsSectionsTests {
    private func sections(
        address: String = "서울 마포구",
        hasUpdate: Bool = false,
        isLoggingOut: Bool = false
    ) -> [SettingsViewModel.Section] {
        SettingsViewModel.sections(
            from: .init(
                addressText: address, hasUpdate: hasUpdate, isLoggingOut: isLoggingOut
            ),
            currentVersion: "1.2.3"
        )
    }

    @Test
    func alwaysHasThreeSections() {
        #expect(sections().count == 3)
    }

    @Test
    func addressText_flowsIntoHomeAddressRow() {
        let rows = sections(address: "집 주소를 등록해 주세요")[0].rows
        #expect(rows == [.homeAddress(subtitle: "집 주소를 등록해 주세요")])
    }

    /// 로딩 실패 문구도 같은 자리에 그대로 실린다 — 별도 상태를 만들지 않는다.
    @Test
    func loadFailureText_usesSameRow() {
        let rows = sections(address: "주소를 불러오지 못했어요")[0].rows
        #expect(rows == [.homeAddress(subtitle: "주소를 불러오지 못했어요")])
    }

    @Test
    func versionRow_carriesUpdateFlag() {
        #expect(sections(hasUpdate: false)[1].rows.contains(
            .version(text: "1.2.3", hasUpdate: false)
        ))
        #expect(sections(hasUpdate: true)[1].rows.contains(
            .version(text: "1.2.3", hasUpdate: true)
        ))
    }

    /// 로그아웃 진행 상태는 행 구성을 바꾸지 않는다 — 중복 탭 방지용 내부 상태일 뿐이다.
    /// 이 사실이 지금은 테스트로 고정돼 있다(이전에는 코드를 읽어야 알 수 있었다).
    @Test
    func loggingOut_doesNotChangeRows() {
        #expect(sections(isLoggingOut: false) == sections(isLoggingOut: true))
    }

    @Test
    func lastSection_hasNoTitleAndHoldsAccountActions() {
        let last = sections()[2]
        #expect(last.title == nil)
        #expect(last.rows == [.logout, .withdraw])
    }
}
