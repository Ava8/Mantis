//
//  CropViewController.swift
//  Mantis
//
//  Created by Echo on 10/30/18.
//  Copyright © 2018 Echo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit

public protocol CropViewControllerDelegate: class {
    func cropViewControllerDidCrop(_ cropViewController: CropViewController, cropped: UIImage)
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage)
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage)
    func cropViewControllerWillDismiss(_ cropViewController: CropViewController)
}

public extension CropViewControllerDelegate {
    func cropViewControllerWillDismiss(_ cropViewController: CropViewController) {}
    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {}
    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {}
}

public enum CropViewControllerMode {
    case normal
    case customizable    
}

public class CropViewController: UIViewController {
    /// When a CropViewController is used in a storyboard,
    /// passing an image to it is needed after the CropViewController is created.
    public var image: UIImage! {
        didSet {
            cropView.image = image
        }
    }
    
    public weak var delegate: CropViewControllerDelegate?
    public var mode: CropViewControllerMode = .normal
    public var config = Mantis.Config()
    
    private var orientation: UIInterfaceOrientation = .unknown
    
    private lazy var cropView = CropView(image: image, viewModel: CropViewModel())
    private lazy var cropToolbar = CropToolbar(frame: CGRect.zero)
    
    private var ratioPresenter: RatioPresenter?
    private var stackView: UIStackView?
    
    private var initialLayout = false
    
    private var doneStr: String = ""
    private var cancelStr: String = ""
    private var resetStr: String = ""
    private var originalSizeStr: String = ""
    private var squareSizeStr: String = ""
    
    public var rotateImage: UIImage?
    public var clampImage: UIImage?
    
    deinit {
        print("CropViewController deinit.")
    }
    
    init(image: UIImage, config: Mantis.Config = Mantis.Config(), mode: CropViewControllerMode = .normal) {
        self.image = image
        self.config = config
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setPresetFixedRatio() {
        let fixedRatioManager = getFixedRatioManager()
        
        var ratioItem: RatioItemType
        if fixedRatioManager.ratios.count == 0 {
            ratioItem = fixedRatioManager.getOriginalRatioItem()
        } else {
            ratioItem = fixedRatioManager.ratios[0]
        }

        let ratioValue = (fixedRatioManager.type == .horizontal) ? ratioItem.ratioH : ratioItem.ratioV
        setFixedRatio(ratioValue)
    }
    
    fileprivate func createCropToolbar() {
        cropToolbar.backgroundColor = .black
        
        cropToolbar.selectedCancel = {[weak self] in self?.handleCancel() }
        cropToolbar.selectedRotate = {[weak self] in self?.handleRotate() }
        cropToolbar.selectedReset = {[weak self] in self?.handleReset() }
        cropToolbar.selectedSetRatio = {[weak self] in self?.handleSetRatio() }
        cropToolbar.selectedCrop = {[weak self] in self?.handleCrop() }
        
        let showRatioButton: Bool
        
        if config.alwaysUsingOnePresetFixedRatio {
            showRatioButton = false
            setPresetFixedRatio()
        } else {
            showRatioButton = true
        }
        
        if mode == .normal {
            cropToolbar.createToolbarUI(rotateButtonImage: rotateImage,
                                         clampButtonImage: clampImage,
                                         doneStr: doneStr,
                                         cancelStr: cancelStr,
                                         resetStr: resetStr)
        } else {
            cropToolbar.createToolbarUI(mode: .simple,
                                         rotateButtonImage: rotateImage,
                                         clampButtonImage: clampImage,
                                         doneStr: doneStr,
                                         cancelStr: cancelStr,
                                         resetStr: resetStr)
        }
    }
    
    fileprivate func getFixedRatioManager() -> FixedRatioManager {
        let type: RatioType = cropView.getRatioType(byImageIsOriginalisHorizontal: cropView.image.isHorizontal())
        
        let ratio = cropView.getImageRatioH()
        
        return FixedRatioManager(type: type,
                                 originalRatioH: ratio,
                                 ratioOptions: config.ratioOptions,
                                 customRatios: config.getCustomRatioItems())
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        createCropToolbar()
        createCropView()
        initLayout()
        updateLayout()
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            view.layoutIfNeeded()
            cropView.adaptForCropBox()
        }
    }
    
    public override var prefersStatusBarHidden: Bool {
        return true
    }
    
