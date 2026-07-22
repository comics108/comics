//
//  EpisodesViewController.swift
//  Mahabharata
//
//  Created by Roman Developer on 10/17/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import SafariServices

extension Notification.Name {
    // Name of Notification center event
    static let seasonPurchased = Notification.Name(rawValue: "seasonPurchased")
    // Episodes of certain season are restored
    static let seasonEpisodesRestored = Notification.Name(rawValue: "episodesRestored")
}

protocol EpisodesViewControllerDelegate: AnyObject {
    func episodesViewControllerDidGoNext(_ controller: EpisodesViewController, currentSeason: Season)
}

extension EpisodesViewController {
    struct ViewState: Equatable {
        let formatter: NumberFormatter = .currencyFormatter()
        var season: Season
        /// First episode of next book; is displayed in the bottom
        var nextEpisode: Episode?
    }
}

extension EpisodesViewController.ViewState {
    static var empty: EpisodesViewController.ViewState {
        .init(
            season: Season(
                id: Int.min,
                name: "",
                image: "",
                product: "",
                order: 0,
                episodes: []
            ),
            nextEpisode: nil
        )
    }
}

class EpisodesViewController: UIViewController {
    private let youtubeLinksContainer: YoutubeLinksContainer = .init()
    
    weak var delegate: EpisodesViewControllerDelegate?
    var state: ViewState = .empty {
        didSet {
            guard oldValue != state else { return }
            // updateUI
        }
    }

    deinit {
        print("deinit")
        NotificationCenter.default.removeObserver(self)
    }

    //MARK: - init

    init(season: Season, nextEpisode: Episode?, delegate: EpisodesViewControllerDelegate?) {
        state = .init(season: season, nextEpisode: nextEpisode)
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let vBackground = GradientView()

    fileprivate lazy var episodesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.isPagingEnabled = true
        collectionView.clipsToBounds = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        EpisodeCollectionViewCell.register(for: collectionView)
        return collectionView
    }()

    private let btnPrevious = UIButton(target: nil, selector: nil, type: .custom, iconName: "icon_left.png")
    private let btnNext = UIButton(target: nil, selector: nil, type: .custom, iconName: "icon_right.png")
    private let btnSubscribe: UIButton = {
        let button =  UIButton(type: .custom)
            .color(.yellow1)
            .font(UIFont.semibold(ofSize: 14))
            .corners(4)
            .borderColor(.yellow1)
            .title(Local("Episodes.Subscribe"))
        button.isHidden = true
        return button
    }()
    private let btnBuy: UIButton = {
        let button = UIButton.greenButton()
        button.isHidden = true
        return button
    }()

    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .white
        self.view.clipsToBounds = true

        view.addSubviews(vBackground, episodesCollectionView, btnPrevious, btnNext, btnBuy, btnSubscribe)

