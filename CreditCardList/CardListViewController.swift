//
//  CardListViewController.swift
//  CreditCardList
//
//  Created by JUNO on 2022/05/07.
//

import UIKit
import Kingfisher
import FirebaseDatabase

// 별도로 delegate, datasource를 별도로 연결하지 않아도 됨
class CardListViewController: UITableViewController {
    var ref: DatabaseReference! // Firebase Realtime Database
    
    var creditCardList: [CreditCard] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UITableView Cell Register
        let nibName = UINib(nibName: "CardListCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "CardListCell")
        
        ref = Database.database().reference()
        
        self.ref.observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: [String: Any]] else { return }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value)
                let cardData = try JSONDecoder().decode([String: CreditCard].self, from: jsonData)
                let cardList = Array(cardData.values)
                self.creditCardList = cardList.sorted { $0.rank < $1.rank }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch let error {
                print("Error json parsing \(error)")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creditCardList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CardListCell"
                                                       , for: indexPath) as? CardListCell else { return UITableViewCell() }
        
        cell.rankLabel.text = "\(creditCardList[indexPath.row].rank)위"
        cell.promotionLabel.text = "\(creditCardList[indexPath.row].promotionDetail.amount)만원 증정"
        cell.cardNameLabel.text = "\(creditCardList[indexPath.row].name)"
        
        let imageURL = URL(string: creditCardList[indexPath.row].cardImageURL)
        
        cell.cardImageView.kf.setImage(with: imageURL)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 상세화면 전달
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let detailViewController = storyboard.instantiateViewController(withIdentifier: "CardDetailViewController") as? CardDetailViewController else { return }
        
        detailViewController.promotionDetail = creditCardList[indexPath.row].promotionDetail
        self.show(detailViewController, sender: nil)
        
        //Option 1 : 조회 정보를 정확히 알 때.
        //불특정한 ID로 생성될 때, 조회하기 애매한 방법
        let cardId = creditCardList[indexPath.row].id
        //ref.child("Item\(cardId)/isSelected").setValue(true)
        
        //Option 2 : 조회 정보를 정확하게 모를때
        ref.queryOrdered(byChild: "id").queryEqual(toValue: cardId).observe(.value) {
            [weak self] snapshot in
            guard let self = self,
                  let value = snapshot.value as? [String: [String: Any]],
                  let key = value.keys.first else { return }
            
            self.ref.child("\(key)/isSelected").setValue(true)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let cardId = creditCardList[indexPath.row].id
            
            //Option1 - 경로를 알 때
            //ref.child("Item\(cardId)").removeValue();
            
            //Option2 - 경로를 모를 때
            ref.queryOrdered(byChild: "id").queryEqual(toValue: cardId).observe(.value) {
                [weak self] snapshot in
                guard let self = self,
                      let value = snapshot.value as? [String: [String: Any]],
                      let key = value.keys.first else { return }
                
                self.ref.child(key).removeValue()
            }
        }
    }
}
