//
//  Subscriptions.swift
//  MacMagazine
//
//  Created by Cassio Rossi on 05/03/21.
//  Copyright © 2021 MacMagazine. All rights reserved.
//

import Combine
import Foundation
import InAppPurchase

enum InAppPurchaseStatus: Equatable {
    case canPurchase
    case processing
    case gotProductPrice(String)
    case purchasedSuccess
    case expired
    case fail
}

class Subscriptions {

    static let shared = Subscriptions()

    let identifier = "MMASSINATURAMENSAL"

    var productCancellable: AnyCancellable?
    var purchaseCancellable: AnyCancellable?
    var receiptCancellable: AnyCancellable?

    var selectedProduct: Product?
    var status: ((InAppPurchaseStatus) -> Void)?
    var isPurchasing: Bool = false

    // MARK: - Methods -

    func checkSubscriptions() {
        productCancellable?.cancel()
        purchaseCancellable?.cancel()
        receiptCancellable?.cancel()

        receiptCancellable = InAppPurchaseManager.shared.$status
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] rsp in
                logD(rsp)

                var settings = Settings()
                settings.purchased = false

                switch rsp {
                    case .failure(_):
                        self?.status?(.canPurchase)

                    case .success(let response):
                        switch response {
                        case .retrieving,
                             .purchasing,
                             .restoring,
                             .validating:
                            self?.status?(.processing)
                        case .validated:
                            settings.purchased = true
                            self?.status?(.purchasedSuccess)
                        case .expired:
                            self?.status?(.expired)
                        default:
                            self?.status?(.canPurchase)
                        }
                }
            }

        InAppPurchaseManager.shared.validateReceipt(subscription: identifier)
    }

    func getProducts() {
        if InAppPurchaseManager.shared.canPurchase {
            if Settings().purchased {
                status?(.purchasedSuccess)
            } else {
                status?(.canPurchase)
                fetchProductInformation()
            }
        }
    }

    func purchase() {
        buy(restore: false)
    }

    func restore() {
        buy(restore: true)
    }

    fileprivate func buy(restore: Bool) {
        productCancellable?.cancel()
        purchaseCancellable?.cancel()
        receiptCancellable?.cancel()

        status?(.processing)

        purchaseCancellable = InAppPurchaseManager.shared.$status
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] rsp in
                logD(rsp)

                switch rsp {
                    case .failure(_):
                        self?.isPurchasing = false
                        self?.status?(.canPurchase)

                    case .success(let response):
                        var status: InAppPurchaseStatus {
                            switch response {
                            case .purchased:
                                self?.isPurchasing = false
                                return .purchasedSuccess
                            case .purchasing,
                                 .restoring:
                                return .processing
                            case .restored:
                                self?.checkSubscriptions()
                                return .processing
                            default:
                                self?.isPurchasing = false
                                return .canPurchase
                            }
                        }
                        self?.status?(status)
                }
            }

        guard let product = selectedProduct else {
            return
        }
        isPurchasing = true
        InAppPurchaseManager.shared.purchase(product: restore ? nil : product)
    }
}

extension Subscriptions {
    fileprivate func fetchProductInformation() {
        productCancellable?.cancel()
        purchaseCancellable?.cancel()
        receiptCancellable?.cancel()

        status?(.processing)

        productCancellable = InAppPurchaseManager.shared.$products
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] rsp in
                switch rsp {
                    case .failure(_):
                        self?.status?(.fail)

                    case .success(let response):
                        guard let product = response.first,
                              let price = product.price else {
                            self?.status?(.fail)
                            return
                        }
                        logD(product.debugDescription)

                        self?.selectedProduct = product
                        self?.status?(.gotProductPrice(price))
                }
            }

        InAppPurchaseManager.shared.getProducts(for: [identifier])
    }
}