    public override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.top, .bottom]
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        cropView.prepareForDeviceRotation()
    }
    
    public func configureLocalizedStrings(doneStr: String,
                                          cancelStr: String,
                                          resetStr: String,
                                          originalSizeStr: String,
                                          squareSizeStr: String) {
        self.doneStr = doneStr
        self.cancelStr = cancelStr
        self.resetStr = resetStr
        self.originalSizeStr = originalSizeStr
        self.squareSizeStr = squareSizeStr
    }
    
    @objc func rotated() {
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        
        guard statusBarOrientation != .unknown else { return }
        guard statusBarOrientation != orientation else { return }
        
        orientation = statusBarOrientation
        
        if UIDevice.current.userInterfaceIdiom == .phone
            && statusBarOrientation == .portraitUpsideDown {
            return
        }
        
        updateLayout()
        view.layoutIfNeeded()
        
        // When it is embedded in a container, the timing of viewDidLayoutSubviews
        // is different with the normal mode.
        // So delay the execution to make sure handleRotate runs after the final
        // viewDidLayoutSubviews
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.cropView.handleRotate()
        }
    }
    
    func setFixedRatio(_ ratio: Double) {
        cropToolbar.setRatioButton?.tintColor = nil
        cropView.aspectRatioLockEnabled = true
        cropView.viewModel.aspectRatio = CGFloat(ratio)
        
        UIView.animate(withDuration: 0.5) {
            self.cropView.setFixedRatioCropBox()
        }
    }
    
    private func createCropView() {
        cropView.delegate = self
        cropView.clipsToBounds = true
    }
    
    private func handleCancel() {
        delegate?.cropViewControllerWillDismiss(self)
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.cropViewControllerDidCancel(self, original: self.image)
        }
    }
    
    private func resetRatioButton() {
        cropView.aspectRatioLockEnabled = false
        cropToolbar.setRatioButton?.tintColor = .white
    }
    
    @objc private func handleSetRatio() {
        if cropView.aspectRatioLockEnabled {
            resetRatioButton()
            return
        }
        
        let fixedRatioManager = getFixedRatioManager()
        
        guard fixedRatioManager.ratios.count > 0 else { return }
        
        if fixedRatioManager.ratios.count == 1 {
            let ratioItem = fixedRatioManager.ratios[0]
            let ratioValue = (fixedRatioManager.type == .horizontal) ? ratioItem.ratioH : ratioItem.ratioV
            setFixedRatio(ratioValue)
            return
        }
        
        ratioPresenter = RatioPresenter(type: fixedRatioManager.type, originalRatioH: fixedRatioManager.originalRatioH, ratios: fixedRatioManager.ratios)
        ratioPresenter?.didGetRatio = {[weak self] ratio in
            self?.setFixedRatio(ratio)
        }
        ratioPresenter?.present(by: self, in: cropToolbar.setRatioButton!,
                                cancelStr: cancelStr,
                                originalSizeStr: originalSizeStr,
                                squareSizeStr: squareSizeStr)
    }

    private func handleReset() {
        resetRatioButton()
        cropView.reset(forceFixedRatio: config.alwaysUsingOnePresetFixedRatio)
    }
    
    private func handleRotate() {
        cropView.counterclockwiseRotate90()
    }
    
    private func handleCrop() {
        guard let image = cropView.crop() else {
            delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
            return
        }
        
        delegate?.cropViewControllerWillDismiss(self)
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.cropViewControllerDidCrop(self, cropped: image)
        }
    }
}

// Auto layout
extension CropViewController {
    fileprivate func initLayout() {
        stackView = UIStackView()
        view.addSubview(stackView!)
        
        stackView?.translatesAutoresizingMaskIntoConstraints = false
        cropToolbar.translatesAutoresizingMaskIntoConstraints = false
        cropView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            stackView?.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            stackView?.topAnchor.constraint(equalTo: self.topLayoutGuide.topAnchor).isActive = true
        }
        if #available(iOS 11.0, *) {
            stackView?.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            stackView?.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.bottomAnchor).isActive = true
        }
        if #available(iOS 11.0, *) {
            stackView?.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        } else {
            stackView?.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        }
        if #available(iOS 11.0, *) {
            stackView?.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        } else {
            stackView?.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        }
    }
    
    fileprivate func setStackViewAxis() {
        if UIApplication.shared.statusBarOrientation.isPortrait {
            stackView?.axis = .vertical
        } else if UIApplication.shared.statusBarOrientation.isLandscape {
            stackView?.axis = .horizontal
        }
    }
    
    fileprivate func changeStackViewOrder() {
        stackView?.removeArrangedSubview(cropView)
        stackView?.removeArrangedSubview(cropToolbar)
        
        if UIApplication.shared.statusBarOrientation.isPortrait || UIApplication.shared.statusBarOrientation == .landscapeRight {
            stackView?.addArrangedSubview(cropView)
            stackView?.addArrangedSubview(cropToolbar)
        } else if UIApplication.shared.statusBarOrientation == .landscapeLeft {
            stackView?.addArrangedSubview(cropToolbar)
            stackView?.addArrangedSubview(cropView)
        }
    }

    fileprivate func updateLayout() {
        setStackViewAxis()
        cropToolbar.checkOrientation()
        changeStackViewOrder()
    }
}

extension CropViewController: CropViewDelegate {
    func cropViewDidBecomeResettable(_ cropView: CropView) {
        cropToolbar.resetButton?.isHidden = false
    }
    
    func cropViewDidBecomeNonResettable(_ cropView: CropView) {
        cropToolbar.resetButton?.isHidden = true
    }
}

// API
extension CropViewController {
    public func crop() {
        guard let image = cropView.crop() else {
            delegate?.cropViewControllerDidFailToCrop(self, original: cropView.image)
            return
        }
        
        delegate?.cropViewControllerDidCrop(self, cropped: image)
    }
    
    public func process(_ image: UIImage) -> UIImage? {
        return cropView.crop(image)
    }
}
