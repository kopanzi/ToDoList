import SwiftUI
import UIKit

/// Kamerayı açan ve sonucu Callback ile dönen %100 güvenli UIKit köprüsü.
/// Senior Notu: UIImagePickerController'ı SwiftUI'a doğrudan döndürmek (return picker)
/// "already presenting" ve donanım çökmesi hatalarına yol açar.
/// Bu sorunu aşmak için boş bir UIViewController döndürüp, kamerayı onun üzerinden modally (present) açıyoruz.
struct CameraPicker: UIViewControllerRepresentable {
    
    // 🛠️ Binding YOK! İşlemi bitirince bu closure tetiklenir ve resmi üst View'a yollar.
    var onImagePicked: (UIImage) -> Void
    
    // 🛠️ SwiftUI'ın kendi kapatma mekanizması
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        // 1. Siyah ve boş bir zemin oluşturuyoruz. SwiftUI bunu sorunsuz bir şekilde sunar.
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .black
        
        // 2. rootVC ekrana yerleştikten hemen sonra kamerayı onun üzerine açıyoruz.
        // Bu yöntem, SwiftUI'ın karmaşık sunum döngüsünden kamerayı tamamen izole eder!
        DispatchQueue.main.async {
            // Gerçek cihaz kontrolü (Simülatörde çökmeyi önler)
            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                print("🛑 Kamera donanımı bulunamadı veya erişim reddedildi. Cihazınızı veya Info.plist izinlerini kontrol edin.")
                self.dismiss()
                return
            }
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = context.coordinator
            picker.allowsEditing = false
            
            // Kameranın ekranı tam kaplamasını garanti altına alıyoruz
            picker.modalPresentationStyle = .fullScreen
            
            // Kamerayı SwiftUI'ın değil, bizim oluşturduğumuz boş VC'nin sunmasını sağlıyoruz.
            rootVC.present(picker, animated: true)
        }
        
        return rootVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Güncelleme gerekmiyor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator (Delegate İşlemleri)
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // 1. Resmi closure üzerinden güvenle View'a gönder
                parent.onImagePicked(image)
            }
            
            // 2. ÖNCE kamerayı UIKit üzerinden kapatıyoruz, işlemi bitince SwiftUI Cover'ını (parent) kapatıyoruz.
            picker.dismiss(animated: true) {
                self.parent.dismiss()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Kullanıcı vazgeçtiğinde de aynı güvenli kapatma sırasını izliyoruz.
            picker.dismiss(animated: true) {
                self.parent.dismiss()
            }
        }
    }
}
