//
//  SeasonsViewController.swift
//  Mahabharata
//
//  Created by Roman Developer on 10/6/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import SafariServices

enum LoadStatus {
    case loaded, loading
}

protocol DownloadFileForEpisodeDelegate: AnyObject {}

extension DownloadFileForEpisodeDelegate {
    func downloadFileFor(episode: Episode) {
        guard !String.isNilOrWhiteSpace(episode.file) else { return }
        Analytics.logEvent(
            AnalyticsCustomEvents.Episode.download,
            parameters: [
                AnalyticsParameters.name: episode.name,
            ]
        )
        let absoluteURL = MahabharataRequestManager.absoluteURL(relativeUrl: episode.file)
        guard let url: URL = .init(string: absoluteURL) else { return }
        let fileName = url.lastPathComponent
        let destination = FileManager.pathInDocuments(
            subdirectory: "Comics",
            fileName: fileName
        )
        BackgroundDownloader
            .shared
            .downloadFile(
                item: episode,
                to: destination,
                identifier: fileName
            )
    }
}

protocol SeasonsViewControllerDelegate: AnyObject {
    func ctaClicked(_ cell: SeasonsScreenEpisodeCollectionViewCell)
}

class SeasonsViewController: UIViewController {
    var state: ViewState = .empty {
        didSet {
            switch state.loadStatus {
            case .loaded: updataAppearance()
            case .loading: break
            }
        }
    }
    var seasonsCache: SeasonsCachableDelegate?
    
    private let gradientBackground = GradientView()
    private lazy var header: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var headerTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .yellow1
        label.font = .regular(ofSize: 16)
        return label
    }()

    private lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "header-image")
        return imageView
    }()

    private lazy var seasonsTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        //table.separatorColor = UIColor.divider
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 56
        SeasonsHeaderTableViewCell.register(for: tableView)
        SeasonTableViewCell.register(for: tableView)
        //Avoid extra space to edges on iPad
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.tableFooterView = UIView()
        return tableView
    }()

    private lazy var episodesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView.init(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            SeasonsScreenEpisodeCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonsScreenEpisodeCollectionViewCell.reuseIdentifier
        )
        collectionView.backgroundColor = .gradientEnd
        return collectionView
    }()

    private lazy var linksBanner: LinksBanner = {
        let banner = LinksBanner(frame: .zero)
        return banner
    }()

    // MARK: - Overrides

    override func loadView() {
        setupViews()
        activateConstraints(
            header
                .top().leading().trailing()
                .height(142),
            headerImageView
                .width(244).height(60)
                .top(40)
                .centerX(),
            headerTitleLabel
                .bottom(12)
                .centerX(),

            episodesCollectionView
                .pinTop(to: header)
                .leading().trailing()
                .height(142),

            seasonsTableView
                .pinTop(16, to: episodesCollectionView)
                .leading().trailing().bottom(36),

            linksBanner
                .leading().trailing().bottom().height(80),

            gradientBackground
                .edges()
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        BackgroundDownloader.shared.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
        BackgroundDownloader.shared.delegate = nil
    }
}

// MARK: - Setup UI

extension SeasonsViewController {

    private func setupViews() {
        setupView()
        setupGradientBackground()
        setupSeasonsTableView()
        setupHeader()
        setupHeaderImageView()
        setupHeaderTitleLabel()
        setupEpisodesCollectionView()
        setupLinksBanner()
    }

    private func setupView() {
        view = UIView()
        view.backgroundColor = .white
    }

    private func setupGradientBackground() {
        view.addSubview(gradientBackground)
    }

    private func setupSeasonsTableView() {
        view.addSubview(seasonsTableView)
    }

    private func setupHeader() {
        view.addSubview(header)
    }

    private func setupHeaderTitleLabel() {
        header.addSubview(headerTitleLabel)
        headerTitleLabel.text = self.state.headerTitle
    }

    private func setupHeaderImageView() {
        header.addSubview(headerImageView)
    }

    private func setupEpisodesCollectionView() {
        view.addSubview(episodesCollectionView)
    }

    private func setupLinksBanner() {
        linksBanner.delegate = self
        view.addSubview(linksBanner)
    }
}

// MARK: - Update UI

extension SeasonsViewController {

