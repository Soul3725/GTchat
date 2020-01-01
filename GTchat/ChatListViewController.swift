import UIKit
import Firebase
import FirebaseFirestore

class ChatListViewController: UITableViewController {
    
    var tourName : [String] = []
    var latestComment : [String] = []
    var tourImg : [URL] = []
    var db: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()
        //Firestoreインスタンス生成
        db = Firestore.firestore()
        db.collection("tournaments_entry").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let userArray = document.data()["users"] as! Array<String>
                }
            }
        }
    }
    
}
