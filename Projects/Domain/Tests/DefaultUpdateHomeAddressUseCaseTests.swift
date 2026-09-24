@testable import Domain
import Synchronization
import Testing

private final class AddressRecorder: Sendable {
    private let events = Mutex<[String]>([])
    func record(_ event: String) { events.withLock { $0.append(event) } }
    var log: [String] { events.withLock { $0 } }
}

private struct StubPlaceRepository: PlaceRepository {
    let recorder: AddressRecorder
    let inRegion: Bool

    func searchPlaces(keyword: String, near coordinate: Coordinate?) async throws -> [Place] { [] }
    func reverseGeocode(_ coordinate: Coordinate) async throws -> Place { throw StubFailure() }
    func isServiceRegion(_ coordinate: Coordinate) async throws -> Bool {
        recorder.record("region")
        return inRegion
    }
}

private struct StubUserRepository: UserRepository {
    let recorder: AddressRecorder

    func fetchMe() async throws -> UserProfile {
        UserProfile(userID: nil, providerID: nil, nickname: nil, address: nil, coordinate: nil, appVersion: nil)
    }
    func updateHomeAddress(address: String?, coordinate: Coordinate?) async throws {
        recorder.record("patch(\(address ?? "nil"))")
    }
    func updateAlertFrequencies(_ frequencies: [Int]) async throws {}
    func withdraw(reason: String?) async throws {}
}

private struct StubFailure: Error {}

struct DefaultUpdateHomeAddressUseCaseTests {
    private let recorder = AddressRecorder()
    private let seoul = Coordinate(latitude: 37.5665, longitude: 126.9780)

    @Test
    func execute_inServiceRegion_checksThenPatches() async throws {
        let sut = DefaultUpdateHomeAddressUseCase(
            userRepository: StubUserRepository(recorder: recorder),
            placeRepository: StubPlaceRepository(recorder: recorder, inRegion: true)
        )

        try await sut.execute(address: "서울 중구", coordinate: seoul)

        #expect(recorder.log == ["region", "patch(서울 중구)"])
    }

    /// 지역 밖이면 PATCH를 보내지 않는다 — 서버에 쓸 수 없는 집이 저장되면 안 된다.
    @Test
    func execute_outOfServiceRegion_throwsWithoutPatch() async {
        let sut = DefaultUpdateHomeAddressUseCase(
            userRepository: StubUserRepository(recorder: recorder),
            placeRepository: StubPlaceRepository(recorder: recorder, inRegion: false)
        )

        await #expect(throws: UpdateHomeAddressError.outOfServiceRegion) {
            try await sut.execute(address: "부산 해운대구", coordinate: seoul)
        }
        #expect(recorder.log == ["region"])
    }
}
