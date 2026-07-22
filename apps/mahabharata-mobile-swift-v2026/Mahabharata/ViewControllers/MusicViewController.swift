//
//  MusicViewController.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 09/02/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit
import AVFoundation

class MusicViewController: UIViewController {

	private var music: [Music] = [Music]()
	private var currentIndex: Int = -1
	
	private let vBackground = GradientView()
	
	fileprivate lazy var tblItems: UITableView = {
		let table = UITableView()
		table.backgroundColor = UIColor.clear
		table.separatorColor = UIColor.maroon1
		
		//Avoid extra space to edges on iPad
		table.cellLayoutMarginsFollowReadableWidth = false
		
		table.dataSource = self
		table.delegate = self
		
		table.rowHeight = UITableView.automaticDimension
		table.estimatedRowHeight = 60
		
		HeaderTableViewCell.register(for: table)
		MusicTableViewCell.register(for: table)
		
		table.tableFooterView = UIView()
		
		return table
	}()
	
	fileprivate lazy var vPlayer = PlayerView(music: Music(), delegate: self)

	private var cMusicTableBottom: NSLayoutConstraint!
	private var cPlayerBottom: NSLayoutConstraint!
	
	override func loadView() {
		self.view = UIView()
		self.view.backgroundColor = .white
		
		self.view.addSubview(self.vBackground)
		self.view.addSubview(self.tblItems)
		self.view.addSubview(self.vPlayer)
		
		self.vPlayer.isHidden = true
		
		self.cMusicTableBottom = self.tblItems.bottomItem == self.view.bottomItem
		self.cPlayerBottom = self.vPlayer.bottomItem == self.view.bottomItem

		activateConstraints(
			self.vBackground.edges(),
			self.tblItems.dockTop(),
			[self.cMusicTableBottom],
			self.vPlayer.pinTop(to: self.tblItems).leading().trailing()
		)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//For switch next track in background
		UIApplication.shared.beginReceivingRemoteControlEvents()
		
		MahabharataRequestManager.getMusic(success: { (music) in
			self.music = music
			self.tblItems.reloadData()
		}) { (err) in
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.isNavigationBarHidden = true
		
		//Make shared audio session playback because comics tab use another audio session category
		SoundManager.shared.setupSharedAudioSession(audioSessionCategory: AVAudioSession.Category.playback.rawValue)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		self.navigationController?.isNavigationBarHidden = false
	}
	
	//MARK: - Methods
	func playMusic(_ music: Music, hasPrevious: Bool, hasNext: Bool) {
		self.vPlayer.isHidden = false
		
		self.vPlayer.reset(music: music, hasPrevious: hasPrevious, hasNext: hasNext)
		
		//Show player if not already displayed bottom
		if !self.cPlayerBottom.isActive {
			deactivateConstraints(self.cMusicTableBottom!)
			
			activateConstraints(
				self.cPlayerBottom!
			)
		}
	}
	
	func downloadFileFor(music: Music) {
		
		let absoluteURL = MahabharataRequestManager.absoluteURL(relativeUrl: music.file)
		if let url = URL(string: absoluteURL) {
			
			let fileName = url.lastPathComponent
			let to = MahabharataCacheManager.documentsPath(fileType: .music, createIfNotExist: true, fileName: fileName)
			
			//Save state
			let musicState = music.state
			if musicState.downloadInfo == nil {
				musicState.downloadInfo = DownloadInfo()
			}
			musicState.save()
			
			//Update interface
			self.updateCells()
			
			BackgroundDownloader.shared.downloadFile(url: url, to: to, identifier: fileName, progress: { (bytes, total, fileName) in
				print("progress \(fileName): \(bytes)")
				
				musicState.downloadInfo?.bytesReceived = bytes
				musicState.downloadInfo?.bytesTotal = total
				musicState.save()
				
				//Update interface
				self.updateCells()
				
			}, completion: { (fileName) in
				print("completion \(fileName)")
				
				//Save state
				let musicState = music.state
				musicState.isDownloaded = true
				musicState.downloadInfo = nil
				musicState.fileName = fileName
				musicState.save()
				
				//Update interface
				self.updateCells()
			})
		}
	}
	
	func deleteFileFor(music: Music) {
		//Delete file
		let filePath = MahabharataCacheManager.documentsPath(fileType: .music, fileName: music.state.fileName)
		FileManager.delete(atPath: filePath)
		
		//Save state
		let state = music.state
		state.isDownloaded = false
		state.save()
	}
	
	func updateCells() {
		let visibleCells = self.tblItems.visibleCells
		
		for cell in visibleCells {
			if let cell = cell as? MusicTableViewCell {
				cell.update()
			}
		}
	}
}

//MARK: - UITableViewDataSource
extension MusicViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.music.count + 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 0 {
			let cell = tableView.dequeue(for: indexPath) as HeaderTableViewCell
			cell.fill(with: Local("Music.Title"))
			return cell
		} else {
			let music = self.music[indexPath.row - 1]
			let cell = tableView.dequeue(for: indexPath) as MusicTableViewCell
			cell.fill(with: music, number: indexPath.row, isPlaying: self.currentIndex == indexPath.row - 1 && vPlayer.isPlaying, delegate: self)
			
			return cell
		}
	}
}

