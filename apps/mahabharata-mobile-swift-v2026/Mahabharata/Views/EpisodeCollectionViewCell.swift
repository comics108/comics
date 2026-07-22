//
//  EpisodeCollectionViewCell.swift
//  Mahabharata
//
//  Created by Roman Developer on 10/17/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit

protocol EpisodeCollectionViewCellDelegate: AnyObject {
    func episodeCollectionViewCellDidRead(cell: EpisodeCollectionViewCell)
    func episodeCollectionViewCellDidUpdate(cell: EpisodeCollectionViewCell)
    func episodeCollectionViewCellDidDelete(cell: EpisodeCollectionViewCell)
    func episodeCollectionViewCellDidShare(cell: EpisodeCollectionViewCell)
    func episodeCollectionViewCellDidWatchOnYoutube(cell: EpisodeCollectionViewCell)
}

extension EpisodeCollectionViewCell {
    struct ViewState {
        var youtubeLink: String?
        var watchTitle: String {
           return Local("Episodes.Watch")
        }
    }
}

extension EpisodeCollectionViewCell.ViewState {
    static var empty: EpisodeCollectionViewCell.ViewState { .init() }
}

class EpisodeCollectionViewCell: ReusableCollectionViewCell {
    private var reqMan : MahabharataRequestManager? = nil

    weak var delegate: EpisodeCollectionViewCellDelegate?
    var state: ViewState = .empty {
        didSet {
            updateAppearance()
        }
    }

    //Coefficent to screen width of design/sketches
    public static let ratioX: CGFloat = UIScreen.main.bounds.size.width / 375.0
    //Calculate episode cover by proportion to cover of sketch
    public static let episodeCoverSize = CGSize(width: round(236 * ratioX), height: round(344 * ratioX) )
    public static let visualSpan: CGFloat = round(20 * ratioX)
    public static let pageWidth = episodeCoverSize.width + visualSpan
    public static let spaceOverlapCount: CGFloat = 7
    public static let cellSize = CGSize(width: pageWidth + spaceOverlapCount * visualSpan, height: episodeCoverSize.height)

    private var vPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 2
        view.layer.shadowColor = UIColor.black.alpha(0.36).cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 3

