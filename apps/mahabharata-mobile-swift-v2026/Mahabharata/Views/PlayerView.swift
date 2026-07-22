//
//  PlayerView.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 08/02/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit
import MediaPlayer
import FirebaseAnalytics
import ComicsViewer

protocol PlayerViewDelegate : class {
	func playerViewDidNext(_ view: PlayerView)
	func playerViewDidPrevious(_ view: PlayerView)
	func playerViewToggledPlay(_ view: PlayerView, isPlaying: Bool)
}

class PlayerView: UIView {

	weak var delegate: PlayerViewDelegate?
	var music: Music!

	private var soundManager = SoundManager(audioSessionCategory: AVAudioSession.Category.playback.rawValue)
	
	private(set) var isPlaying: Bool = false
	
	private var timer = Timer()
	
	//Variable to check end of music: when does not changed, track is finished
	private var lastMusicTime: TimeInterval = 0
	
	//Helper variable for changing slider
	private var changedTimeInterval: TimeInterval = 0

	//Item info
	private let vText = UIView()
	private let lblTitle = UILabel.titleSmallLabel()
	private let lblSubtitle = UILabel.subtitleSmallLabel()

	//Progress
	fileprivate lazy var vProgressContainer = UIView()
	
	//MARK: - Controls
	private var sldrTime: UISlider = {
		let slider = UISlider()
		slider.tintColor = .maroon3
		slider.minimumTrackTintColor = .yellow1
		slider.maximumTrackTintColor = .maroon3
		slider.setThumbImage(UIImage(named: "music_circle.png"), for: .normal)

		slider.addTarget(self, action: #selector(slider_TimeChanged), for: .valueChanged)
		slider.addTarget(self, action: #selector(slider_TimeSet), for: .touchUpInside)

		return slider
	}()
	
	private let lblCurrentTime = UILabel.guideLabel()
	private let lblDuration = UILabel.guideLabel()

	fileprivate lazy var vPlayerContainer = UIView()
	
	fileprivate lazy var btnPlay: UIButton = {
		let btn = UIButton(type: .custom).foreground(UIImage(named: "icon_play.png")!)
		btn.addTarget(self, action: #selector(btnPlay_Click), for: .touchUpInside)
		
		return btn
	}()
	
	fileprivate lazy var btnPause: UIButton = {
		let btn = UIButton(type: .custom).foreground(UIImage(named: "icon_pause.png")!)
		btn.addTarget(self, action: #selector(btnPause_Click), for: .touchUpInside)
		
		return btn
	}()
	
	fileprivate lazy var btnPrevious: UIButton = {
		let btn = UIButton(type: .custom).foreground(UIImage(named: "icon_rewind.png")!)
		btn.addTarget(self, action: #selector(btnPrevious_Click), for: .touchUpInside)

		return btn
	}()

	fileprivate lazy var btnNext: UIButton = {
		let btn = UIButton(type: .custom).foreground(UIImage(named: "icon_forward.png")!)
		btn.addTarget(self, action: #selector(btnNext_Click), for: .touchUpInside)
		
		return btn
	}()
	
	required init(music: Music, delegate: PlayerViewDelegate) {
		
		self.music = music
		self.delegate = delegate
		
		super.init(frame: .zero)
		
		self.addSubview(self.vText)
		self.vText.addSubview(self.lblTitle)
		self.vText.addSubview(self.lblSubtitle)

		self.addSubview(self.vProgressContainer)
		
		self.vProgressContainer.addSubview(self.sldrTime)
		self.vProgressContainer.addSubview(self.lblCurrentTime)
		self.vProgressContainer.addSubview(self.lblDuration)

		self.addSubview(self.vPlayerContainer)
		[self.btnPrevious, self.btnPause, self.btnPlay, self.btnNext].forEach(self.vPlayerContainer.addSubview)
		
		self.backgroundColor = .maroon2
		
		activateConstraints(
			self.vText.top(19).leading(15).trailing(15),
			
			self.lblTitle.dockTop(),
			
			self.lblSubtitle.pinTop(3, to: self.lblTitle).leading().trailing().bottom(),

			self.vProgressContainer.pinTop(16, to: self.vText).leading().trailing(),
			
			self.sldrTime.top().leading(15).trailing(15),
			self.lblCurrentTime.pinTop(10, to: self.sldrTime).leading(15).bottom(),
			self.lblDuration.pinTop(10, to: self.sldrTime).trailing(15).bottom(),
			
			self.vPlayerContainer.pinTop(21, to: self.vProgressContainer).leading().trailing().bottom(34),
			
			self.btnPlay.top().centerX().width(44).height(44).bottom(),
			self.btnPause.center(to: self.btnPlay).width(44).height(44),
			self.btnPrevious.width(44).height(44).pinRight(55, to: self.btnPlay).top(to: btnPlay),
			self.btnNext.width(44).height(44).pinLeft(55, to: self.btnPlay).top(to: btnPlay)
		)
		
		updateIsPlaying(false)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}	
	
	// MARK: - Methods
	func reset(music: Music, hasPrevious: Bool, hasNext: Bool) {
		self.music = music
		
		//Next/prev buttons state
		self.btnPrevious.isEnabled = hasPrevious
		self.btnNext.isEnabled = hasNext
		
		//Stop previous track
		stop()

		//Reset track position
		self.music.position = 0.0
		self.showPlayerTime(timeInterval: 0.0)
		
		//Show new track info
		self.showInfo(music)
		
		Analytics.logEvent(AnalyticsCustomEvents.Sound.selectMusic, parameters: [AnalyticsParameters.name : "\(music.author) - \(music.name)"])
		
		//Start new track
		self.start()
	}
	
	//NOTE: start stream or start local stored file
	func start() {
		
		var url: URL?
		//Play from downloaded file if exists
		if music.state.isDownloaded {
			let path = MahabharataCacheManager.documentsPath(fileType: .music, fileName: music.state.fileName)
			if FileManager.default.fileExists(atPath: path) {
				url = URL(fileURLWithPath: path)
			}
		}
		
		if url == nil {
			//Reset downloaded state if file is missing
			self.music.state.isDownloaded = false
			self.music.state.save()
			
			url = URL(string: MahabharataRequestManager.absoluteURL(relativeUrl: music.file))
		}
		
		if let url = url {
			self.isPlaying = true
			
			//Start progress
			self.lastMusicTime = 0
			startTimer()
			
			//Play sound
			if soundManager.currentTime.isNaN {
				soundManager.play(url: url)
			} else {
				soundManager.resume()
			}
			
			//Update buttons
			updateIsPlaying(true)

			//Get duration from file & show it
			music.duration = SoundManager.duration(url: url)
			showDuration(music.duration)
			
			self.delegate?.playerViewToggledPlay(self, isPlaying: true)
		}
	}
	
	func pause() {
		
		self.isPlaying = false
		
		soundManager.pause()
		timer.invalidate()
		updateIsPlaying(false)
		
		self.delegate?.playerViewToggledPlay(self, isPlaying: false)
	}
	
	func stop() {
		
		self.isPlaying = false
		
		soundManager.stop()
		timer.invalidate()
		updateIsPlaying(false)
		
		self.delegate?.playerViewToggledPlay(self, isPlaying: false)
	}
	
	//MARK: - Helper methods
	private func showInfo(_ music: Music) {
		self.lblTitle.text = music.name
		self.lblSubtitle.text = music.author
		
		//Reset length/position
		self.showPlayerTime(timeInterval: music.position)
		
		self.sldrTime.value = Float(music.position)
	}
	
	private func startTimer() {
		//Timer mode: timer fired on scrolling
		let timer = Timer(timeInterval: 1.0,
						  target: self,
						  selector: #selector(timer_UpdatePlayerTime),
						  userInfo: nil,
						  repeats: true)
		RunLoop.current.add(timer, forMode: .common)
		timer.tolerance = 0.1
		
		self.timer = timer
	}
	
	@objc
	private func timer_UpdatePlayerTime(_ sender: Any) {
		updatePlayerTime(soundManager.currentTime)
	}
	
	private func updatePlayerTime(_ currentTime: TimeInterval) {
//		print("---- updatePlayerTime", currentTime)
		let previousMusicTime = self.lastMusicTime
		self.lastMusicTime = currentTime
		
		self.showPlayerTime(timeInterval: min(currentTime, self.music.duration))
		
		//Check if music finished: music started && music time not changed (because player time at the end of track could be less than music duration)
		if currentTime > Double.ulpOfOne && abs(currentTime - previousMusicTime) <= Double.ulpOfOne {
			soundManagerDidCompletedTrack()
		}
	}

	private func showPlayerTime(timeInterval: TimeInterval) {
		self.lblCurrentTime.text = string(timeInterval:timeInterval)
		sldrTime.value = Float(timeInterval)
	}
	
	private func showDuration(_ timeInterval: TimeInterval) {
		sldrTime.isHidden = timeInterval.isNaN
		
		if !timeInterval.isNaN {
			sldrTime.maximumValue = Float(timeInterval)
		}
		
		self.lblDuration.text = string(timeInterval: timeInterval)
	}
	
	//TODO: ? more efficient time stamp
	private func string(timeInterval: TimeInterval) -> String {
		let timeIntervalInSeconds = Int(timeInterval.isNaN ? 0.0 : timeInterval)
		
		let hours = timeIntervalInSeconds / 3600
		let minutes = (timeIntervalInSeconds - Int(hours) * 3600) / 60
		let seconds = timeIntervalInSeconds % 60
		
		return hours > 0 ? String(format: "%.2d:%.2d:%.2d", Int(hours), Int(minutes), Int(seconds)) : String(format: "%.2d:%.2d", Int(minutes), Int(seconds))
	}
	
	private func updateIsPlaying(_ isPlaying: Bool) {
		btnPlay.isHidden = isPlaying
		btnPause.isHidden = !isPlaying
	}
	
	// MARK: - Actions:
	@objc private func btnPlay_Click(sender: UIButton) {
		start()
	}
	
	@objc private func btnPause_Click(sender: UIButton) {
		pause()
	}

	@objc private func btnPrevious_Click(sender: UIButton) {
		self.delegate?.playerViewDidPrevious(self)
	}
	
	@objc private func btnNext_Click(sender: UIButton) {
		self.delegate?.playerViewDidNext(self)
	}

	@objc private func slider_TimeChanged(_ sender: UISlider) {
		self.changedTimeInterval = TimeInterval(sender.value)
	}
	
	@objc private func slider_TimeSet(_ sender: UISlider) {
		//Prevent timer to reset slider
		timer.invalidate()
		
		//NOTE: SoundManager.shared.currentTime changes not immediately
		soundManager.seek(time: self.changedTimeInterval)

		//Show changed time
		updatePlayerTime(self.changedTimeInterval)
		
		//Resume auto changing slider - with delay for SoundManager seeked changedTimeInterval
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.startTimer()
		}
	}
	
	//MARK: - SoundManagerDelegate
	func soundManagerDidCompletedTrack() {
		stop()
		
		if self.btnNext.isEnabled {
			self.delegate?.playerViewDidNext(self)
		} else {
			self.music.position = 0
			self.showPlayerTime(timeInterval: 0)
		}
	}
}
