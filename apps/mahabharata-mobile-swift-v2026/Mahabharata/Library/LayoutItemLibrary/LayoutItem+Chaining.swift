//
//  LayoutItem+Chaining.swift
//  LayoutLibrary
//
//  Created by Stanislav Grinberg on 27 Oct 2017.
//  Updated by Andrey Kozlov on 17 Feb 2019.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//
//  Changes history:
//		07 Mar 2018. Stanislav Grinberg:
//          * centerX and centerY now supporting shifting
//      14 Sep 2018. Sergey Vasilyev:
//          * deactivateConstraints now supportig array of NSLayoutConstraint
//		16 Jan 2019. Andrey Kozlov:
//			* added width/height with anchor methods (commented)
//			* added constraints(autoresizing:) extension to UIView
//		11 Feb 2019. Andrey Kozlov:
//			* added safeAreaLayoutGuide parameter for all methods to support iPhone X
//			* added Dock methods to extension Array
//			* added invert to extension NSLayoutConstraint.Relation for correct execution in right(), trailing(), bottom() methods.
//		14 Feb 2019. Andrey Kozlov:
//			* added safeItem()
//			* refactoring code
//		17 Feb 2019. Andrey Kozlov:
//			* now all methods support safeItem
//

// Dock (dockLeft, dockRight, dockTop, dockBottom) - цепляет к указанной строне и прижимает к смежным, например, dockLeft цепляет к левой стороне и прижимает к низу и верху. Эквивалентно насыпанию в П-образный контейнер.
// Align (top, left/leading, right/trailing, bottom) - цепляет к указанной стороне. Эквивалентно заданию начала координат от указанной стороны.
// Pin (pinTop, pinLeft, pinRight, pinBottom) - pinLeft цепляет к объекту находящемуся слева к его правой стороне. Эквивалентно столновению с объектом в указанном направлении.

import UIKit

// MARK: Express value with relation (e.g >=10 or <=20)

struct FlexibleMargin {
	
	let value: CGFloat
	let relation: NSLayoutConstraint.Relation
}

prefix operator <=
prefix func <= (value: CGFloat) -> FlexibleMargin {
	return FlexibleMargin(value: value, relation: .lessThanOrEqual)
}

prefix operator >=
prefix func >= (value: CGFloat) -> FlexibleMargin {
	return FlexibleMargin(value: value, relation: .greaterThanOrEqual)
}

// >=view or >=view + 10

struct FlexibleDimension {
	
	let view: UIView
	let relation: NSLayoutConstraint.Relation
	let value: CGFloat
}

prefix func <= (view: UIView) -> FlexibleDimension {
	return FlexibleDimension(view: view, relation: .lessThanOrEqual, value: 0.0)
}

prefix func >= (view: UIView) -> FlexibleDimension {
	return FlexibleDimension(view: view, relation: .greaterThanOrEqual, value: 0.0)
}

func + (lhs: FlexibleDimension, rhs: CGFloat) -> FlexibleDimension {
	return FlexibleDimension(view: lhs.view, relation: lhs.relation, value: lhs.value + rhs)
}

// MARK: Helper functions

private func layoutItem<T>(_ firstItem: LayoutItem<T>, constrainTo secondItem: LayoutItem<T>, withRelation relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
	if relation == .greaterThanOrEqual {
		return firstItem >= secondItem
	} else if relation == .lessThanOrEqual {
		return firstItem <= secondItem
	}
	fatalError()
}

private func layoutItem(_ item: LayoutItem<Dimension>, constrainToValue value: CGFloat, withRelation relation: NSLayoutConstraint.Relation) -> NSLayoutConstraint {
	if relation == .greaterThanOrEqual {
		return item >= value
	} else if relation == .lessThanOrEqual {
		return item <= value
	}
	fatalError()
}

private func safeItem(_ view: UIView, _ guide: Bool) -> LayoutItemProtocol {
	if guide, #available(iOS 11.0, *) {
		return view.safeAreaLayoutGuide
	}
	return view
}

func activateConstraints(_ constraintsArrays: [NSLayoutConstraint]...) {
	var constraints = [NSLayoutConstraint]()
	for constraintsArray in constraintsArrays {
		for constraint in constraintsArray {
			constraints.append(constraint)
		}
	}
	NSLayoutConstraint.activate(constraints)
}

func deactivateConstraints(_ constraintsArrays: [NSLayoutConstraint]...) {
	var constraints = [NSLayoutConstraint]()
	for constraintsArray in constraintsArrays {
		for constraint in constraintsArray {
			constraints.append(constraint)
		}
	}
	NSLayoutConstraint.deactivate(constraints)
}

// MARK: - UIView + LayoutItem

extension UIView {
	
	// MARK: - Align
	
