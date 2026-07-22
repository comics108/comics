//
//  QuotesViewController.swift
//  Mahabharata
//
//  Created by Olga Zhegulo  on 28/03/2018.
//  Copyright © 2018 Iron Water Studio. All rights reserved.
//

import UIKit
import FirebaseAnalytics

class QuotesViewController: UIViewController {

	var quotes = [Quote]()
	
	private let vBackground = GradientView()
	
	fileprivate lazy var tblItems: UITableView = {
		let table = UITableView()
		table.backgroundColor = UIColor.clear
		table.dataSource = self
		
		table.rowHeight = UITableView.automaticDimension
		table.estimatedRowHeight = 400
		
		HeaderTableViewCell.register(for: table)
		QuoteTableViewCell.register(for: table)
		
		//Avoid extra space to edges on iPad
		table.cellLayoutMarginsFollowReadableWidth = false
		
		table.tableFooterView = UIView()
		
		return table
	}()
	
	override func loadView() {
		self.view = UIView()
		self.view.backgroundColor = .white
		
		self.view.addSubviews(self.vBackground, self.tblItems)
		
		activateConstraints(
			self.vBackground.edges(),
			self.tblItems.edges()
		)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		MahabharataRequestManager.getQuotes(success: { (quotes) in
			self.quotes = quotes
			self.tblItems.reloadData()
		}) { (err) in
			print(err)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.isNavigationBarHidden = true
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		self.navigationController?.isNavigationBarHidden = false
	}
	
	private func present(_ vc: UIViewController, on viewController: UIViewController) {
		vc.modalTransitionStyle = .crossDissolve
		vc.modalPresentationStyle = .overFullScreen
		
		viewController.present(vc, animated: true, completion: nil)
	}

}

//MARK: - UITableViewDataSource
extension QuotesViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.quotes.count + 1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.row == 0 {
			let cell = tableView.dequeue(for: indexPath) as HeaderTableViewCell
			cell.fill(with: Local("Mahabharata"))
			return cell
		} else {
			
			let quote = self.quotes[indexPath.row - 1]
			let cell = tableView.dequeue(for: indexPath) as QuoteTableViewCell
			cell.fill(with: quote, delegate: self)
			
			return cell
		}
	}
}

//MARK: - QuoteTableViewCellDelegate
extension QuotesViewController: QuoteTableViewCellDelegate {
	func quoteTableViewCellDidShare(_ cell: QuoteTableViewCell, quote: Quote) {
		let shareVC = ShareQuoteViewController(quote: quote)
		
		shareVC.okBlock = { (quotequoteImage, image) in
			
			shareVC.dismiss(animated: true, completion: { [weak self] in
				guard let self = self else { return }
				let text = shareVC.text
				
				var activityItems: [Any] = [text]
				if let image = image {
					activityItems.append(image)
				} else {
					//Text as alternative
					activityItems.append(quote.name)
				}
				
				let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
				
				if UIDevice.isIPad, let popover = activityVC.popoverPresentationController {
					popover.sourceRect = self.view.bounds
					popover.sourceView = self.view
					popover.permittedArrowDirections = [.up]
				}
				self.present(activityVC, animated: true)
			})
		}
		
		shareVC.cancelBlock = {
			shareVC.dismiss(animated: true)
		}
		
		self.present(shareVC, on: self)
	}
}
