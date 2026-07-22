//
//  ComicsTopView.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 16/03/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit
import CoreImage

protocol ComicsTopViewDelegate: AnyObject {
	func comicsTopViewWillChangeLanguage(_ view: ComicsTopView, languageCode: Settings.Language)
}

class ComicsTopView: UIView {

	var number: Int = 0 {
		didSet {
			self.lblChapterNumber.text = "\(Local("Episodes.Episode")) \(number)"
		}
	}
	
	var name: String = "" {
		didSet {
			self.lblChapterName.text = name
		}
	}
	
	var language: Settings.Language = .russian {
		didSet {
			switch language {
			case .russian:
				self.btnRu.isSelected = true
			case .english:
				self.btnEn.isSelected = true
			case .indian:
				self.btnHindi.isSelected = true
			default:
				break
			}
		}
	}
	
	weak var delegate: ComicsTopViewDelegate?
	
	public static let topPanelHeight: CGFloat = 150
	
	private let vTopPanel = UIView().background(.maroon1)
	
	private let vBackground = GradientView(gradientStart: UIColor.rgba(15,7,15,1), gradientEnd: UIColor.rgba(31,25,31,0))
		.background(.clear)
	
	private let imgPointer = UIImageView(image: UIImage(named: "icon_tap.png"))
	
	private let lblClick = UILabel.guideLabel().text(Local("Episode.Click"))
	
	private let lblScroll = UILabel.guideLabel().text(Local("Episode.Scroll"))
	
	private let imgArrowDown = UIImageView(image: UIImage(named: "icon_bottom.png"))

	private let vLanguages = UIView().background(.clear)
	