	func top(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.topItem == toItem.topItem + value]
	}
	
	func top(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [layoutItem(self.topItem, constrainTo: toItem.topItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func left(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.leftItem == toItem.leftItem + value]
	}
	
	func left(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [layoutItem(self.leftItem, constrainTo: toItem.leftItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func leading(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.leadingItem == toItem.leadingItem + value]
	}
	
	func leading(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [layoutItem(self.leadingItem, constrainTo: toItem.leadingItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func bottom(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.bottomItem == toItem.bottomItem - value]
	}
	
	func bottom(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [layoutItem(self.bottomItem, constrainTo: toItem.bottomItem - flexibleMargin.value, withRelation: flexibleMargin.relation.invert)]
	}
	
	func right(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.rightItem == toItem.rightItem - value]
	}
	
	func right(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [layoutItem(self.rightItem, constrainTo: toItem.rightItem - flexibleMargin.value, withRelation: flexibleMargin.relation.invert)]
	}
	
	func trailing(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.trailingItem == toItem.trailingItem - value]
	}
	
	func trailing(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [layoutItem(self.trailingItem, constrainTo: toItem.trailingItem - flexibleMargin.value, withRelation: flexibleMargin.relation.invert)]
	}
	
	// MARK: - Height, Width
	
	func height(_ value: CGFloat) -> [NSLayoutConstraint] {
		return [self.heightItem == value]
	}
	
	func height(_ flexibleMargin: FlexibleMargin) -> [NSLayoutConstraint] {
		return [layoutItem(self.heightItem, constrainToValue: flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func height(_ flexibleDimension: FlexibleDimension) -> [NSLayoutConstraint] {
		return [layoutItem(self.heightItem, constrainTo: flexibleDimension.view.heightItem + flexibleDimension.value, withRelation: flexibleDimension.relation)]
	}
	
	func height(of item: UIView, safe guide: Bool = false, multiplier: CGFloat = 1.0) -> [NSLayoutConstraint] {
		return [self.heightItem == safeItem(item, guide).heightItem * multiplier]
	}
	
	func width(_ value: CGFloat) -> [NSLayoutConstraint] {
		return [self.widthItem == value]
	}
	
	func width(_ flexibleMargin: FlexibleMargin) -> [NSLayoutConstraint] {
		return [layoutItem(self.widthItem, constrainToValue: flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func width(_ flexibleDimension: FlexibleDimension) -> [NSLayoutConstraint] {
		return [layoutItem(self.widthItem, constrainTo: flexibleDimension.view.widthItem + flexibleDimension.value, withRelation: flexibleDimension.relation)]
	}
	
	func width(of item: UIView, safe guide: Bool = false, multiplier: CGFloat = 1.0) -> [NSLayoutConstraint] {
		return [self.widthItem == safeItem(item, guide).widthItem * multiplier]
	}
	
	// MARK: - Centering
	
	func centerY(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.centerYItem == toItem.centerYItem + value]
	}
	
	func centerX(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.centerXItem == toItem.centerXItem + value]
	}
	
	func center(to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.centerXItem == toItem.centerXItem, self.centerYItem == toItem.centerYItem]
	}
	
	// MARK: - Pin
	
	func pinTop(_ value: CGFloat = 0.0, to item: UIView) -> [NSLayoutConstraint] {
		return [self.topItem == item.bottomItem + value]
	}
	
	func pinTop(_ flexibleMargin: FlexibleMargin, to item: UIView) -> [NSLayoutConstraint] {
		return [layoutItem(self.topItem, constrainTo: item.bottomItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func pinLeft(_ value: CGFloat = 0.0, to item: UIView) -> [NSLayoutConstraint] {
		return [self.leadingItem == item.trailingItem + value]
	}
	
	func pinLeft(_ flexibleMargin: FlexibleMargin, to item: UIView) -> [NSLayoutConstraint] {
		return [layoutItem(self.leadingItem, constrainTo: item.trailingItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func pinRight(_ value: CGFloat = 0.0, to item: UIView) -> [NSLayoutConstraint] {
		return [self.trailingItem == item.leadingItem - value]
	}
	
	func pinRight(_ flexibleMargin: FlexibleMargin, to item: UIView) -> [NSLayoutConstraint] {
		return [layoutItem(self.trailingItem, constrainTo: item.leadingItem - flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func pinBottom(_ value: CGFloat = 0.0, to item: UIView) -> [NSLayoutConstraint] {
		return [self.bottomItem == item.topItem - value]
	}
	
	func pinBottom(_ flexibleMargin: FlexibleMargin, to item: UIView) -> [NSLayoutConstraint] {
		return [layoutItem(self.bottomItem, constrainTo: item.topItem - flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	// MARK: - Dock
	
	func dockTop(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let secondView: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.topItem == secondView.topItem + value,
				self.leadingItem == secondView.leadingItem + value,
				self.trailingItem == secondView.trailingItem - value]
		
	}
	
	func dockLeft(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let secondView: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.topItem == secondView.topItem + value,
				self.leadingItem == secondView.leadingItem + value,
				self.bottomItem == secondView.bottomItem - value]
	}
	
	func dockRight(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let secondView: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.topItem == secondView.topItem + value,
				self.trailingItem == secondView.trailingItem - value,
				self.bottomItem == secondView.bottomItem - value]
	}
	
	func dockBottom(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let secondView: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.leadingItem == secondView.leadingItem + value,
				self.bottomItem == secondView.bottomItem - value,
				self.trailingItem == secondView.trailingItem - value]
	}
	
	// MARK: - Miscellaneous
	
	func edges(_ value: CGFloat, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		return edges(top: value, left: value, bottom: value, right: value, to: item, safe: guide)
	}
	
	func edges(top: CGFloat = 0.0, left: CGFloat = 0.0, bottom: CGFloat = 0.0, right: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let toItem: LayoutItemProtocol = safeItem(item ?? superview!, guide)
		return [self.topItem == toItem.topItem + top,
				self.leadingItem == toItem.leadingItem + left,
				self.trailingItem == toItem.trailingItem - right,
				self.bottomItem == toItem.bottomItem - bottom]
	}
	
	func apply(side: CGFloat) -> [NSLayoutConstraint] {
		return apply(size: CGSize(width: side, height: side))
	}
	
	func apply(size: CGSize, multiplier: CGFloat = 1.0) -> [NSLayoutConstraint] {
		return [widthItem == size.width * multiplier, heightItem == size.height * multiplier]
	}
	
	func apply(of item: UIView? = nil, multiplier: CGFloat = 1.0) -> [NSLayoutConstraint] {
		let toItem = item ?? superview!
		return [self.widthItem == toItem.widthItem * multiplier, self.heightItem == toItem.heightItem * multiplier]
	}
}

// MARK: - Array + Chaining

extension Array where Element == NSLayoutConstraint {
	
	// MARK: - Align
	
	func top(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.topItem == secondView.topItem + value]
	}
	
	func top(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [layoutItem(firstView.topItem, constrainTo: secondView.topItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func left(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.leftItem == secondView.leftItem + value]
	}
	
	func left(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [layoutItem(firstView.leftItem, constrainTo: secondView.leftItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func leading(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.leadingItem == secondView.leadingItem + value]
	}
	
	func leading(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [layoutItem(firstView.leadingItem, constrainTo: secondView.leadingItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func bottom(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.bottomItem == secondView.bottomItem - value]
	}
	
	func bottom(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [layoutItem(firstView.bottomItem, constrainTo: secondView.bottomItem - flexibleMargin.value, withRelation: flexibleMargin.relation.invert)]
	}
	
	func right(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.rightItem == secondView.rightItem - value]
	}
	
	func right(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [layoutItem(firstView.rightItem, constrainTo: secondView.rightItem - flexibleMargin.value, withRelation: flexibleMargin.relation.invert)]
	}
	
	func trailing(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.trailingItem == secondView.trailingItem - value]
	}
	
	func trailing(_ flexibleMargin: FlexibleMargin, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [layoutItem(firstView.trailingItem, constrainTo: secondView.trailingItem - flexibleMargin.value, withRelation: flexibleMargin.relation.invert)]
	}
	
	// MARK: - Height, Width
	
	func height(_ value: CGFloat) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [firstView.heightItem == value]
	}
	
	func height(_ flexibleMargin: FlexibleMargin) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [layoutItem(firstView.heightItem, constrainToValue: flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func height(_ flexibleDimension: FlexibleDimension) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [layoutItem(firstView.heightItem, constrainTo: flexibleDimension.view.heightItem + flexibleDimension.value, withRelation: flexibleDimension.relation)]
	}
	
	func height(of item: UIView, safe guide: Bool = false, multiplier: CGFloat = 1.0) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [firstView.heightItem == safeItem(item, guide).heightItem * multiplier]
	}
	
	func width(_ value: CGFloat) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [firstView.widthItem == value]
	}
	
	func width(_ flexibleMargin: FlexibleMargin) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [layoutItem(firstView.widthItem, constrainToValue: flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func width(_ flexibleDimension: FlexibleDimension) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [layoutItem(firstView.widthItem, constrainTo: flexibleDimension.view.widthItem + flexibleDimension.value, withRelation: flexibleDimension.relation)]
	}
	
	func width(of item: UIView, safe guide: Bool = false, multiplier: CGFloat = 1.0) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [firstView.widthItem == safeItem(item, guide).widthItem * multiplier]
	}
	
	// MARK: - Centering
	
	func centerY(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.centerYItem == secondView.centerYItem + value]
	}
	
	func centerX(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.centerXItem == secondView.centerXItem + value]
	}
	
	func center(to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		return self + [firstView.centerXItem == secondView.centerXItem, firstView.centerYItem == secondView.centerYItem]
	}
	
	// MARK: - Pin
	
	func pinTop(_ value: CGFloat = 0.0, to item: UIView) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [firstView.topItem == item.bottomItem + value]
	}
	
	func pinTop(_ flexibleMargin: FlexibleMargin, to item: UIView) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [layoutItem(firstView.topItem, constrainTo: item.bottomItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func pinLeft(_ value: CGFloat = 0.0, to item: UIView) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [firstView.leadingItem == item.trailingItem + value]
	}
	
	func pinLeft(_ flexibleMargin: FlexibleMargin, to item: UIView) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [layoutItem(firstView.leadingItem, constrainTo: item.trailingItem + flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func pinRight(_ value: CGFloat = 0.0, to item: UIView) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [firstView.trailingItem == item.leadingItem - value]
	}
	
	func pinRight(_ flexibleMargin: FlexibleMargin, to item: UIView) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [layoutItem(firstView.trailingItem, constrainTo: item.leadingItem - flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	func pinBottom(_ value: CGFloat = 0.0, to item: UIView) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [firstView.bottomItem == item.topItem - value]
	}
	
	func pinBottom(_ flexibleMargin: FlexibleMargin, to item: UIView) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		return self + [layoutItem(firstView.bottomItem, constrainTo: item.topItem - flexibleMargin.value, withRelation: flexibleMargin.relation)]
	}
	
	// MARK: - Dock
	
	func dockTop(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		let constraints: [NSLayoutConstraint] = [firstView.topItem == secondView.topItem + value,
												 firstView.leadingItem == secondView.leadingItem + value,
												 firstView.trailingItem == secondView.trailingItem - value]
		return self + constraints
	}
	
	func dockLeft(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		let constraints: [NSLayoutConstraint] = [firstView.topItem == secondView.topItem + value,
												 firstView.leadingItem == secondView.leadingItem + value,
												 firstView.bottomItem == secondView.bottomItem - value]
		return self + constraints
	}
	
	func dockRight(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		let constraints: [NSLayoutConstraint] = [firstView.topItem == secondView.topItem + value,
												 firstView.trailingItem == secondView.trailingItem - value,
												 firstView.bottomItem == secondView.bottomItem - value]
		return self + constraints
	}
	
	func dockBottom(_ value: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		let constraints: [NSLayoutConstraint] = [firstView.leadingItem == secondView.leadingItem + value,
												 firstView.bottomItem == secondView.bottomItem - value,
												 firstView.trailingItem == secondView.trailingItem - value]
		return self + constraints
	}
	
	// MARK: - Miscellaneous
	
	func edges(_ value: CGFloat, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		return edges(top: value, left: value, right: value, bottom: value, to: item, safe: guide)
	}
	
	func edges(top: CGFloat = 0.0, left: CGFloat = 0.0, right: CGFloat = 0.0, bottom: CGFloat = 0.0, to item: UIView? = nil, safe guide: Bool = false) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView: LayoutItemProtocol = safeItem(item ?? firstView.superview!, guide)
		let constraints: [NSLayoutConstraint] = [firstView.topItem == secondView.topItem + top,
												 firstView.leadingItem == secondView.leadingItem + left,
												 firstView.trailingItem == secondView.trailingItem - right,
												 firstView.bottomItem == secondView.bottomItem - bottom]
		return self + constraints
	}
	
	func apply(side: CGFloat) -> [NSLayoutConstraint] {
		return apply(size: CGSize(width: side, height: side))
	}
	
	func apply(size: CGSize, multiplier: CGFloat = 1.0) -> [NSLayoutConstraint] {
		let view = self.last!.firstItem as! UIView
		return self + [view.widthItem == size.width * multiplier, view.heightItem == size.height * multiplier]
	}
	
	func apply(of item: UIView? = nil, multiplier: CGFloat = 1.0) -> [NSLayoutConstraint] {
		let firstView = self.last!.firstItem as! UIView
		let secondView = item ?? firstView.superview!
		return self + [firstView.widthItem == secondView.widthItem * multiplier, firstView.heightItem == secondView.heightItem * multiplier]
	}
}

// MARK: - Priority setting

extension Array where Element == NSLayoutConstraint {
	
	func priority(_ value: Float) -> [NSLayoutConstraint] {
		self.last!.priority = UILayoutPriority(value)
		return self
	}
}

// MARK: - Invert relation

extension NSLayoutConstraint.Relation {
	
	var invert: NSLayoutConstraint.Relation {
		if self == .greaterThanOrEqual {
			return .lessThanOrEqual
		} else if self == .lessThanOrEqual {
			return .greaterThanOrEqual
		}
		return .equal
	}
}