        self.btnPrevious.addTarget(self, action: #selector(btnPrevious_Click(_:)), for: .touchUpInside)
        self.btnNext.addTarget(self, action: #selector(btnNext_Click(_:)), for: .touchUpInside)
        self.btnBuy.addTarget(self, action: #selector(btnBuy_Click(_:)), for: .touchUpInside)
        self.btnSubscribe.addTarget(self, action: #selector(btnSubscribe_Click(_:)), for: .touchUpInside)

        let sidePadding = (UIScreen.main.bounds.width - EpisodeCollectionViewCell.pageWidth) / 2
        activateConstraints(
            self.vBackground.edges(),
            self.episodesCollectionView.edges(top: 0, left: sidePadding, bottom: 65, right: sidePadding)
        )

        //12 = half of difference from button size and visible arrow size
        let arrowPadding = (UIScreen.main.bounds.width - EpisodeCollectionViewCell.episodeCoverSize.width) / 2 - EpisodeCollectionViewCell.visualSpan - 38 + 12

        //Vertical space from image to real border of button
        let arrowVerticalPaddingBorder: CGFloat = 0.5 * (38 - 18)
        let buttonWidth = UIDevice.isIPad ? 0.5 * EpisodeCollectionViewCell.episodeCoverSize.width : EpisodeCollectionViewCell.episodeCoverSize.width

        activateConstraints(
            btnPrevious.leading(arrowPadding),
            [self.btnPrevious.topItem == self.episodesCollectionView.centerYItem - 0.5 * EpisodeCollectionViewCell.episodeCoverSize.height - arrowVerticalPaddingBorder],
            btnPrevious.width(38).height(38),

            btnNext.trailing(arrowPadding),
            btnNext.top(to: btnPrevious),
            btnNext.width(38).height(38),

            btnSubscribe.height(35).centerX().bottom(30).width(buttonWidth),
            btnBuy.height(35).centerX().pinBottom(20, to: btnSubscribe).width(buttonWidth)
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()

        NotificationCenter.default.addObserver(self, selector: #selector(seasonPurchasedNotification(_:)), name: .seasonPurchased, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(seasonEpisodesRestoredNotification(_:)), name: .seasonEpisodesRestored, object: nil)

        //Show/hide arrow buttons
        let currentRow = 0
        self.btnPrevious.isHidden = currentRow == 0
        self.btnNext.isHidden = currentRow >= state.season.episodes.count - 1
        fillBuyButton(state.season.getBuyTitle())

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollViewDidScroll(self.episodesCollectionView)
            self.scrollViewDidEndDecelerating(self.episodesCollectionView)
        }

        loadProducts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BackgroundDownloader.shared.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BackgroundDownloader.shared.delegate = nil
    }

    // MARK: - Methods
    func loadProducts() {
        //Load prices for not bought products
        var productIds = state.season.episodes.filter({ !String.isNilOrWhiteSpace($0.product) && !$0.state.isPurchased}).map { $0.product }
        // If season products were not downloaded at first page (because of some error)
        if state.season.shouldPurchase && state.season.price.isEmpty {
            productIds.append(state.season.product)
        }
        guard !productIds.isEmpty else { return }

        InAppPurchaseManager.shared.getProducts(for: productIds, success: { [weak self] (products) in
            guard let self = self else { return }
            for product in products {
                //Calculate localized price with currency
                if let index = self.state.season.episodes.firstIndex(where: { $0.product == product.productIdentifier }) {
                    // Do not use product.formattedPrice for efficiency: use single formatter for controller instead of creating formatters for each product
                    self.state.formatter.locale = product.priceLocale
                    self.state.season.episodes[index].price = self.state.formatter.formatCurrency(product.price)
                    print("price: \(self.state.season.episodes[index].price)")
                }
                // For safety, if season price could not be calculated at first page
                if self.state.season.product == product.productIdentifier {
                    // Do not use product.formattedPrice for efficiency: use single formatter for controller instead of creating formatters for each product
                    self.state.formatter.locale = product.priceLocale
                    self.state.season.price = self.state.formatter.formatCurrency(product.price)
                    print("price: \(self.state.season.price)")
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                // Reload all cells because prices were calculated
                self.episodesCollectionView.reloadData()
            }
        }) { (error) in
            print("Error: \(error)")
        }

    }

    func fillBuyButton(_ title: String) {
        //btnBuy.isHidden = title.isEmpty
        btnBuy.setTitle(title, for: .normal)
    }

    func seasonPurchased(id: Int) {
        fillBuyButton(state.season.getBuyTitle())

        // NOTE: season.isPurchased = true is not needed because this property is set in Settings before the notification posted
        // Update all created cells
        let visibleItems = episodesCollectionView.indexPathsForVisibleItems
        episodesCollectionView.reloadItems(at: visibleItems)
        // Adjust cell transform
        scrollViewDidScroll(episodesCollectionView)
    }

    // MARK: - Helper methods

    func deleteFileFor(episode: Episode) {
        Analytics.logEvent(AnalyticsCustomEvents.Episode.Delete, parameters: [AnalyticsParameters.name : episode.name])

        //Delete file
        let filePath = FileManager.pathInDocuments(subdirectory: "Comics", fileName: episode.state.fileName)
        FileManager.delete(atPath: filePath)

        //Save state
        let episodeState = episode.state
        episodeState.isDownloaded = false
        episodeState.save()
    }

    func updateCells() {
        for cell in episodesCollectionView.visibleCells {
            guard let indexPath = episodesCollectionView.indexPath(for: cell), let cell = cell as? EpisodeCollectionViewCell else { continue }
            print("update cell for \(indexPath.item). \(state.season.episodes[indexPath.item].name)")
            cell.update(
                episode: state.season.episodes[indexPath.item],
                bookPurchased: state.season.isPurchased
            )
        }
    }

    func updateCell(_ cell: EpisodeCollectionViewCell, index: Int) {
        cell.update(episode: state.season.episodes[index], bookPurchased: state.season.isPurchased)
    }

    private var isReloading = false

    //MARK: - Purchase notification
    @objc
    func seasonPurchasedNotification(_ notification: Notification?) {
        guard let info = notification?.userInfo else {
            return
        }
        if let seasonId = info[Season.NotificationConstants.userInfoIdKey] as? Int, state.season.id == seasonId {
            seasonPurchased(id: seasonId)
        }
    }

    @objc
    func seasonEpisodesRestoredNotification(_ notification: Notification?) {
        let visibleItems = episodesCollectionView.indexPathsForVisibleItems
        episodesCollectionView.reloadItems(at: visibleItems)
    }

    //MARK: - Handlers
    @objc
    func btnBack_Click(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    //MARK: - Navigation
    @objc
    func btnPrevious_Click(_ sender: UIButton) {
        goPrevious()
    }

    func goPrevious() {
        guard let previousIndexPath = episodesCollectionView.indexPathsForVisibleItems.min() else { return }
        scroll(episodesCollectionView, to: previousIndexPath)
        animate(episodesCollectionView)
    }

    @objc
    func btnNext_Click(_ sender: UIButton) {
        goNext()
    }

    func goNext() {
        guard let nextIndexPath = episodesCollectionView.indexPathsForVisibleItems.max() else { return }
        scroll(episodesCollectionView, to: nextIndexPath)
        animate(episodesCollectionView)
    }

    private func animate(_ collectionView: UICollectionView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.scrollViewDidEndDecelerating(collectionView)
        }
    }

    private func scroll(_ collectionView: UICollectionView, to indexPath: IndexPath) {
        self.episodesCollectionView.isPagingEnabled = false
        self.episodesCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        self.episodesCollectionView.isPagingEnabled = true
    }

    @objc
    func btnBuy_Click(_ sender: UIButton) {
        if state.season.shouldPurchase && !state.season.isPurchased {
            btnBuy.showActivityIndicator()
            let seasonId = state.season.id
            InAppPurchaseManager.shared.purchaseProduct(with: state.season.product, success: { [weak self] (_, _) in
                // Mark purchased permanently in settings. Purchase could be completed after user closed this screen; provides season state for all screens
                Season.markPurchased(seasonId)
                NotificationCenter.default.post(name: .seasonPurchased, object: nil, userInfo: [Season.NotificationConstants.userInfoIdKey: seasonId])

                guard let self = self else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.btnBuy.hideActivityIndicator()
                    self.seasonPurchased(id: self.state.season.id)
                }
            }) { (error: InAppError) in
                print("not purchased", error.description)
                DispatchQueue.main.async {
                    self.btnBuy.hideActivityIndicator()
                }
            }
        }
    }

    //MARK - Other handlers
    @objc
    func btnSubscribe_Click(_ sender: UIButton) {
        if let url = URL(string: "http://mahabharata.pro/subscribe") {
            UIApplication.openUrl(url)
        }
    }

}

extension EpisodesViewController {

    private func setupViews() {
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        setupNavigationTitle()
        setupLeftBarButtonItem()
    }

    private func setupNavigationTitle() {
        let label = UILabel(
            frame: CGRect(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 44
            )
        )
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 2
        label.font = UIFont.regular(ofSize: 18)
        label.textColor = .yellow1
        label.text = state.season.name.fixNewLine()
        label.sizeToFit()
        label.textAlignment = .center
        navigationItem.titleView = label
    }

    private func setupLeftBarButtonItem() {
        self.navigationItem.leftBarButtonItem = self.barButton(withImage: "icon_back", action: #selector(btnBack_Click(_:)))
    }
}

// MARK: - UICollectionViewDataSource
extension EpisodesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.state.season.episodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let episode = self.state.season.episodes[indexPath.row]
        print("cellForItemAt \(indexPath.item). \(episode.name)")
        let cell = collectionView.dequeue(for: indexPath) as EpisodeCollectionViewCell
        cell.fill(with: episode, bookPurchased: state.season.isPurchased, delegate: self)
        cell.state.youtubeLink = youtubeLinksContainer.youtubeLink(state.season.id, episode.id)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension EpisodesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return EpisodeCollectionViewCell.cellSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let sidePadding = EpisodeCollectionViewCell.spaceOverlapCount * EpisodeCollectionViewCell.visualSpan / 2
        return UIEdgeInsets(top: 0, left: -sidePadding, bottom: 0, right: -sidePadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let sidePadding = EpisodeCollectionViewCell.spaceOverlapCount * EpisodeCollectionViewCell.visualSpan
        return -sidePadding
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - UIScrollViewDelegate
extension EpisodesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isReloading else { return }
        let visibleCells = self.episodesCollectionView.visibleCells
        let sidePadding = (UIScreen.main.bounds.size.width - EpisodeCollectionViewCell.cellSize.width) / 2

        for cell in visibleCells {
            if let cell = cell as? EpisodeCollectionViewCell {
                let point = cell.convert(CGPoint(x: -sidePadding, y: 0), to: self.view)
                let ratio = point.x / EpisodeCollectionViewCell.pageWidth
                cell.setTransform(ratio: ratio)
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleCells = self.episodesCollectionView.visibleCells
        let sidePadding = (UIScreen.main.bounds.size.width - EpisodeCollectionViewCell.cellSize.width) / 2

        for cell in visibleCells {
            let point = cell.convert(CGPoint(x: -sidePadding, y: 0), to: self.view)
            let ratio = round(point.x / EpisodeCollectionViewCell.pageWidth)
            cell.isUserInteractionEnabled = (ratio == 0)
            if ratio == 0 {
                if let row = self.episodesCollectionView.indexPath(for: cell)?.row {
                    //Show/hide arrow buttons
                    self.btnPrevious.isHidden = row == 0
                    self.btnNext.isHidden = row >= self.state.season.episodes.count - 1
                }
            }
        }
    }
}

// MARK: - EpisodeCollectionViewCellDelegate
extension EpisodesViewController: EpisodeCollectionViewCellDelegate {

    func episodeCollectionViewCellDidRead(cell: EpisodeCollectionViewCell) {
        guard let indexPath = episodesCollectionView.indexPath(for: cell) else { return }
        let episode = state.season.episodes[indexPath.item]
        print("Read \(episode.name) from '\(episode.file)'")

        //Use variable not to retrieve form UserDefaults
        let episodeState = episode.state

        //If episode is not free, not bought and is not downloading, buy it
        //        if notFreeNotBoughtNotDownloaded(episode: episode, episodeState: episodeState, season: season) {
        //            handleNotFreeNotBoughtNotDownloadedCase(episode: episode, cell: cell, indexPath: indexPath)
        //            return
        //        }

        // Purchased or free
        if episodeState.isDownloaded {
            present(episode)
        } else {
            // Get files from our server
            downloadFileFor(episode: episode)
        }
    }

    func episodeCollectionViewCellDidUpdate(cell: EpisodeCollectionViewCell) {
        guard let indexPath = episodesCollectionView.indexPath(for: cell) else { return }
        let episode = state.season.episodes[indexPath.item]
        Analytics.logEvent(AnalyticsCustomEvents.Episode.update, parameters: [AnalyticsParameters.name : episode.name, AnalyticsParameters.oldVersion: episode.state.version, AnalyticsParameters.newVersion: episode.version])

        self.deleteFileFor(episode: episode)

        self.downloadFileFor(episode: episode)
    }

    func episodeCollectionViewCellDidDelete(cell: EpisodeCollectionViewCell) {
        guard let indexPath = episodesCollectionView.indexPath(for: cell) else { return }
        let episode = state.season.episodes[indexPath.item]

        AlertManager.present(message: String(format: Local("Episodes.AreYouSureToDelete"), episode.name), buttons: [Local("Episodes.Yes"), Local("Episodes.No")], dismissBlock: {(buttonIndex: Int) in
            if buttonIndex == 0 {
                self.deleteFileFor(episode: episode)

                //Update interface
                self.updateCell(cell, index: indexPath.item)
            }
            else if buttonIndex == 1 {
                return
            }
        })
    }

    func episodeCollectionViewCellDidShare(cell: EpisodeCollectionViewCell) {
        guard let indexPath = episodesCollectionView.indexPath(for: cell) else { return }
        let episode = state.season.episodes[indexPath.item]
        let shareVC = ShareEpisodeViewController()
        shareVC.state = .init(episode: episode)
        shareVC.okBlock = { _, image in
            shareVC.dismiss(animated: true) { [weak self] in
                guard let vc = self else { return }
                let text = shareVC.state.shareText
                var activityItems: [Any] = [text]
                if let image = image {
                    activityItems.append(image)
                }
                let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                if UIDevice.isIPad, let popover = activityVC.popoverPresentationController {
                    popover.sourceView = cell.btnShare
                    popover.sourceRect = cell.contentView.frame
                    popover.permittedArrowDirections = [.any]
                }
                vc.present(activityVC, animated: true)
            }
        }

        shareVC.cancelBlock = {
            shareVC.dismiss(animated: true)
        }

        self.present(shareVC, on: self)
    }

    func episodeCollectionViewCellDidWatchOnYoutube(cell: EpisodeCollectionViewCell) {
        guard let link = cell.state.youtubeLink, let url = URL(string: link) else { return }
        let config: SFSafariViewController.Configuration = .init()
        config.entersReaderIfAvailable = true
        let vc: SFSafariViewController = .init(url: url, configuration: config)
        present(vc, animated: true)
    }

    // MARK: - seems we will not use this method because all content now is free
    private func notFreeNotBoughtNotDownloaded(episode: Episode, episodeState: EpisodeState, season: Season) -> Bool {
        return episode.shouldPurchase && !(episodeState.isPurchased || season.isPurchased) && episodeState.downloadInfo == nil
    }

    private func handleNotFreeNotBoughtNotDownloadedCase(episode: Episode, cell: EpisodeCollectionViewCell, indexPath: IndexPath) {
        if !InAppPurchaseManager.canMakePayments() {
            AlertManager.present(
                title: Local("Title"),
                message: Local("Purchases.Off"),
                buttons: [Local("OK")],
                dismissBlock: { _ in
                })
            return
        }

        cell.blockUI()

        InAppPurchaseManager.shared.purchaseProduct(with: episode.product, success: { [weak self] (data, str) in
            print("Purchased, data = \(data), str = \(String(describing: str))")
            //Store purchased flag permanently
            //NOTE: because state is retrieved every time, store it before any changes
            let state = episode.state
            state.isPurchased = true
            state.save()

            guard let self = self else { return }
            cell.unblockUI()

            //Reload button
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateCell(cell, index: indexPath.item)
            }

            //NOTE: Firebase analytics collect in_app_purchase event automatically

            //Get files from our server (episode is not downloaded)
            self.downloadFileFor(episode: episode)

        }) { error in
            print("Error: \(error)")
            cell.unblockUI()
        }
    }

    private func present(_ episode: Episode) {
        //Open downloaded episode
        let index = state.season.episodes.firstIndex(where: { $0.id == episode.id })!
        //Next episode in current season or 1st episode in next book
        let nextEpisode = index < state.season.episodes.count - 1 ? state.season.episodes[index + 1] : state.nextEpisode
        let episodeViewController = EpisodeViewController(
            episode: episode,
            nextEpisode: nextEpisode,
            isLast: index == state.season.episodes.count - 1,
            season: state.season,
            delegate: self
        )
        self.navigationController?.pushViewController(episodeViewController, animated: true)
    }

    private func present(_ vc: UIViewController, on viewController: UIViewController) {
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen

        viewController.present(vc, animated: true, completion: nil)
    }
}

//MARK: - EpisodeViewControllerDelegate
extension EpisodesViewController: EpisodeViewControllerDelegate {
    func episodeViewControllerWillGoNext(_ controller: EpisodeViewController, goNextBook: Bool) {
        if !goNextBook {
            self.navigationController?.popViewController(animated: true)
            //Scroll to episode + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.goNext()
            }
        } else {
            self.delegate?.episodesViewControllerDidGoNext(self, currentSeason: state.season)
        }
    }
}

// MARK: - BackgroundDownloaderDelegate
extension EpisodesViewController: BackgroundDownloaderDelegate {
    func backgroundDownloader(_ downloader: BackgroundDownloader, progressChangedFor item: DownloadItem, bytes: Int64, total: Int64, to: String) {
        guard let episode = item as? Episode else { return }

        //Save state
        let episodeState = episode.state
        if episodeState.downloadInfo == nil {
            episodeState.downloadInfo = DownloadInfo()
        }
        episodeState.downloadInfo?.bytesReceived = bytes
        episodeState.downloadInfo?.bytesTotal = total
        episodeState.save()

        //Update interface
        self.updateCells()
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
        self.updateCells()

        //Unpack
        //Async to update button before unpack
        DispatchQueue.main.async {
            guard let folderName = FileManager.fileNameWithoutExtension(from: episodeState.fileName)
            else { return }

            let atURL = URL(fileURLWithPath: to)
            let to2 = FileManager.pathInDocuments(subdirectory: "Comics", fileName: folderName)
            let toURL = URL(fileURLWithPath: to2, isDirectory: true)
            print("At: \(atURL), to: \(toURL)")

            let success = SSZipArchive.unzipFile(atPath: to,
                                                 toDestination: to2,
                                                 preserveAttributes: true,
                                                 overwrite: true,
                                                 nestedZipLevel: 2,
                                                 password: nil,
                                                 error: nil,
                                                 delegate: nil,
                                                 progressHandler: nil,
                                                 completionHandler: nil)


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

// MARK: - DownloadFileForEpisodeDelegate

extension EpisodesViewController: DownloadFileForEpisodeDelegate {}
