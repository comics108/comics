//
//  MusicTableViewCell.swift
//  Mahabharata
//
//  Created by Olga Zhegulo on 08/03/18.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import Lottie

protocol MusicTableViewCellDelegate: class {
	func musicTableViewCellDidRead(_ cell: MusicTableViewCell, music: Music)
	func musicTableViewCellDidDelete(_ cell: MusicTableViewCell,  music: Music)
}

class MusicTableViewCell: ReusableTableViewCell {
	
	private var music: Music?
	weak var delegate: MusicTableViewCellDelegate?

	private let lblNumber = UILabel.numberSmallLabel()
	private let vText = UIView()
	private let lblTitle = UILabel.titleSmallLabel()
	private let lblSubtitle = UILabel.subtitleSmallLabel()
	private let btnDownload = UIButton(type: .custom).foreground(UIImage(named: "icon_download.png")!)
	private let vProgressDownload: CircularProgressView = {
		let view = CircularProgressView(radius: 11.0, trackWidth: 2.0).background(.clear)
		view.trackColor = .inactiveYellow
		view.progressColor = .yellow1
		
		return view
	}()
	
	private let btnDelete = UIButton(type: .custom).foreground(UIImage(named:"icon_del.png")!)

	private let ltEqualizerAnimation: AnimationView = {
		let view = AnimationView(name: "equalizer")
		view.loopMode = .loop
		return view
	}()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.selectionStyle = .none
		self.backgroundColor = UIColor.clear

		self.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
		
		self.contentView.addSubview(self.lblNumber)
		self.contentView.addSubview(self.vText)
		self.vText.addSubview(self.lblTitle)
		self.vText.addSubview(self.lblSubtitle)
		self.contentView.addSubview(self.btnDelete)
		self.contentView.addSubview(self.vProgressDownload)
		self.contentView.addSubview(self.btnDownload)

		self.btnDownload.addTarget(self, action: #selector(btnDownload_Click(_:)), for: .touchUpInside)
		self.btnDelete.addTarget(self, action: #selector(btnDelete_Click(_:)), for: .touchUpInside)

		self.btnDelete.isHidden = true
		self.vProgressDownload.isHidden = true
		
		self.vProgressDownload.clearsContextBeforeDrawing = false
		
		self.contentView.addSubview(self.ltEqualizerAnimation)
		self.ltEqualizerAnimation.isHidden = true

		activateConstraints(
			self.lblNumber.leadingItem == self.contentView.leadingItem + 16,
			self.lblNumber.centerYItem == self.contentView.centerYItem,
			
			self.ltEqualizerAnimation.leadingItem == self.contentView.leadingItem + 16,
			self.ltEqualizerAnimation.centerYItem == self.contentView.centerYItem,

			self.vText.topItem == self.contentView.topItem + 13,
			self.vText.leadingItem == self.contentView.leadingItem + 49,
			self.vText.trailingItem == self.contentView.trailingItem - 71,
			self.vText.centerYItem == self.contentView.centerYItem,

			self.lblTitle.leadingItem == self.vText.leadingItem,
			self.lblTitle.topItem == self.vText.topItem,
			self.lblTitle.trailingItem == self.vText.trailingItem,
			
			self.lblSubtitle.leadingItem == self.vText.leadingItem,
			self.lblSubtitle.topItem == self.lblTitle.bottomItem + 3,
			self.lblSubtitle.trailingItem == self.vText.trailingItem,
			self.lblSubtitle.bottomItem == self.vText.bottomItem,
			
			self.btnDownload.widthItem == 44,
			self.btnDownload.heightItem == 44,
			self.btnDownload.centerYItem == self.contentView.centerYItem,
			self.btnDownload.trailingItem == self.contentView.trailingItem - 3,
			
			self.vProgressDownload.widthItem == 22,
			self.vProgressDownload.heightItem == 22,
			self.vProgressDownload.centerYItem == self.btnDownload.centerYItem,
			self.vProgressDownload.centerXItem == self.btnDownload.centerXItem,
			
			self.btnDelete.widthItem == 44,
			self.btnDelete.heightItem == 44,
			self.btnDelete.centerYItem == self.contentView.centerYItem,
			self.btnDelete.trailingItem == self.contentView.trailingItem - 3
		)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		
		self.stopAnimation()
	}
	
	func fill(with music: Music, number: Int, isPlaying: Bool, delegate: MusicTableViewCellDelegate) {
		self.music = music
		self.delegate = delegate
		
		self.lblNumber.text = String(number)
		self.lblTitle.text = music.name
		self.lblSubtitle.text = music.author
		
		if isPlaying {
			self.playAnimation()
		} else {
			self.stopAnimation()
		}
		
		self.update()		
	}
	
	func update() {
		let musicState = self.music!.state
		
		//Update buttons
		self.vProgressDownload.isHidden = musicState.isDownloaded || musicState.downloadInfo == nil
		if !self.vProgressDownload.isHidden, let downloadInfo = musicState.downloadInfo {
			self.vProgressDownload.progress = downloadInfo.bytesTotal > 0 ? Double(downloadInfo.bytesReceived) / Double(downloadInfo.bytesTotal) : 0
		}
		self.btnDownload.isHidden = musicState.isDownloaded || musicState.downloadInfo != nil
		self.btnDelete.isHidden = !musicState.isDownloaded || musicState.downloadInfo != nil
	}

	func playAnimation()
	{
		//Hide number
		self.lblNumber.isHidden = true
		
		//Show animation instead
		self.ltEqualizerAnimation.play()
		self.ltEqualizerAnimation.isHidden = false
	}
	
	func stopAnimation()
	{
		//Stop and hide animation
		self.ltEqualizerAnimation.stop()
		self.ltEqualizerAnimation.isHidden = true
		
		//Show number instead
		self.lblNumber.isHidden = false
	}
	
	// MARK: - Handlers
	@objc func btnDownload_Click(_ sender: UIButton) {
		self.delegate?.musicTableViewCellDidRead(self, music: self.music!)
	}
	
	@objc func btnDelete_Click(_ sender: UIButton) {
		self.delegate?.musicTableViewCellDidDelete(self, music: self.music!)
	}
}
