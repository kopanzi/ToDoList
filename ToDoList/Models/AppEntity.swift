import Foundation

/// Tüm modellerin (Görev, Not vb.) uyması gereken temel protokol.
protocol AppEntity: Identifiable, Codable {
    var id: String { get }
    var createdAt: Date { get }
}
