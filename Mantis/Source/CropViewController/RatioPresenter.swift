//
//  RatioPresenter.swift
//  Mantis
//
//  Created by Echo on 11/3/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

enum RatioType {
    case horizontal
    case vertical
}

class RatioPresenter {
    var didGetRatio: ((Double)->Void) = { _ in }
    private var type: RatioType = .vertical
    private var originalRatioH: Double
    private var ratios: [RatioItemType]
    
    init(type: RatioType, originalRatioH: Double, ratios: [RatioItemType] = []) {
        self.type = type
        self.originalRatioH = originalRatioH
        self.ratios = ratios
    }
    
    func present(by viewController: UIViewController, in sourceView: UIView,
                 cancelStr: String,
                 originalSizeStr: String,
                 squareSizeStr: String) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        for ratio in ratios {
            var title = (type == .horizontal) ? ratio.nameH : ratio.nameV
            
            if title == "Original" {
                title = originalSizeStr
            }
            
            if title == "Square" {
                title = squareSizeStr
            }
            
            let action = UIAlertAction(title: title, style: .default) {[weak self] _ in
                guard let self = self else { return }
                let ratioValue = (self.type == .horizontal) ? ratio.ratioH : ratio.ratioV
                self.didGetRatio(ratioValue)
            }
            actionSheet.addAction(action)
        }
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            // https://stackoverflow.com/a/27823616/288724
            actionSheet.popoverPresentationController?.permittedArrowDirections = .any
            actionSheet.popoverPresentationController?.sourceView = sourceView
            actionSheet.popoverPresentationController?.sourceRect = sourceView.bounds
        }
        
//        let cancelText = LocalizedHelper.getString("Cancel")
        let cancelAction = UIAlertAction(title: cancelStr, style: .cancel)
        actionSheet.addAction(cancelAction)
        
        viewController.present(actionSheet, animated: true)
    }
}
