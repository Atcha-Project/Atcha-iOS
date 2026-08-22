public struct Place: Equatable, Sendable {
    public let name: String
    public let address: String
    public let coordinate: Coordinate

    public init(name: String, address: String, coordinate: Coordinate) {
        self.name = name
        self.address = address
        self.coordinate = coordinate
    }
}
