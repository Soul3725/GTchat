import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    let user = Auth.auth().currentUser

    override func viewDidLoad() {
        super.viewDidLoad()
        changeImageSize()
        greeting.text = "ようこそ、" + (user?.displayName)! + "さん"
    }
    
    @IBOutlet weak var greeting: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    
    func changeImageSize(){
        if let user = user {
            //photoURLを書き換えてオリジナルサイズのURLに変更
            var photoURL = user.photoURL!.absoluteString
            print(photoURL)
            if let range = photoURL.range(of: "_normal") {
                photoURL.replaceSubrange(range, with: "")
                //URLから画像を非同期で表示
                let url = URL(string: photoURL)
                DispatchQueue.global().async {
                    do {
                        let imgData = try Data(contentsOf: url!)
                        DispatchQueue.main.async {
                            self.userImage.image = UIImage(data: imgData)
                        }
                    }catch let err {
                        print("Error : \(err.localizedDescription)")
                    }
                }
            }
        }
    }
    
}