//MARK: - UITableViewDelegate
extension MusicViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row == 0 {
			return
		} else {
			//Remove animation from current music cell
			for cell in self.tblItems.visibleCells {
				if let musicCell = cell as? MusicTableViewCell,
					let indexPath = self.tblItems.indexPath(for: cell),
					indexPath.row - 1 == self.currentIndex {

					musicCell.stopAnimation()
				}
			}

			//Set new current item
			self.currentIndex = indexPath.row - 1
			
			//Play selected item
			self.playMusic(self.music[currentIndex], hasPrevious: currentIndex > 0, hasNext: currentIndex < self.music.count - 1)
		}
	}
}

//MARK: - MusicTableViewCellDelegate
extension MusicViewController: MusicTableViewCellDelegate {
	func musicTableViewCellDidRead(_ cell: MusicTableViewCell, music: Music) {
		print("Read \(music.name)")
		
		if music.state.isDownloaded {
			if let index = self.music.firstIndex (where: { $0.id == music.id }) {
				self.currentIndex = index
				self.playMusic(self.music[currentIndex], hasPrevious: currentIndex > 0, hasNext: currentIndex < self.music.count - 1)
			}
		}
		else {
			self.downloadFileFor(music: music)
		}
	}
	
	func musicTableViewCellDidDelete(_ cell: MusicTableViewCell, music: Music) {
		print("Delete \(music.name)")
		
		AlertManager.present(message: String(format: Local("Music.AreYouSureToDelete"), music.name), buttons: [Local("Music.Yes"), Local("Music.No")], dismissBlock: { (code: Int) in
			if code == 0 {
				self.deleteFileFor(music: music)
				
				//Update interface
				self.updateCells()
			}
			else if code == 1 {
				return
			}
		})
	}
}

//MARK: - PlayerViewDelegate
extension MusicViewController: PlayerViewDelegate {
	func playerViewDidNext(_ view: PlayerView) {
		if let index = self.music.firstIndex (where: { $0.id == view.music.id }) {
			
			view.pause()
			
			if index + 1 <= self.music.count - 1 {
				
				self.currentIndex = index + 1
				view.reset(music: self.music[currentIndex], hasPrevious: true, hasNext: currentIndex < self.music.count - 1)
			}
		}
	}
	
	func playerViewDidPrevious(_ view: PlayerView) {
		if let index = self.music.firstIndex (where: { $0.id == view.music.id }),
			index - 1 >= 0 {
			
			view.pause()
			
			self.currentIndex = index - 1
			view.reset(music: self.music[currentIndex], hasPrevious: currentIndex > 0, hasNext: true)
		}
	}
	
	func playerViewToggledPlay(_ view: PlayerView, isPlaying: Bool) {
		if let cell = self.tblItems.visibleCells.first(where: { (cell) -> Bool in
			if let indexPath = self.tblItems.indexPath(for: cell) {
				return indexPath.row > 0 && view.music.id == self.music[indexPath.row - 1].id
			}
			return false
		}) {
			if let musicCell = cell as? MusicTableViewCell {
				if isPlaying {
					musicCell.playAnimation()
				} else {
					musicCell.stopAnimation()
				}
			}
		}
	}
}
