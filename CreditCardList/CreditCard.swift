//
//  CreditCard.swift
//  CreditCardList
//
//  Created by JUNO on 2022/05/07.
//

import Foundation

struct CreditCard: Codable {
    let id: Int
    let rank: Int
    let name: String
    let cardImageURL: String
    let promotionDetail: PromotionDetail
    let isSelected: Bool?
}

struct PromotionDetail: Codable {
    let companyName: String
    let amount: Int
    let benefitDate: String
    let benefitDetail: String
    let benefitCondition: String
    let condition: String
    let period: String
}
