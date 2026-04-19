import SwiftUI

/// Görünümlere seçili yoğunluğu otomatik uygulayan modifier.
struct LayoutDensityModifier: ViewModifier {
    @EnvironmentObject var appearance: AppearanceManager
    var edges: Edge.Set
    
    func body(content: Content) -> some View {
        content
            .padding(edges, 16 * appearance.layoutDensity.paddingMultiplier)
            // İsteğe bağlı: Font büyüklüğünü de buradan global etkileyebiliriz
    }
}

extension View {
    /// Kartlara veya listelere Senior seviyesinde yoğunluk ayarı uygular.
    func applyDensity(edges: Edge.Set = .all) -> some View {
        self.modifier(LayoutDensityModifier(edges: edges))
    }
}
