import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    let user = Auth.auth().currentUser
    var db: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        changeImageSize()
        greeting.text = "ようこそ、" + (user?.displayName)! + "さん"
    }
    
    @IBOutlet weak var greeting: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    
    func changeImageSize(){
        if let user = user {
            //photoURLを書き換えてオリジナルサイズのURLに変更
            var photoURL = user.photoURL!.absoluteString
            if let range = photoURL.range(of: "_normal") {
                photoURL.replaceSubrange(range, with: "")
                //URLから画像を非同期で表示
                let url = URL(string: photoURL)
                let uID = user.uid
                db.collection("users").document(uID).updateData([
                    "img": photoURL
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
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
