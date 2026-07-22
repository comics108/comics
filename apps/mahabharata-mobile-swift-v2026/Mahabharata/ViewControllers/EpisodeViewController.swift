//
//  EpisodeViewController.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/9/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import AVKit
import FirebaseAnalytics
import ComicsViewer

// Delegate to go to next episode; currently unused because netxbutton was replaced by Buy book button
protocol EpisodeViewControllerDelegate: AnyObject {
	func episodeViewControllerWillGoNext(_ controller: EpisodeViewController, goNextBook: Bool)
}

class EpisodeViewController: UIViewController {
	private var episode: Episode
	private var nextEpisode: Episode?
	private var isLast: Bool
	private var season: Season

	private var comics: Comics?
	
	weak var delegate: EpisodeViewControllerDelegate?
	
	private var bookPurchased: Bool {
		season.isPurchased
	}
	
	//Flag to display alert only after first viewDidAppear
	private var hasLoaded = false
	
	//For Google Analytics event
	private var hasRead = false
	
	private let vBackground = GradientView()
	private var svComics = ImageScrollView()
	
	private let vComicsTop = ComicsTopView(frame: .zero)
    private let vComicsBottom: ComicsBottomView = {
        ComicsBottomView(frame: .zero)
    }()
	private var vSoundState = SoundStateView(soundOn: !Settings.shared.soundOff)

	private var cTopPanelTop: NSLayoutConstraint!
	private var cBottomPanelBottom: NSLayoutConstraint!

	init(episode: Episode, nextEpisode: Episode?, isLast: Bool, season: Season, delegate: EpisodeViewControllerDelegate?) {
		self.episode = episode
		self.nextEpisode = nextEpisode
		self.isLast = isLast
		self.season = season
		self.delegate = delegate
		
		let to = FileManager.pathInDocuments(subdirectory: "Comics", fileName: self.episode.state.fileName)
		//let start = Date().timeIntervalSinceNow
		//ArchiveManager.shared.currentArchive = Archive(url: URL(fileURLWithPath: to), accessMode: .read)!
		ArchiveManager.shared.currentArchiveURL = URL(fileURLWithPath: to)
		//let end = Date().timeIntervalSinceNow
		//print("Interval: \(end-start)")
		
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		self.view = UIView()
		self.view.backgroundColor = .white
		self.view.clipsToBounds = true
		
		self.vComicsTop.delegate = self
		self.vComicsBottom.delegate = self
		self.svComics.scrollDelegate = self
		
		svComics.showsHorizontalScrollIndicator = false
		svComics.showsVerticalScrollIndicator = false
		
		self.view.addSubviews(self.vBackground, self.svComics)
		
		self.view.addSubview(self.vComicsTop)
		self.view.addSubview(self.vComicsBottom)
		self.vComicsBottom.isHidden = true //self.nextEpisode == nil
		
		self.view.addSubview(self.vSoundState)
		self.vSoundState.alpha = 0.0

		self.cTopPanelTop = self.vComicsTop.top().first!
		//Place bottom panel initially below screen
		self.cBottomPanelBottom = self.vComicsBottom.bottom(-UIScreen.main.bounds.size.height).first!
		
		activateConstraints(
			self.vBackground.edges(),
			self.svComics.edges(),
			
			[self.cTopPanelTop].leading().trailing(),
			[self.cBottomPanelBottom].leading().trailing(),
			
			self.vSoundState.top(192).centerX()
		)
	}
	
	//MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

		//Comics structure
		ArchiveManager.shared.comics { (comics) in
			//print("Parsed comics: \(comics)")
			
			self.comics = comics
			self.svComics.comics = comics
			
			self.vComicsTop.number = episode.order
			self.vComicsTop.name = episode.name
			self.vComicsTop.language = Settings.shared.language
			self.vComicsTop.delegate = self

			self.vComicsBottom.fill(episode: nextEpisode, bookPurchased: bookPurchased, buyTitle: season.getBuyTitle())
		}
		
		//Handle tap on scroll
		self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
		