    private func updataAppearance() {
        DispatchQueue.main.async {
            self.view.hideActivityIndicator()
            self.seasonsTableView.reloadData()
            self.episodesCollectionView.reloadData()
        }
    }
}

// MARK: - Methods

extension SeasonsViewController {

    private func loadData() {
        view.showActivityIndicator()

        MahabharataRequestManager.getSeasons(success: { [weak self] seasons in
            guard let vc = self else { return }
            vc.state.seasonsSource = .server
            vc.state.seasons = seasons
            vc.seasonsCache?.cache(seasons) { [weak self] result in
                guard self != nil else { return }
                switch result {
                case .success(_):
                    print("##### seasons loaded from cache")
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            
            // Load prices. Prices are not displayed but are passed to episodes list
            vc.loadProducts { [weak self] in
                guard let vc = self else { return }
                vc.state.loadStatus = .loaded
            }
        }) { error in
            self.view.hideActivityIndicator()
        }
        loadSeasonsFromCacheIfNeeded()
    }
    
    private func loadSeasonsFromCacheIfNeeded() {
        DispatchQueue
            .global(qos: .userInteractive)
            .asyncAfter(deadline: state.delay) { [weak self] in
                guard let self = self else { return }
                if self.state.seasonsSource == .server { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let seasonsCache = self.seasonsCache else { return }
                    seasonsCache.cached({ [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let seasons):
                            self.state.seasonsSource = .cache
                            self.state.seasons = seasons
                            self.state.loadStatus = .loaded
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    })
                }
            }
    }

    private func loadProducts(_ completion: @escaping (() -> Void)) {
        //Load prices for not bought products
        let productIds = state.seasons.filter({ !String.isNilOrWhiteSpace($0.product) && !$0.isPurchased}).map { $0.product }
        print("productIds \(productIds.count)")
        if productIds.count > 0 {
            InAppPurchaseManager.shared.getProducts(for: productIds, success: { [weak self] products in
                guard let self = self else { return }
                for product in products {
                    //Calculate localized price with currency
                    if let index = self.state.seasons.firstIndex(where: { $0.product == product.productIdentifier }) {
                        // Do not use product.formattedPrice for efficiency: use single formatter for controller instead of creating formatters for each product
                        self.state.formatter.locale = product.priceLocale
                        self.state.seasons[index].price = self.state.formatter.formatCurrency(product.price)
                    }
                }
                completion()
            }) { error in
                print("Error: \(error)")
                completion()
            }
        } else {
            completion()
        }
    }

    private func getBuyTitle(index: Int) -> String {
        Local("Episodes.ReadNow")
    }
}

// MARK: - UITableViewDataSource

extension SeasonsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.seasonsToShow.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        seasonCell(at: indexPath)
    }
}

// MARK: - UITableViewDelegate

extension SeasonsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard state.seasonsToShow[indexPath.row].episodes.count > 0 else { return }
        presentSeason(indexPath: indexPath)
    }
}

// MARK: - UICollectionViewDataSource

extension SeasonsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        state.episodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SeasonsScreenEpisodeCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? SeasonsScreenEpisodeCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        cell.state = .init(
            episode: state.episodes[indexPath.row],
            cta: Local("Episodes.ReadNow")
        )
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SeasonsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        .init(
            width: 186,
            height: 144
        )
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}

// MARK: - UICollectionViewDelegate

extension SeasonsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SeasonsScreenEpisodeCollectionViewCell else { return }
        ctaClicked(cell)
    }
}

extension SeasonsViewController {

    private func seasonCell(at indexPath: IndexPath) -> UITableViewCell {
        let season = state.seasonsToShow[indexPath.row]
        let cell = seasonsTableView.dequeue(for: indexPath) as SeasonTableViewCell
        cell.onClick = { [weak self] in
            guard let vc = self else { return }
            vc.handleCtaClick(at: indexPath)
        }
        cell.state = SeasonTableViewCell.ViewState(
            ctaButtonStyle: ctaButtonStyle(indexPath),
            season: season,
            ctaTitle: getBuyTitle(index: indexPath.row)
        )
        return cell
    }