        return view
    }()

    private let vCover: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()

    private let imgCover = UIImageView()
    private let imgTopCover = UIImageView(image: UIImage(named: UIDevice.isIPad ? "cover_bg_ipad.png" : "cover_bg.png") ?? UIImage())
    private let lblTitle = UILabel.titleSmallLabel()
    private let lblEpisodeNumber = UILabel.numberSmallLabel()
    private let lblDate: UILabel = {
        let label = UILabel.numberSmallLabel().alignment(.right)
        label.isHidden = true
        return label
    }()

    //NOTE: use system font instead of custom because otherwise another font is loaded to display rouble => scroll lag before cell with price
    private let btnRead: ProgressButton = {
        ProgressButton()
            .background(.yellow1)
            .color(.maroon1)
            .font(UIFont.semibold(ofSize: 10))
            .corners(4)
            .borderColor(.yellow1)
            .clip()

    }()
    private let btnUpdate = UIButton(type: .custom).foreground(UIImage(named:"icon_refresh.png") ?? UIImage(), for: .normal)
    private let btnDelete: UIButton = {
        let button = UIButton(type: .custom).foreground(UIImage(named:"icon_del.png") ?? UIImage(), for: .normal)
        button.isHidden = true
        return button
    }()
    let btnShare = UIButton(type: .custom).foreground(UIImage(named:"icon_share_small.png") ?? UIImage(), for: .normal)

    lazy var btnWatchYoutube: UIButton = {
        let button = UIButton(type: .custom)
            .background(.yellow1)
            .color(.maroon1)
            .font(UIFont.semibold(ofSize: 10))
            .corners(4)
            .borderColor(.yellow1)
            .title(state.watchTitle)
            .clip()
        return button
    }()
    
    private let btnBigRead = UIButton(type: .custom).background(.clear)

    override init(frame: CGRect) {

        super.init(frame: frame)

        self.backgroundColor = .clear

        self.contentView.addSubview(self.vPanel)
        self.vPanel.addSubview(self.vCover)
        self.vCover.addSubview(self.imgCover)
        self.vCover.addSubview(self.imgTopCover)
        self.vCover.addSubview(self.lblTitle)
        self.vCover.addSubview(self.lblEpisodeNumber)
        self.vCover.addSubview(self.lblDate)

        self.vCover.addSubview(self.btnBigRead)
        self.vCover.addSubview(self.btnRead)
        self.vCover.addSubview(self.btnUpdate)
        self.vCover.addSubview(self.btnDelete)
        self.vCover.addSubview(self.btnShare)
        self.vCover.addSubviews(self.btnWatchYoutube)
        
        self.btnRead.addTarget(self, action: #selector(btnRead_Click(_:)), for: .touchUpInside)
        self.btnUpdate.addTarget(self, action: #selector(btnUpdate_Click(_:)), for: .touchUpInside)
        self.btnDelete.addTarget(self, action: #selector(btnDelete_Click(_:)), for: .touchUpInside)
        self.btnShare.addTarget(self, action: #selector(btnShare_Click(_:)), for: .touchUpInside)
        self.btnWatchYoutube.addTarget(self, action: #selector(btnWatchYoutube_Click(_:)), for: .touchUpInside)
        self.btnBigRead.addTarget(self, action: #selector(btnRead_Click(_:)), for: .touchUpInside)

        let sidePadding = ((EpisodeCollectionViewCell.spaceOverlapCount + 1) * EpisodeCollectionViewCell.visualSpan) / 2
        activateConstraints(
            self.vPanel.leadingItem == self.contentView.leadingItem + sidePadding,
            self.vPanel.trailingItem == self.contentView.trailingItem - sidePadding,
            self.vPanel.topItem == self.contentView.topItem,
            self.vPanel.bottomItem == self.contentView.bottomItem,

            self.vCover.leadingItem == self.vPanel.leadingItem,
            self.vCover.topItem == self.vPanel.topItem,
            self.vCover.bottomItem == self.vPanel.bottomItem,
            self.vCover.trailingItem == self.vPanel.trailingItem,

            self.imgCover.leadingItem == self.vCover.leadingItem,
            self.imgCover.topItem == self.vCover.topItem,
            self.imgCover.bottomItem == self.vCover.bottomItem,
            self.imgCover.trailingItem == self.vCover.trailingItem,
            self.imgCover.widthItem == EpisodeCollectionViewCell.episodeCoverSize.width,
            self.imgCover.heightItem == EpisodeCollectionViewCell.episodeCoverSize.height,

            self.imgTopCover.leadingItem == self.vCover.leadingItem,
            self.imgTopCover.topItem == self.vCover.topItem,
            self.imgTopCover.trailingItem == self.vCover.trailingItem,
            self.imgTopCover.widthItem == EpisodeCollectionViewCell.episodeCoverSize.width,
            self.imgTopCover.heightItem == 144,

            self.lblEpisodeNumber.topItem == self.vCover.topItem + 16,
            self.lblEpisodeNumber.leadingItem == self.vCover.leadingItem + 16,

            self.lblTitle.topItem == self.lblEpisodeNumber.bottomItem + 6,
            self.lblTitle.leadingItem == self.lblEpisodeNumber.leadingItem,
            self.lblTitle.trailingItem == self.vCover.trailingItem - 48,

            self.lblDate.topItem == self.lblEpisodeNumber.topItem,
            self.lblDate.trailingItem == self.vCover.trailingItem - 16,

            self.btnRead.leadingItem == self.lblTitle.leadingItem,
            self.btnRead.topItem == self.lblTitle.bottomItem + 14,
            self.btnRead.widthItem == 66,
            self.btnRead.heightItem == 26,

            self.btnShare.topItem == self.lblTitle.topItem - 10,
            self.btnShare.trailingItem == self.vCover.trailingItem - 4,
            self.btnShare.widthItem == 44,
            self.btnShare.heightItem == 40,

            self.btnWatchYoutube.centerYItem == self.btnRead.centerYItem,
            self.btnWatchYoutube.trailingItem == self.vCover.trailingItem - 12,
            self.btnWatchYoutube.widthItem == 66,
            self.btnWatchYoutube.heightItem == 26,
            
            self.btnUpdate.centerYItem == self.btnRead.centerYItem,
            self.btnUpdate.trailingItem == self.btnDelete.leadingItem - 14,
            self.btnUpdate.widthItem == 44,
            self.btnUpdate.heightItem == 40,

            self.btnDelete.centerYItem == self.btnRead.centerYItem,
            self.btnDelete.trailingItem == self.vCover.trailingItem - 4,
            self.btnDelete.widthItem == 44,
            self.btnDelete.heightItem == 40,

            self.btnBigRead.topItem == self.imgCover.topItem,
            self.btnBigRead.leadingItem == self.imgCover.leadingItem,
            self.btnBigRead.trailingItem == self.imgCover.trailingItem,
            self.btnBigRead.bottomItem == self.imgCover.bottomItem
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        //Cancel image download
        self.reqMan?.cancelConnection()
        self.reqMan = nil

        self.imgCover.image = nil
        lblTitle.text = nil
        btnRead.progressState = .none
        self.backgroundColor = .red

        self.unblockUI()
    }

    // MARK: - Functionality
    func fill(with episode: Episode, bookPurchased: Bool, delegate: EpisodeCollectionViewCellDelegate) {
        self.backgroundColor = .clear
        self.delegate = delegate

        self.lblTitle.text = episode.name
        self.lblEpisodeNumber.text = Local("Episodes.Episode") + " " + String(episode.order)
        self.lblDate.text = episode.date.shortDateString()

        if !String.isNilOrWhiteSpace(episode.image) {
            self.reqMan = MahabharataRequestManager.downloadImage(
                episode.image.replace("*", withValue: "944"),	//Protection from large images on server
                defaultImageName: nil,
                cachePath: MahabharataRequestManager.cachePath(episode),
                context: self,
                success: { [weak self] image in
                    guard let self = self else { return }
                    self.reqMan = nil
                    if let img = image {
                        self.imgCover.image = img
                    }
                })
        } else {
            self.imgCover.image = ImageManager.solid(color: .black, size: EpisodeCollectionViewCell.episodeCoverSize)
        }

        // Update state of download progress button
        self.update(episode: episode, bookPurchased: bookPurchased)
    }

    func setTransform(ratio: CGFloat) {
        var transform = CATransform3DMakeTranslation(-EpisodeCollectionViewCell.episodeCoverSize.width * ratio * 0.12, EpisodeCollectionViewCell.episodeCoverSize.height * abs(ratio) * 0.24, 0)
        transform = CATransform3DScale(transform, 1 - abs(ratio) * 0.24, 1 - abs(ratio) * 0.24, 1)
        self.vPanel.layer.transform = transform
    }

    func update(episode: Episode, bookPurchased: Bool) {
        let episodeState = episode.state

        //Update buttons
        btnRead.progressState = Episode.getState(episode: episode, bookPurchased: bookPurchased)
        btnUpdate.isHidden = !(episodeState.isDownloaded && episode.version > episodeState.version)
        //self.btnDelete.isHidden = !episodeState.isDownloaded
    }

    func blockUI() {
        btnRead.showActivityIndicator()
        self.btnBigRead.isUserInteractionEnabled = false
    }

    func unblockUI() {
        btnRead.hideActivityIndicator()
        self.btnRead.isUserInteractionEnabled = true
    }


}

// MARK: - Handlers -

private extension EpisodeCollectionViewCell {
    @objc func btnRead_Click(_ sender: UIButton) {
        self.delegate?.episodeCollectionViewCellDidRead(cell: self)
    }

    @objc func btnUpdate_Click(_ sender: UIButton) {
        self.delegate?.episodeCollectionViewCellDidUpdate(cell: self)
    }

    @objc func btnDelete_Click(_ sender: UIButton) {
        self.delegate?.episodeCollectionViewCellDidDelete(cell: self)
    }

    @objc func btnShare_Click(_ sender: UIButton) {
        self.delegate?.episodeCollectionViewCellDidShare(cell: self)
    }

    @objc func btnWatchYoutube_Click(_ sender: UIButton) {
        delegate?.episodeCollectionViewCellDidWatchOnYoutube(cell: self)
    }
}

private extension EpisodeCollectionViewCell {
    func updateAppearance() {
        btnWatchYoutube.isHidden = state.youtubeLink == nil
    }
}
