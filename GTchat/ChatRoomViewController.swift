import UIKit
import Firebase
import MessageKit
import InputBarAccessoryView

let user = Auth.auth().currentUser!

class ChatRoomViewController: MessagesViewController {
    
    var db: Firestore!
    var messages: [MockMessage] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self //送信者の定義など
        messagesCollectionView.messagesLayoutDelegate = self //吹き出しのサイズの調整など
        messagesCollectionView.messagesDisplayDelegate = self //文字色などの色周りなど
        messageInputBar.delegate = self
        
        db = Firestore.firestore()
        
        getMessage()
    }
    
    func getMessage() {
        db.collection("sample").addSnapshotListener { snapShot, error in
            guard let snapShot = snapShot else {
                return
            }
            snapShot.documentChanges.forEach{diff in
            //更新内容が追加だったときの処理
                    if diff.type == .added {
                            let chatData = diff.document.data()
                            let userInfo = MockUser(senderId: chatData["senderID"] as! String, displayName: chatData["sender"] as! String)
                            let mes = MockMessage(text: chatData["message"] as! String, user: userInfo, messageId: UUID().uuidString, date: Date())
                            self.messages.append(mes)
                            DispatchQueue.main.async {
                                self.messagesCollectionView.reloadData()
                                self.messagesCollectionView.scrollToBottom()
                            }
                    }
            }
            
        }
    }
    
}


extension ChatRoomViewController: MessagesDataSource {
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 5 == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY年MM月dd日"
            let dateString = formatter.string(from: message.sentDate)
            return NSAttributedString(
                string: dateString,
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                             NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            )
        }
        return nil
    }
   
    //送信者(本人)の定義
    func currentSender() -> SenderType {
        return MockUser(senderId: user.uid, displayName: user.displayName!)
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    //相手の名前を表示
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        if name != user.displayName {
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        } else {
            return nil
        }
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY/MM/dd HH:mm"
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
       
}


extension ChatRoomViewController: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        let name = message.sender.displayName
        if name == user.displayName {
            return 0
        } else {
            return 15
        }
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 15
    }
    
}


extension ChatRoomViewController: MessagesDisplayDelegate {
  
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        db.collection("users").document(message.sender.senderId).getDocument { (document, error) in
            if let document = document, document.exists {
                let imgURL = document.data()!["img"]
                let url = URL(string: imgURL as! String)
                DispatchQueue.global().async {
                    do {
                        let imgData = try Data(contentsOf: url!)
                        DispatchQueue.main.async {
                            let img = UIImage(data: imgData)
                            let avatar = Avatar(image: img)
                            avatarView.set(avatar: avatar)
                        }
                    }catch let err {
                        print("Error : \(err.localizedDescription)")
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}

extension ChatRoomViewController: MessageInputBarDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let messageData = [
            "sender" : user.displayName,
            "senderID" : user.uid,
            "message" : text
        ]
        db.collection("sample").document().setData(
            messageData as [String : Any]
            ) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
        inputBar.inputTextView.text = ""
    }
}