    private func presentSeason(indexPath: IndexPath) {
        guard let navigationController = navigationController else { return }

        //NOTE: table has non-data (title) first cell
        let season = self.state.seasonsToShow[indexPath.row]
        //First episode of next book
        let nextEpisode = indexPath.row < self.state.seasonsToShow.count ? self.state.seasonsToShow[indexPath.row].episodes.first : nil

        //Open book
        let episodesViewController = EpisodesViewController(season: season, nextEpisode: nextEpisode, delegate: self)
        navigationController.pushViewController(episodesViewController, animated: true)
    }

    private func ctaButtonStyle(_ indexPath: IndexPath) -> SeasonTableViewCell.CtaButtonStyle {
        .usual
    }
}

extension SeasonsViewController {

    private func handleCtaClick(at indexPath: IndexPath) {
        presentSeason(indexPath: indexPath)
    }
}

// MARK: - EpisodesViewControllerDelegate

extension SeasonsViewController: EpisodesViewControllerDelegate {
    func episodesViewControllerDidGoNext(_ controller: EpisodesViewController, currentSeason: Season) {
        if let index = self.state.seasons.firstIndex(where: { $0.id == currentSeason.id }),
           index < self.state.seasons.count - 1 {

            //First episode of next book
            let nextEpisode = index < self.state.seasons.count - 1 ? self.state.seasons[index + 1].episodes.first : nil

            self.navigationController?.popToViewController(self, animated: false)
            self.navigationController?.pushViewController(EpisodesViewController(season: self.state.seasons[index + 1], nextEpisode: nextEpisode, delegate: self), animated: true)
        }
    }
}

// MARK: - BackgroundDownloaderDelegate

extension SeasonsViewController: BackgroundDownloaderDelegate {
    func backgroundDownloader(_ downloader: BackgroundDownloader, progressChangedFor item: DownloadItem, bytes: Int64, total: Int64, to path: String) {
        guard let episode = item as? Episode else { return }

        //Save state
        let episodeState = episode.state
        if episodeState.downloadInfo == nil {
            episodeState.downloadInfo = DownloadInfo()
        }
        episodeState.downloadInfo?.bytesReceived = bytes
        episodeState.downloadInfo?.bytesTotal = total
        episodeState.save()

        updateCells()
    }

    func backgroundDownloader(downloader: BackgroundDownloader, didCompletedFor item: DownloadItem, to: String) {
        guard let episode = item as? Episode else { return }
        print("Download completed \(episode.order) \(episode.name)")

        //Save state
        let episodeState = episode.state
        episodeState.isDownloaded = true
        episodeState.downloadInfo = nil
        episodeState.version = episode.version
        episodeState.fileName = (to as NSString).lastPathComponent
        episodeState.isUnpacking = true
        episodeState.save()

        //Update interface: unpacking
        updateCells()

        //Unpack
        //Async to update button before unpack
        DispatchQueue.main.async {
            guard let folderName = FileManager.fileNameWithoutExtension(from: episodeState.fileName) else { return }
            let atURL = URL(fileURLWithPath: to)
            let to2 = FileManager.pathInDocuments(subdirectory: "Comics", fileName: folderName)
            let toURL = URL(fileURLWithPath: to2, isDirectory: true)
            print("At: \(atURL), to: \(toURL)")
            let success = SSZipArchive.unzipFile(
                atPath: to,
                toDestination: to2,
                preserveAttributes: true,
                overwrite: true,
                nestedZipLevel: 2,
                password: nil,
                error: nil,
                delegate: nil,
                progressHandler: nil,
                completionHandler: nil
            )
            if success != false {
                print("Unzip succeed")

                //Remove archive
                FileManager.delete(atPath: to)

                //Write unpacked files directory as filename
                let episodeState = episode.state
                episodeState.fileName = folderName
                episodeState.isUnpacking = false
                episodeState.save()
            } else {
                print("Unzip failed")

                //Mark episode not unpacking
                let episodeState = episode.state
                episodeState.isUnpacking = false
                episodeState.save()

                return
            }

            //Update interface
            self.updateCells()
        }
    }
}

// MARK: - SeasonsViewControllerDelegate

extension SeasonsViewController: SeasonsViewControllerDelegate {
    func ctaClicked(_ cell: SeasonsScreenEpisodeCollectionViewCell) {
        guard let indexPath = episodesCollectionView.indexPath(for: cell) else { return }
        let episode = state.episodes[indexPath.item]
        print("Read \(episode.name) from '\(episode.file)'")
        let episodeState = episode.state
        if episodeState.isDownloaded {
            present(episode)
        } else {
            downloadFileFor(episode: episode)
        }
    }
}

