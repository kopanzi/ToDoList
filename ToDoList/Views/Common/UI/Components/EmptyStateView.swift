import SwiftUI

/// Liste boş olduğunda kullanıcıyı karşılayan modern bilgilendirme ekranı.
struct EmptyStateView: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear) // List içinde kullanıldığında şeffaf kalması için
    }
}
