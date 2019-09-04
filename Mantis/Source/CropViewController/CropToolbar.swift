//
//  CropToolbar.swift
//  Mantis
//
//  Created by Echo on 11/6/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

public enum CropToolbarMode {
    case normal
    case simple
}

class CropToolbar: UIView {    
    var selectedCancel = {}
    var selectedCrop = {}
    var selectedRotate = {}
    var selectedReset = {}
    var selectedSetRatio = {}
    
    var cancelButton: UIButton?
    var setRatioButton: UIButton?
    var resetButton: UIButton?
    var anticlockRotateButton: UIButton?
    var cropButton: UIButton?
    
    private var optionButtonStackView: UIStackView?
    private var actionButtonStackView: UIStackView?
    
    private func createOptionButton(withTitle title: String?, andAction action: Selector) -> UIButton {
        let buttonColor = UIColor.white
//        let buttonFontSize: CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 20 : 17
        let buttonFontSize: CGFloat = 20
        let buttonFont = UIFont.systemFont(ofSize: buttonFontSize)
        
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.titleLabel?.font = buttonFont
        
        if let title = title {
            button.setTitle(title, for: .normal)
            button.setTitleColor(buttonColor, for: .normal)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        
        return button
    }
    
    private func createCancelButton(with cancelStr: String) {
//        let cancelText = LocalizedHelper.getString("Cancel")
        
        cancelButton = createOptionButton(withTitle: cancelStr, andAction: #selector(cancel))
    }
    
    private func createRotationButton(with image: UIImage?) {
        anticlockRotateButton = createOptionButton(withTitle: nil, andAction: #selector(rotate))
        anticlockRotateButton?.setImage(ToolBarButtonImageBuilder.rotateCCWImage(with: image), for: .normal)
    }
    
    private func createResetButton(with image: UIImage? = nil, with resetStr: String) {
//        if let image = image {
//            resetButton = createOptionButton(withTitle: nil, andAction: #selector(reset))
//            resetButton?.setImage(image, for: .normal)
//        } else {
//            let resetText = LocalizedHelper.getString("Reset")

            resetButton = createOptionButton(withTitle: resetStr, andAction: #selector(reset))
//        }
    }
    
    private func createSetRatioButton(with image: UIImage?) {
        setRatioButton = createOptionButton(withTitle: nil, andAction: #selector(setRatio))
        setRatioButton?.setImage(ToolBarButtonImageBuilder.clampImage(with: image), for: .normal)
    }
    
    private func createCropButton(with doneStr: String) {
//        let doneText = LocalizedHelper.getString("Done")
        cropButton = createOptionButton(withTitle: doneStr, andAction: #selector(crop))
    }
    
    private func createButtonContainer() {
        optionButtonStackView = UIStackView()
        addSubview(optionButtonStackView!)
        
        optionButtonStackView?.distribution = .equalCentering
        optionButtonStackView?.isLayoutMarginsRelativeArrangement = true
    }
    
    private func createActionButtonContainer() {
        actionButtonStackView = UIStackView()
        addSubview(actionButtonStackView!)
        
        actionButtonStackView?.distribution = .equalSpacing
        actionButtonStackView?.isLayoutMarginsRelativeArrangement = true
    }
    
    private func setButtonContainerLayout() {
        optionButtonStackView?.translatesAutoresizingMaskIntoConstraints = false
        optionButtonStackView?.topAnchor.constraint(equalTo: topAnchor).isActive = true
        if let customBottomAnchor = actionButtonStackView?.topAnchor {
            optionButtonStackView?.bottomAnchor.constraint(equalTo: customBottomAnchor, constant: -15).isActive = true
        } else {
            optionButtonStackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        optionButtonStackView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        optionButtonStackView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    private func setActionButtonContainerLayout() {
        actionButtonStackView?.translatesAutoresizingMaskIntoConstraints = false
        actionButtonStackView?.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        actionButtonStackView?.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        actionButtonStackView?.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
    }
    
    private func addButtonsToContainer(buttons: [UIButton?]) {
        buttons.forEach{
            if let button = $0 {
                optionButtonStackView?.addArrangedSubview(button)
            }
        }
    }
    
    private func addActionButtonsToContainer(buttons: [UIButton?]) {
        buttons.forEach{
            if let button = $0 {
                actionButtonStackView?.addArrangedSubview(button)
            }
        }
    }
    
    func createToolbarUI(mode: CropToolbarMode = .normal,
                         rotateButtonImage: UIImage?,
                         clampButtonImage: UIImage?,
                         doneStr: String,
                         cancelStr: String,
                         resetStr: String) {
        createButtonContainer()
        createActionButtonContainer()
        setButtonContainerLayout()
        setActionButtonContainerLayout()

        createRotationButton(with: rotateButtonImage)
        createSetRatioButton(with: clampButtonImage)

        if mode == .normal {
            createResetButton(with: ToolBarButtonImageBuilder.resetImage(), with: resetStr)
            createCancelButton(with: cancelStr)
            createCropButton(with: doneStr)
            addButtonsToContainer(buttons: [cancelButton, anticlockRotateButton, resetButton, setRatioButton, cropButton])
        } else {
            createResetButton(with: nil, with: resetStr)
            addButtonsToContainer(buttons: [anticlockRotateButton, resetButton, setRatioButton])
            createCancelButton(with: cancelStr)
            createCropButton(with: doneStr)
            addActionButtonsToContainer(buttons: [cancelButton, cropButton])
        }
    }
    
    func checkOrientation() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            optionButtonStackView?.axis = .horizontal
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            actionButtonStackView?.axis = .horizontal
            actionButtonStackView?.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        } else {
            optionButtonStackView?.axis = .vertical
            optionButtonStackView?.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
            actionButtonStackView?.axis = .vertical
            actionButtonStackView?.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        }
    }
    
    @objc private func cancel() {
        selectedCancel()
    }
    
    @objc private func setRatio() {
        selectedSetRatio()
    }
    
    @objc private func reset(_ sender: Any) {
        selectedReset()
    }
    
    @objc private func rotate(_ sender: Any) {
        selectedRotate()
    }
    
    @objc private func crop(_ sender: Any) {
        selectedCrop()
    }
}