extension SeasonsViewController {
    private func present(_ episode: Episode) {
        // Open downloaded episode
        guard let index = state.episodes.firstIndex(where: { $0.id == episode.id }),
              let season = state.season(of: episode),
              let navigationController = navigationController else { return }
        // Next episode in current season or 1st episode in next book
        let nextEpisode = index < state.episodes.count - 1 ? state.episodes[index + 1] : state.nextEpisode
        let episodeViewController = EpisodeViewController(
            episode: episode,
            nextEpisode: nextEpisode,
            isLast: index == state.episodes.count - 1,
            season: season,
            delegate: self
        )
        navigationController.pushViewController(episodeViewController, animated: true)
    }
}

extension SeasonsViewController {
    func updateCells() {
        for cell in episodesCollectionView.visibleCells {
            guard let cell = cell as? SeasonsScreenEpisodeCollectionViewCell,
                  let indexPath = episodesCollectionView.indexPath(for: cell),
                  let season = state.season(of: state.episodes[indexPath.item]) else { continue }
            print("update cell for \(indexPath.item). \(state.episodes[indexPath.item].name)")
            cell.update(
                episode: state.episodes[indexPath.item],
                bookPurchased: season.isPurchased
            )
        }
    }
}

// MARK: - EpisodeViewControllerDelegate

extension SeasonsViewController: EpisodeViewControllerDelegate {
    func episodeViewControllerWillGoNext(_ controller: EpisodeViewController, goNextBook: Bool) {
        // MARK: - TODO
    }
}

// MARK: - DownloadFileForEpisodeDelegate

extension SeasonsViewController: DownloadFileForEpisodeDelegate {}

// MARK: - LinksBannerDelegate

extension SeasonsViewController: LinksBannerDelegate {
    func topButtonClicked() {
        let animator = UIViewPropertyAnimator(
            duration: 0.2,
            curve: .easeIn
        ) { [weak self] in
            guard let vc = self else { return }
            switch vc.linksBanner.state.position {
            case .open:
                vc.linksBanner.transform = CGAffineTransform(translationX: 0, y: 40)
            case .close:
                vc.linksBanner.transform = .identity
            }
        }
        animator.addAnimations { [weak self] in
            guard let vc = self else { return }
            switch vc.linksBanner.state.position {
            case .open:
                vc.linksBanner.container.alpha = 0
            case .close:
                vc.linksBanner.container.alpha = 1
            }
        }
        animator.addCompletion { [weak self] position in
            guard let vc = self, position == .end else { return }
            vc.linksBanner.state.toggle()
        }
        animator.startAnimation()
    }

    func linkClicked(_ url: URL) {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        let vc = SFSafariViewController(url: url, configuration: config)
        present(vc, animated: true)
    }
}



//MARK: - SeasonTableViewCellDelegate
//
//extension SeasonsViewController: SeasonTableViewCellDelegate {
//	func seasonTableViewCellDelegateSelectedBuy(_ cell: SeasonTableViewCell) {
//		if let indexPath = tableView.indexPath(for: cell) {
//            let season = state.seasons[indexPath.row - 1]
//			if season.shouldPurchase && !season.isPurchased {
//				cell.blockUI()
//				InAppPurchaseManager.shared.purchaseProduct(with: season.product, success: { [weak self] (_, _) in
//					guard let self = self else { return }
//					// Mark purchased permanently in settings. Purchase could be completed after user closed this screen.
//					Season.markPurchased(season.id)
//					NotificationCenter.default.post(name: .seasonPurchased, object: nil, userInfo: [Season.NotificationConstants.userInfoIdKey: season.id])
//					DispatchQueue.main.async {
//						cell.unblockUI()
//						cell.setupCtaButton(self.getBuyTitle(index: indexPath.row - 1))
//					}
//				}) { (error: InAppError) in
//					print("not purchased", error.description)
//					DispatchQueue.main.async {
//						cell.unblockUI()
//					}
//				}
//			} else {
//				// TODO: remove after debug
//				DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//					NotificationCenter.default.post(name: .seasonPurchased, object: nil, userInfo: [Season.NotificationConstants.userInfoIdKey: season.id])
//				}
//			}
//		}
//	}
//}
