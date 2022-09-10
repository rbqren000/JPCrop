//
//  CropViewController.swift
//  JPCrop_Example
//
//  Created by Rogue24 on 2020/12/26.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import JPCrop

class CropViewController: UIViewController {
    typealias CropDone = (UIImage?, Croper.Configure) -> ()
    
    private var configure: Croper.Configure!
    private var croper: Croper!
    private var slider: CropSlider!
    private var cropDone: CropDone?
    
    private let bgLayer = CAGradientLayer()
    
    static func build(_ configure: Croper.Configure, cropDone: CropDone?) -> CropViewController {
        let cropVC = CropViewController()
        cropVC.configure = configure
        cropVC.cropDone = cropDone
        return cropVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBase()
        setupOperationBar()
        setupCroper()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}

private extension CropViewController {
    func setupBase() {
        view.clipsToBounds = true
        view.backgroundColor = .black
    }
    
    func setupOperationBar() {
        let h = 50.px + NavBarH + DiffTabBarH
        let operationBar = UIView(frame: CGRect(x: 0, y: PortraitScreenHeight - h, width: PortraitScreenWidth, height: h))
        view.addSubview(operationBar)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = operationBar.bounds
        operationBar.addSubview(blurView)
        
        let slider = CropSlider(minimumValue: -Float(Croper.diffAngle), maximumValue: Float(Croper.diffAngle), value: 0)
        slider.frame.origin.y = 10.px
        slider.sliderWillChangedForUser = { [weak self] in
            guard let self = self else { return }
            self.croper.showRotateGrid(animated: true)
        }
        slider.sliderDidChangedForUser = { [weak self] value in
            guard let self = self else { return }
            self.croper.rotate(value)
        }
        slider.sliderEndChangedForUser = { [weak self] in
            guard let self = self else { return }
            self.croper.hideRotateGrid(animated: true)
        }
        operationBar.addSubview(slider)
        self.slider = slider
        
        let stackView = UIStackView()
        stackView.backgroundColor = .clear
        stackView.frame = CGRect(x: 0, y: 50.px, width: PortraitScreenWidth, height: NavBarH)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        operationBar.addSubview(stackView)
        
        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        backBtn.tintColor = .white
        backBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        backBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(backBtn)
        
        let rotateBtn = UIButton(type: .system)
        rotateBtn.setImage(UIImage(systemName: "rotate.left"), for: .normal)
        rotateBtn.tintColor = .white
        rotateBtn.addTarget(self, action: #selector(rotateLeft), for: .touchUpInside)
        rotateBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(rotateBtn)
        
        let whRatioBtn = UIButton(type: .system)
        whRatioBtn.setImage(UIImage(systemName: "aspectratio"), for: .normal)
        whRatioBtn.tintColor = .white
        whRatioBtn.addTarget(self, action: #selector(switchWHRatio), for: .touchUpInside)
        whRatioBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(whRatioBtn)
        
        let recoverBtn = UIButton(type: .system)
        recoverBtn.setImage(UIImage(systemName: "gobackward"), for: .normal)
        recoverBtn.tintColor = .white
        recoverBtn.addTarget(self, action: #selector(recover), for: .touchUpInside)
        recoverBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(recoverBtn)
        
        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.titleLabel?.font = .systemFont(ofSize: 15.px, weight: .bold)
        doneBtn.addTarget(self, action: #selector(crop), for: .touchUpInside)
        doneBtn.frame.size = CGSize(width: NavBarH, height: NavBarH)
        stackView.addArrangedSubview(doneBtn)
    }
    
    func setupCroper() {
        Croper.margin = UIEdgeInsets(top: StatusBarH + 15.px,
                                     left: 15.px,
                                     bottom: 50.px + NavBarH + DiffTabBarH + 15.px,
                                     right: 15.px)
        let croper = Croper(frame: PortraitScreenBounds, configure)
        croper.clipsToBounds = false
        view.insertSubview(croper, at: 0)
        self.croper = croper
    }
}

// MARK: - 监听返回/恢复/旋转/比例切换/裁剪事件
private extension CropViewController {
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func recover() {
        croper.recover(animated: true)
        slider.updateValue(0, animated: true)
    }
    
    @objc func rotateLeft() {
        croper.rotateLeft(animated: true)
    }
    
    @objc func switchWHRatio() {
        let alertCtr = UIAlertController(title: "切换裁剪宽高比", message: nil, preferredStyle: .actionSheet)
        alertCtr.addAction(UIAlertAction(title: "原始", style: .default) { _ in
            self.croper.updateCropWHRatio(0, rotateGridCount: (5, 5), animated: true)
        })
        alertCtr.addAction(UIAlertAction(title: "9 : 16", style: .default) { _ in
            self.croper.updateCropWHRatio(9.0 / 16.0, rotateGridCount: (6, 5), animated: true)
        })
        alertCtr.addAction(UIAlertAction(title: "1 : 1", style: .default) { _ in
            self.croper.updateCropWHRatio(1, rotateGridCount: (4, 4), animated: true)
        })
        alertCtr.addAction(UIAlertAction(title: "4 : 3", style: .default) { _ in
            self.croper.updateCropWHRatio(4.0 / 3.0, rotateGridCount: (4, 5), animated: true)
        })
        alertCtr.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alertCtr, animated: true, completion: nil)
    }
    
    @objc func crop() {
        navigationController?.popViewController(animated: true)
        
        guard let cropDone = self.cropDone else { return }
        let configure = croper.syncConfigure()
        croper.asyncCrop {
            guard let image = $0 else { return }
            cropDone(image, configure)
        }
    }
}