	private lazy var btnRu: UIButton = {
		let btn = UIButton.languageButton().title(Local("Episode.Language.Ru"))
		btn.addTarget(self, action: #selector(btnRu_Click(_:)), for: .touchUpInside)
		
		return btn
	}()
	
	private lazy var btnEn: UIButton = {
		let btn = UIButton.languageButton().title(Local("Episode.Language.En"))
		btn.addTarget(self, action: #selector(btnEn_Click(_:)), for: .touchUpInside)
		
		return btn
	}()
	
	private lazy var btnHindi: UIButton = {
		let btn = UIButton.languageButton().title(Local("Episode.Language.Hindi"))
		btn.addTarget(self, action: #selector(btnHindi_Click(_:)), for: .touchUpInside)
		
		return btn
	}()

	private let vChapterTitle = UIView().background(.clear)
	
	private let lblChapterNumber = UILabel.chapterLabel()
	private let lblChapterName = UILabel.titleLabel().alignment(.center)
	
	private var cTop: NSLayoutConstraint!
	
	//MARK: - init
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.backgroundColor = .clear

		self.addSubview(self.vBackground)
		
		self.addSubview(self.vTopPanel)
		[self.imgPointer, self.lblClick, self.lblScroll, self.imgArrowDown].forEach(self.vTopPanel.addSubview)
		
		self.addSubview(self.vLanguages)
		[self.btnRu, self.btnEn, self.btnHindi].forEach(self.vLanguages.addSubview)
		
		self.addSubview(self.vChapterTitle)
		[self.lblChapterNumber, self.lblChapterName].forEach(self.vChapterTitle.addSubview)

		self.cTop = self.vBackground.top(ComicsTopView.topPanelHeight - 50).first!
		
		activateConstraints(
			self.height(452),
			[self.cTop].leading().trailing().bottom(),

			//Top panel
			self.vTopPanel.top().leading().trailing().height(ComicsTopView.topPanelHeight),
			
			//Inside top panel
			self.imgPointer.top(18).centerX(),
			self.lblClick.pinTop(11, to: self.imgPointer).centerX(),
			self.lblScroll.pinTop(12, to: self.lblClick).centerX(),
			self.imgArrowDown.pinTop(16, to: self.lblScroll).centerX(),
			
			//Languages panel
			self.vLanguages.pinTop(29, to: self.vTopPanel).centerX(),

//			self.btnRu.top(),
//			self.btnRu.width(61),
//			self.btnRu.leading(16),
//
//			self.btnEn.top(),
//			self.btnEn.width(of: self.btnRu).height(of: self.btnRu),
//			self.btnRu.pinRight(6, to: self.btnEn),
//			self.btnEn.trailing(16),
//			self.btnEn.bottom(),

			self.btnEn.top(),
			self.btnEn.centerX(),
			self.btnEn.bottom(),

			self.btnRu.top(to: self.btnEn),
			self.btnHindi.top(to: self.btnEn),
			self.btnRu.width(61),
			self.btnEn.width(of: self.btnRu).height(of: self.btnRu),
			self.btnHindi.width(of: self.btnRu).height(of: self.btnRu),

			self.btnRu.pinRight(-6, to: self.btnEn),
			self.btnHindi.pinLeft(6, to: self.btnEn),

			self.btnRu.leading(16),
			self.btnHindi.trailing(16),

			//Chapter number && name
			self.vChapterTitle.pinTop(27, to: self.vLanguages).leading().trailing().bottom(),
			
			self.lblChapterNumber.top().leading(16).trailing(16),
			self.lblChapterName.pinTop(11, to: self.lblChapterNumber).leading(64).trailing(64),
			[self.lblChapterName.bottomItem <= self.bottomItem - 16]
		)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func hitTest(_ point: CGPoint,
						  with event: UIEvent?) -> UIView? {
		
		for btn in [self.btnRu, self.btnEn, self.btnHindi] {
			if btn.point(inside: self.convert(point, to: btn), with: event) {
				return btn
			}
		}
		return nil
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		self.drawMask()
	}
	
	
	func drawMask() {
		let maskLayer = CAShapeLayer()
		
		let radius = CGFloat(455 * EpisodeCollectionViewCell.ratioX)
		let path: CGMutablePath = CGPath(ellipseIn: CGRect(x: self.vTopPanel.frame.size.width * 0.5 - radius, y: self.vTopPanel.frame.size.height - 2 * radius, width: 2 * radius, height: 2 * radius), transform: nil) as! CGMutablePath
		path.closeSubpath()

		maskLayer.path = path;
		maskLayer.lineJoin = CAShapeLayerLineJoin.miter
		
		vTopPanel.layer.mask = maskLayer
		vTopPanel.clipsToBounds = true
		
		//Set top padding for rounded cover depending on view width
		self.cTop.constant = self.getTopPanelHeight(width: self.frame.size.width, radius: radius)
	}
	
	//Calculate top space for background
	private func getTopPanelHeight(width: CGFloat, radius: CGFloat) -> CGFloat {
		//A: too little padding for iPad
//		let r1 = sqrt(pow(0.5 * width, 2) + pow(radius - ComicsTopView.topPanelHeight, 2))
//		let r2: CGFloat = radius - r1
//		return (r2 * r1) / (radius - ComicsTopView.topPanelHeight)
		
		//B: Too big padding for s2
//		let cosAlpha = (radius - ComicsTopView.topPanelHeight) / r1
//		return ComicsTopView.topPanelHeight - radius * cosAlpha
		
		let tangAlpha = 0.5 * width / (radius - ComicsTopView.topPanelHeight)
		//1/sqrt(1+tg(a))
		let cosAlpha = 1 / sqrt(1 + tangAlpha)
		let r1 = (radius - ComicsTopView.topPanelHeight) / cosAlpha
		let r2 = radius - r1
		return round(r2 / cosAlpha)
	}
	
	//MARK: - Handlers
	@objc func btnRu_Click(_ sender: UIButton) {
		if !sender.isSelected {
			changeLanguage(.russian, sender: sender)
		}
	}
	
	@objc func btnEn_Click(_ sender: UIButton) {
		if !sender.isSelected {
			changeLanguage(.english, sender: sender)
		}
	}

	@objc func btnHindi_Click(_ sender: UIButton) {
		if !sender.isSelected {
			changeLanguage(.indian, sender: sender)
		}
	}

	private func changeLanguage(_ languageCode: Settings.Language, sender: UIButton) {
		for btn in [self.btnRu, self.btnEn, self.btnHindi] {
			btn.isSelected = btn == sender
		}
		self.delegate?.comicsTopViewWillChangeLanguage(self, languageCode: languageCode)
	}
}
