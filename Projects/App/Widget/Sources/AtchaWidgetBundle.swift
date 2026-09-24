import DesignSystem
import SwiftUI
import WidgetKit

@main
struct AtchaWidgetBundle: WidgetBundle {
    // 익스텐션 프로세스 시작 시점에 Pretendard를 미리 등록한다 — WidgetKit이
    // 스냅샷을 요청하기 전에 등록 비용이 끝나도록. once-가드라 멱등이고,
    // Font.pretendard 경로도 내부에서 같은 등록을 지연 수행하므로 이 훅은
    // 타이밍 보증일 뿐 정합성 조건은 아니다.
    init() {
        DSFont.registerFontsIfNeeded()
    }

    var body: some Widget {
        LastTrainLiveActivityWidget()
    }
}