		Analytics.logEvent(AnalyticsCustomEvents.Episode.open, parameters: [AnalyticsParameters.name : episode.name])
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		//Change music behaviour in background
		SoundManager.shared.setupSharedAudioSession(audioSessionCategory: AVAudioSession.Category.ambient.rawValue)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !hasLoaded {
			hasLoaded = true
			
			if episode.state.position > 0 {
				
				AlertManager.present(message: Local("Episode.ConfirmRestorePosition"), buttons: [Local("Episode.No"), Local("Episode.Yes")], dismissBlock: { (code) in
					if code == 1 {
						self.svComics.contentOffset = CGPoint(x: 0, y: self.episode.state.position)
					}
				})
			}
		}
		
		if !Settings.shared.soundOff {
			self.svComics.resumeSounds()
		}
	}
		
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		let scrollPercent = self.svComics.contentSize.height > 0 ? self.svComics.contentOffset.y / self.svComics.contentSize.height : 0
		Analytics.logEvent(AnalyticsCustomEvents.Episode.exit, parameters: [AnalyticsParameters.name : episode.name, AnalyticsParameters.scrollPercent: scrollPercent])

		//Store position in episode
		let episodeState = self.episode.state
		episodeState.position = self.svComics.contentOffset.y
		episodeState.save()
		
		self.svComics.pauseSounds()
	}
	
	//MARK - Recognizer
	@objc func tapped(_ sender: UIGestureRecognizer) {
		Settings.shared.soundOff = !Settings.shared.soundOff
		self.vSoundState.soundOn = !Settings.shared.soundOff
		
		//Turn off player volume; but sound continues
		self.svComics.mute(Settings.shared.soundOff)
		
		//Show and hide sound state icon: 0.2 sec appear, 1.0 sec show, 0.2 sec disappear
		UIView.animate(withDuration: 0.2) {
			self.vSoundState.alpha = 1.0
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
			UIView.animate(withDuration: 0.2) {
				self.vSoundState.alpha = 0.0
			}
		}
	}
}

//MARK: - ComicsTopViewDelegate
extension EpisodeViewController: ComicsTopViewDelegate {
	func comicsTopViewWillChangeLanguage(_ view: ComicsTopView, languageCode: Settings.Language) {
		Analytics.logEvent(AnalyticsCustomEvents.Language.changeLanguage, parameters: [AnalyticsParameters.language : languageCode.identifier])

		Settings.shared.language = languageCode
		self.svComics.reloadLanguage()
	}
}

//MARK: - ComicsBottomViewDelegate
extension EpisodeViewController: ComicsBottomViewDelegate {
	func comicsBottomViewWillBuy(_ view: ComicsBottomView) {
		if season.shouldPurchase && !season.isPurchased {
			view.blockUI()
			let seasonId = season.id
			InAppPurchaseManager.shared.purchaseProduct(with: season.product, success: { [weak self] (_, _) in
				// Mark purchased permanently in settings. Purchase could be completed after user closed this screen; provides season state for all screens
				Season.markPurchased(seasonId)
				NotificationCenter.default.post(name: .seasonPurchased, object: nil, userInfo: [Season.NotificationConstants.userInfoIdKey: seasonId])
				
				guard let self = self else { return }
				DispatchQueue.main.async {
					view.unblockUI()
					self.vComicsBottom.fillBuyButton(self.season.getBuyTitle(), bookPurchased: true)
				}
			}) { (error: InAppError) in
				print("not purchased", error.description)
				DispatchQueue.main.async {
					view.unblockUI()
				}
			}
		}
	}
}

//MARK: - ImageScrollViewDelegate
extension EpisodeViewController: ImageScrollViewDelegate {
	func imageScrollViewDidScroll(_ view: ImageScrollView) {
		//Place top panel partially visible on top or outside screen
		self.cTopPanelTop.constant = max(0 - view.contentOffset.y, -self.vComicsTop.frame.size.height)
		
		//Place bottom panel below screen or partially visible when in bottom
		self.cBottomPanelBottom.constant = min(UIScreen.main.bounds.size.height, -self.view.frame.size.height + view.contentSize.height - view.contentOffset.y)

		//TODO: probably log comics opened after it was scrolled at least one screen
//		if !hasRead && view.contentOffset.y == view.frame.size.height {
//			hasRead = true
//			Analytics.logEvent(AnalyticsCustomEvents.Episode.open, parameters: [AnalyticsParameters.name : episode.name])
//		}
	}
}
