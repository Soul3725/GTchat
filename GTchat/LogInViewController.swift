import UIKit
import Firebase

class LogInViewController: UIViewController {
    
    var provider: OAuthProvider?
    var db: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()
        //Viewが読み込まれた後にOAuthProviderを作成
        provider = OAuthProvider(providerID: "twitter.com")
         //Firestoreインスタンス生成
        db = Firestore.firestore()
        //test用UserDefault初期化コード
        //UserDefaults.standard.set(nil, forKey:"twitterAccessToken")
        //過去にログインしたことがある場合自動ログイン
        let twitterAccessToken = UserDefaults.standard.string(forKey: "twitterAccessToken")
        let twitterSecretToken = UserDefaults.standard.string(forKey: "twitterSecretToken")
        if (twitterAccessToken != nil && twitterSecretToken != nil) {
            signInWithTwitter()
        }
    }
    
    @IBAction func pushTwitter(_ sender: Any) {
        signInWithTwitter()
    }
    
    func signInWithTwitter(){
        provider!.getCredentialWith(nil) { credential, error in
          if error != nil {
            //Handleエラー
            self.errorAlert()
            return
          }
            if credential != nil {
                Auth.auth().signIn(with: credential!) { (result, error) in
                if error != nil {
                //ログインエラー
                    self.errorAlert()
                return
                }
                    
                //アクセストークン・シークレットトークンをunwrap
                let credential = result?.credential as? OAuthCredential
                let accessToken = credential?.accessToken
                let secretToken = credential?.secret
                //Twitterアクセストークン・シークレットトークンの値を保存
                UserDefaults.standard.set(accessToken, forKey:"twitterAccessToken")
                UserDefaults.standard.set(secretToken, forKey:"twitterSecretToken")
                
                //ユーザー別のDBを構築
                let user = Auth.auth().currentUser!
                let uID = user.uid
                let userInfo = result?.additionalUserInfo?.profile
                let twtrID = userInfo!["id"]!
                let displayName = userInfo!["name"] as! String
                let screenName = userInfo!["screen_name"] as! String
                self.db.collection("users").document(uID).setData([
                    "ID": twtrID,
                    "displayName": displayName,
                    "screenName": screenName
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                            //HomeViewControllerへtoMainを介して遷移
                            self.performSegue(withIdentifier: "toMain", sender: nil)
                        }
                    }
                }
            }
        }
    }
    
    func errorAlert(){
        //アラートに表示する文字列の設定
        let alert: UIAlertController = UIAlertController(title: "ERROR", message: "ログインに失敗しました。", preferredStyle:  UIAlertController.Style.alert)
        //OKボタンの実装
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            print("OK")
        })
        //OKボタンをアラートに追加
        alert.addAction(defaultAction)
        //アラートを表示
        present(alert, animated: true, completion: nil)
    }
}
