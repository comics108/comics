//
//  AboutViewController.swift
//  Mahabharata
//
//  Created by Roman Developer on 11/9/17.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//

import UIKit
import AVKit
import FirebaseAnalytics

class AboutViewController: UIViewController {
    private let vBackground = GradientView()

    private let svContent = UIScrollView().background(.clear)
    private let contentView = UIView().background(.clear)

    private let lblAbout = UILabel.aboutLabel(Local("About.Text"))

    private lazy var btnRestorePurchases: UIButton = {
        let btn = UIButton(type: .custom).color(.yellow1).background(.clear).font(UIFont.semibold(ofSize: 14)).corners(4).borderColor(.yellow1).clip()
            .title(Local("Purchases.Restore"))

        btn.addTarget(self, action: #selector(btnRestorePurchases_Click(_:)), for: .touchUpInside)

        return btn
    }()

    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .white

        self.view.addSubview(self.vBackground)
        self.view.addSubview(self.svContent)

        self.svContent.addSubview(self.contentView)

        self.contentView.addSubview(self.lblAbout)
        self.contentView.addSubview(self.btnRestorePurchases)

        activateConstraints(
            self.vBackground.edges(),
            self.svContent.dockTop().width(of: self.view).bottom(),

            self.contentView.top().bottom(),
            UIDevice.isIPad ?
            self.contentView.width(EpisodeCollectionViewCell.episodeCoverSize.width).centerX() :
                self.contentView.width(of: self.svContent),

            self.lblAbout.top(16).leading(16).trailing(16),

            self.btnRestorePurchases.pinTop(24, to: self.lblAbout).height(34).centerX(),
            UIDevice.isIPad ?
            [self.btnRestorePurchases.widthItem == self.contentView.widthItem * 0.5] :
                self.btnRestorePurchases.leading(70).trailing(70),
            [self.btnRestorePurchases.bottomItem <= self.contentView.bottomItem - 24]
        )
    }

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = Local("About.Title")
        self.navigationItem.leftBarButtonItem = self.barButton(withImage: "icon_back", action: #selector(btnBack_Click(_:)))
    }

    //MARK: - Methods
    func blockUI() {
        btnRestorePurchases.showActivityIndicator()
        self.btnRestorePurchases.isUserInteractionEnabled = false
    }

    func unblockUI() {
        btnRestorePurchases.hideActivityIndicator()
        self.btnRestorePurchases.isUserInteractionEnabled = true
    }

    private func restoreProducts() {
        self.blockUI()
        InAppPurchaseManager.shared.restoreProducts(success: { [weak self] (productIDs) in
            print("Restored, productIDs = \(String(describing: productIDs))")

            Analytics.logEvent(AnalyticsCustomEvents.Episode.restorePurchases, parameters: [AnalyticsParameters.productIds : String(describing: productIDs)])

            MahabharataRequestManager.getSeasons(success: { [weak self] (seasons) in
                // NOTE: restore even if self is destructed because purchase fact is stored in UserDefaults
                for season in seasons {
                    var hasRestored = false

                    // Restore seasons
                    if productIDs.contains(season.product) {
                        Season.markPurchased(season.id)
                        hasRestored = true
                    }
                    // Restore episodes
                    for episode in season.episodes {
                        if productIDs.contains(episode.product) {
                            hasRestored = true
                            //Store purchased flag permanently
                            //NOTE: because state is retrieved every time, store it before any changes
                            let state = episode.state
                            state.isPurchased = true
                            state.save()
                        }
                    }

                    if hasRestored {
                        // Notify episodes list to refresh all to avoid many notifications
                        NotificationCenter.default.post(name: .seasonEpisodesRestored, object: nil, userInfo: [Season.NotificationConstants.userInfoIdKey: season.id])
                    }
                }
                guard let self = self else { return }
                self.unblockUI()
            }, error: { [weak self] (err) in
                self?.unblockUI()
                print(err)
            })
        }) { (error) in
            self.unblockUI()
            print("Error: \(error)")
        }
    }

    // MARK: - Handlers
    @objc
    func btnBack_Click(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    func btnRestorePurchases_Click(_ sender: UIButton) {
        if !InAppPurchaseManager.canMakePayments() {
            AlertManager.present(
                title: Local("Title"),
                message: Local("Purchases.Off"),
                buttons: [Local("OK")],
                dismissBlock: { _ in
                })
        } else {
            restoreProducts()
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
