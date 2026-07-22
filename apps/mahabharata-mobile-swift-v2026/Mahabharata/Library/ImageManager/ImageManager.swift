//
//  ImageManager.swift
//  ImageManager
//
//  Created by Vasiliy Ursu on 4 Apr 2012.
//  Updated by Vasiliy Ursu on 28 Dec 2018.
//
//  Dependencies:
//  	UIKit
//
//	Notes:
//		UIGraphicsBeginImageContext(bounds.size) - this method does not uses scale factor and it always is 1.0 (without retina)
//		UIGraphicsBeginImageContextWithOptions(bounds.size, false, image.scale) - this method uses original image scale factor and in most cases it is 1.0 (when received from network or received not scaled image from disk)
//		UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale) - this method uses device screen scale factor
//		UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0) - this method uses device screen scale factor, i.e. 0.0 means automatically use scale factor of main screen/device
//		Resume:
//			Usign device scale factor is always needed.
//
//  Changes history:
//		27 Dec 2018. Vasiliy Ursu:
//			* Fixed using intefral to use downward size of rect
//		28 Dec 2018. Vasiliy Ursu:
//			* Fixed resize image bug ~ when context have greather size than drawed image (1 pixel difference)
//
//  Copyright 2018 IronWaterStudio. All rights reserved.
//

import UIKit
// TODO: check that it needed
//import ImageIO

class ImageManager {
	
	// 6+, 7+ devices return 3.0
	static var scaleFactor: CGFloat {
		get {
			return UIScreen.main.scale //0.0;//UIScreen.main.scale // 0.0 - means automatically use scale factor of main screen
		}
	}
	
	static func angle(degrees: CGFloat) -> CGFloat {
		return degrees * CGFloat.pi / 180.0
	}
	
	// MARK: - Working with file system
	
	// Path should be a full path with dir & name & ext.
	@discardableResult
	static func save(data: Data, atPath path: String) -> Bool {
		if !FileManager.default.fileExists(atPath: path) {
			try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
			do {
				try data.write(to: URL(string: path)!, options: Data.WritingOptions.atomic)
				return true
			} catch let error {
				print("ImageManager: \(error.localizedDescription)")
				return false
			}
		}
		// File existence handling
		return false
	}
	
	// Path should be a full path with dir & name & ext.
	@discardableResult
	static func remove(atPath path: String) -> Bool {
		if FileManager.default.fileExists(atPath: path) {
			do {
				try FileManager.default.removeItem(at: URL(string: path)!)
				return true
			} catch let error {
				print("ImageManager: \(error.localizedDescription)")
				return false
			}
		}
		return false
	}
	
	// Path should be a full path with dir & name & ext.
	static func imageExists(atPath path: String) -> Bool {
		if FileManager.default.fileExists(atPath: path) {
			return true
		}
		return false
	}
	
	
	
	// MARK: - Preloads
	
	///AFAIK, UIGraphicsBeginImageContextWithOptions doesn't set up the bitmap context in the same way as this snipped above (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little) - so when you then draw the image some post-processing still happens on the main thread. But it's also an implementation detail and might change in future iOS releases.
	@available(*, deprecated, message: "This method is deprecated, instead of use preloadImage(path|data)")
	static func preload(image: UIImage?, with context: CGContext? = nil) -> UIImage? {
		guard let image = image else { return nil }
		
		let drawRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
		
		var img: UIImage?
		if let ctx: CGContext = context, let cgImage: CGImage = image.cgImage {
			ctx.draw(cgImage, in: drawRect)
			if let resultCGImage: CGImage = ctx.makeImage() {
				img = UIImage(cgImage: resultCGImage)
			}
		} else {
			// Avoiding lazy load
			let imageSize = image.size
			UIGraphicsBeginImageContextWithOptions(imageSize, false, self.scaleFactor)
			image.draw(in: drawRect)
			img = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
		}
		
		return img
	}
	
	/* Roman's sample code:
	DispatchQueue.global().async {
	let imageData = try! NSData(contentsOfFile: path, options: []) as Data
	if let image = UIImage(data: imageData, scale: UIScreen.main.scale) {
	DispatchQueue.main.async {
	return image
	}
	} else {
	DispatchQueue.main.async {
	return UIImage()
	}
	}
	}
	*/
	// Roman's preload
	static func preload(with path: String) -> UIImage? {
		if let imageData = try? NSData(contentsOfFile: path, options: []) as Data {
			if let image = UIImage(data: imageData, scale: UIScreen.main.scale) {
				return image
			}
		}
		return nil
	}
	
	// Denis preload, this method requires ImageIO.framework.
	static func preloadImage(with data: NSData) -> UIImage? {
		if let imageSource = CGImageSourceCreateWithData(data, nil) {
			let options: [NSObject: Any] = [
				kCGImageSourceShouldCache: true,
				kCGImageSourceShouldCacheImmediately: true
			]
			
			if let image = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary) {
				return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
			}
		}
		
		return nil
	}
	
	// Denis preload: Natural prelaod instead of UIImage.init(contentsOfFile path: String), this method requires ImageIO.framework.
	static func preloadImage(with path: String) -> UIImage? {
		if let imageSource = CGImageSourceCreateWithURL(NSURL.fileURL(withPath: path) as CFURL, nil) {
			let options: [NSObject: Any] = [
				kCGImageSourceShouldCache: true,
				kCGImageSourceShouldCacheImmediately: true
			]
			
			if let image = CGImageSourceCreateImageAtIndex(imageSource, 0, options as CFDictionary) {
				return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up)
			}
		}
		
		return nil
	}
	
	
	// MARK: -
	
	static func resize(image: UIImage, newSize: CGSize) -> UIImage? {
		// This is the rect that we've calculated out and this is what is actually used below
		//Integral returns "upward to the nearest whole integers", but we should take downward size
		//let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
		let rect = CGRect(x: 0, y: 0, width: Int(newSize.width), height: Int(newSize.height))
		
		// Actually do the resizing to the rect using the ImageContext stuff
		UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
		image.draw(in: rect)
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return newImage
	}
	
	static func resize(image: UIImage, fitSize size: CGSize, scaleToFill: Bool = false) -> UIImage? {
		let widthRatio  = size.width  / image.size.width
		let heightRatio = size.height / image.size.height
		
		let ctxRatio = min(widthRatio, heightRatio)
		let ctxWidth = image.size.width * ctxRatio
		let ctxHeight = image.size.height * ctxRatio
		// NOTE: ctxSize & rect.size will be different when scale performed to not whole numbers and ctxSize should little slall than real image (when draw will be performed exceeded pixel will be outscoper/lost)
		var ctxSize = CGSize(width: Int(ctxWidth), height: Int(ctxHeight))
		
		// Integral returns "upward to the nearest whole integers"
		var rect = CGRect(x: 0, y: 0, width: ctxWidth, height: ctxHeight).integral
		// When we should scale & center image to specified fitting size
		if scaleToFill {
			ctxSize = size
			
			let scaledRatio = max(widthRatio, heightRatio)
			
			// Figure out what our orientation is, and use that to form the rectangle
			let scaledSize = CGSize(width: image.size.width * scaledRatio, height: image.size.height * scaledRatio)
			let point = scaledSize == size ? CGPoint.zero : CGPoint(x: (size.width - scaledSize.width) * 0.5, y: (size.height - scaledSize.height) * 0.5)
			rect = CGRect(origin: point, size: scaledSize).integral
		}
		
		// Actually do the resizing to the rect using the ImageContext stuff
		UIGraphicsBeginImageContextWithOptions(ctxSize, false, image.scale)
		
		// Can be bottom or right background borders
		if !scaleToFill {
			// Make solid color background:
			//UIColor.black.setFill()
			//UIRectFill(rect)
		}
		
		image.draw(in: rect)
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return newImage
	}
	
	static func rotate(image: UIImage, degrees: CGFloat) -> UIImage? {
		// Calculate the size of the rotated view's containing box for our drawing space
		let rotatedViewBox: UIView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height))
		let rotation: CGAffineTransform = CGAffineTransform(rotationAngle: self.angle(degrees: degrees))
		rotatedViewBox.transform = rotation
		let rotatedSize: CGSize = rotatedViewBox.frame.size
		
		// Create the bitmap context
		UIGraphicsBeginImageContextWithOptions(rotatedSize, false, image.scale)
		if let context = UIGraphicsGetCurrentContext() {
			
			// Move the origin to the middle of the image so we will rotate and scale around the center.
			context.translateBy(x: rotatedSize.width/2, y: rotatedSize.height/2)
			
			// Rotate the image context
			context.rotate(by: self.angle(degrees: degrees))
			
			// Now, draw the rotated/scaled image into the context
			context.scaleBy(x: 1.0, y: -1.0)
			
			if let cgImage = image.cgImage {
				context.draw(cgImage, in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
				
				let newImage = UIGraphicsGetImageFromCurrentImageContext()
				UIGraphicsEndImageContext()
				
				return newImage
			}
		}
		return nil
	}
	
	// FIXME: Not tested
	static func rotate(_ image: UIImage, orientation: UIImage.Orientation) -> UIImage? {
		guard let cgImage = image.cgImage else { return nil }
		
		let orient: UIImage.Orientation
		var transform: CGAffineTransform = .identity
		
		let width = image.size.width
		let height = image.size.height
		var bounds: CGRect = CGRect(x: 0.0, y: 0.0, width: width, height: height)
		let imageSize: CGSize = image.size;
		let boundHeight: CGFloat
		
		switch orientation {
		case .up:
			orient = .left
		case .upMirrored:
			orient = .leftMirrored
		case .down:
			orient = .right
		case .downMirrored:
			orient = .rightMirrored;
		case .right:
			orient = .up;
		case .rightMirrored:
			orient = .upMirrored;
		case .left:
			orient = .down;
		case .leftMirrored:
			orient = .downMirrored;
		}
		
		switch(orient) {
		case .up: //EXIF = 1 - OK
			break
		case .upMirrored: //EXIF = 2 - OK
			transform = transform.translatedBy(x: imageSize.width, y: 0.0)
			transform = transform.scaledBy(x: -1.0, y: 1.0)
		case .down: //EXIF = 3 - OK
			transform = transform.translatedBy(x: imageSize.width, y: imageSize.height)
			transform = transform.rotated(by: CGFloat.pi)
		case .downMirrored: //EXIF = 4 - OK
			transform = transform.translatedBy(x: 0.0, y: imageSize.height)
			transform = transform.scaledBy(x: 1.0, y: -1.0)
		case .rightMirrored: //EXIF = 5
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
			transform = transform.scaledBy(x: -1.0, y: 1.0)
			transform = transform.rotated(by: -CGFloat.pi / 2.0)
		case .right: //EXIF = 6
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransform(translationX: 0.0, y: imageSize.width)
			transform = transform.rotated(by: -CGFloat.pi / 2.0)
		case .leftMirrored: //EXIF = 7
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
			transform = transform.rotated(by: CGFloat.pi / 2.0)
		case .left: //EXIF = 8
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
			transform = transform.rotated(by: CGFloat.pi / 2.0)
		}
		
		UIGraphicsBeginImageContextWithOptions(bounds.size, false, image.scale)
		let context: CGContext = UIGraphicsGetCurrentContext()!
		
		context.concatenate(transform)
		context.scaleBy(x: 1.0, y: -1.0)
		context.translateBy(x: 0.0, y: -imageSize.height)
		
		context.draw(cgImage, in: CGRect(x: 0.0, y: 0.0, width: width, height: height))
		let resultImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return resultImage;
	}
	
	static func convertToGrayScale(_ image: UIImage) -> UIImage? {
		guard let cgImage = image.cgImage else { return nil }
		
		let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height:  image.size.height)
		
		// Convert to grayscale without alpha-channel
		let colorSpace = CGColorSpaceCreateDeviceGray()
		
		if let context = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) {
			
			context.draw(cgImage, in: imageRect)
			
			guard let imageRef = context.makeImage() else { return nil }
			
			// Convert to alpha-channel
			
			if let context = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) {
				context.draw(cgImage, in: imageRect)
				
				guard let mask = context.makeImage() else { return nil }
				
				// Create resulting image
				if let resultImage = imageRef.masking(mask) {
					return UIImage(cgImage: resultImage, scale: image.scale, orientation: image.imageOrientation)
				}
			}
		}
		return nil
	}
	
	// MARK: - Drawing
	
	// When images have different scale, then possible need to use multiplication to scale, see crop
	// But probabli draw operation uses correct scale by render, need to check it
	static func draw(image frontImage: UIImage, onImage backImage: UIImage) -> UIImage? {
		var frontImageSize: CGSize = frontImage.size
		var backImageSize: CGSize = backImage.size
		
		frontImageSize.width *= frontImage.scale
		frontImageSize.height *= frontImage.scale
		
		backImageSize.width *= backImage.scale
		backImageSize.height *= backImage.scale
		
		let size: CGSize = CGSize(width: max(frontImageSize.width, backImageSize.width), height: max(frontImageSize.height, backImageSize.height))
		
		// Create a new bitmap image context
		UIGraphicsBeginImageContextWithOptions(size, false, backImage.scale)
		
		
		let backImageRect = CGRect(x: (size.width - backImageSize.width) * 0.5, y: (size.height - backImageSize.height) * 0.5, width: backImageSize.width, height: backImageSize.height)
		
		let frontImageRect = CGRect(x: (size.width - frontImageSize.width) * 0.5, y: (size.height - frontImageSize.height) * 0.5, width: frontImageSize.width, height: frontImageSize.height)
		
		backImage.draw(in: backImageRect)
		frontImage.draw(in: frontImageRect)
		
		// Get a UIImage from the image context
		let img = UIGraphicsGetImageFromCurrentImageContext()
		
		// Clean up drawing environment
		UIGraphicsEndImageContext()
		
		return img
	}
	
	static func draw(image frontImage: UIImage, inImage backImage: UIImage) -> UIImage? {
		// Create a new bitmap image context
		UIGraphicsBeginImageContextWithOptions(backImage.size, false, backImage.scale)
		
		backImage.draw(in: CGRect(x: 0.0, y: 0.0, width: backImage.size.width, height: backImage.size.height))
		
		if let resizedFrontImg = ImageManager.resize(image: frontImage, fitSize: backImage.size) {
			let frontImageX: CGFloat = (backImage.size.width - resizedFrontImg.size.width) * 0.5
			let frontImageY: CGFloat = (backImage.size.height - resizedFrontImg.size.height) * 0.5
			resizedFrontImg.draw(in: CGRect(x: frontImageX, y: frontImageY, width: resizedFrontImg.size.width, height: resizedFrontImg.size.height))
		}
		
		// Get a UIImage from the image context
		let img = UIGraphicsGetImageFromCurrentImageContext()
		
		// Clean up drawing environment
		UIGraphicsEndImageContext()
		
		return img
	}
	
	static func solid(color: UIColor, size: CGSize) -> UIImage? {
		let rect: CGRect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
		
		var img:UIImage? = nil
		UIGraphicsBeginImageContextWithOptions(size, false, self.scaleFactor)
		if let context = UIGraphicsGetCurrentContext() {
			context.setFillColor(color.cgColor)
			context.fill(rect)
			
			img = UIGraphicsGetImageFromCurrentImageContext()
		}
		UIGraphicsEndImageContext()
		
		return img
	}
	
	static func gradient(from startColor: UIColor, to finishColor: UIColor, size: CGSize) -> UIImage? {
		let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
		
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = [startColor.cgColor, finishColor.cgColor]
		gradientLayer.bounds = rect
		
		var img:UIImage? = nil
		UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scaleFactor)
		if let context = UIGraphicsGetCurrentContext() {
			gradientLayer.render(in: context)
			img = UIGraphicsGetImageFromCurrentImageContext()
		}
		UIGraphicsEndImageContext()
		return img
	}
	
	// https://stackoverflow.com/questions/31314412/how-to-resize-image-in-swift
	// https://samwize.com/2016/06/01/resize-uiimage-in-swift/
	// https://nshipster.com/image-resizing/
	/// Create new image with clipping primitive and new image should be always in retina, because we need to have smoth border
	/// TODO: need to create clip image by using UIBezierPath
	static func roundImage(_ image: UIImage, borderWidth: CGFloat? = nil, borderColor: UIColor? = nil) -> UIImage? {
		let diameter: CGFloat = min(image.size.width, image.size.height)
		let originX: CGFloat = (image.size.width - diameter) * 0.5
		let originY: CGFloat = (image.size.height - diameter) * 0.5
		let cropRect = CGRect(x: originX, y: originY, width: diameter, height: diameter)
		
		var img:UIImage? = nil
		if  let croppedImage = crop(image: image, rect: cropRect) {
			let bounds = CGRect(x: 0.0, y: 0.0, width: diameter, height: diameter)
			
			// Perform processing operation by using scale factor of main screen/device
			// Use main screen/device scale factor to have smoth border lines!
			UIGraphicsBeginImageContextWithOptions(bounds.size, false, self.scaleFactor)
			if let context = UIGraphicsGetCurrentContext() {
				// Add a clip before drawing anything, in the shape of an rounded rect
				let path: UIBezierPath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.size.width * 0.5)
				path.addClip()
				
				// Draw your image
				croppedImage.draw(in: bounds)
				if let width = borderWidth, let color = borderColor {
					color.setStroke()
					context.setLineWidth(width)
					context.strokeEllipse(in: bounds)
				}
				
				img = UIGraphicsGetImageFromCurrentImageContext()
			}
			UIGraphicsEndImageContext()
			
			// When source image scale is different from main screnn/device scale and need to perform downscale need to uncomment following code
			// But previous operation implementation will have artifacts and steps (not clear image).
			/*
			if let processedImg = img, image.scale != processedImg.scale /*UIScreen.main.scale*/ {
			UIGraphicsBeginImageContextWithOptions(bounds.size, false, image.scale)
			processedImg.draw(in: bounds)
			img = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			}
			*/
		}
		return img
	}
	
	static func repeatHorizontal(image: UIImage, to size: CGSize, insets: UIEdgeInsets, clip: Bool, bkgColor: UIColor = .clear) -> UIImage? {
		let availableSize = CGSize(width: size.width - insets.left - insets.right, height: size.height - insets.top - insets.bottom)
		let minSide = min(availableSize.width, availableSize.height)
		let resizedImage: UIImage = self.resize(image: image, fitSize: CGSize(width: minSide, height: minSide))!
		let fullCount = Int(availableSize.width / resizedImage.size.width)
		let imageContextSize = CGSize(width: availableSize.width, height: resizedImage.size.height)
		
		if !clip {
			UIGraphicsBeginImageContextWithOptions(size, false, image.scale/*self.scaleFactor*/)////UIGraphicsBeginImageContext(size)
			if let context: CGContext = UIGraphicsGetCurrentContext() {
				context.translateBy(x: 0, y: size.height)
				context.scaleBy(x: 1.0, y: -1.0)
				
				context.setFillColor(bkgColor.cgColor)
				context.fill(CGRect(origin: .zero, size: size))
			}
			let imgCanvas = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
			
			UIGraphicsBeginImageContextWithOptions(imageContextSize, false, 1.0/*self.scaleFactor*/)//UIGraphicsBeginImageContext(imageContextSize)
			if let context: CGContext = UIGraphicsGetCurrentContext() {
				context.translateBy(x: 0, y: resizedImage.size.height)
				context.scaleBy(x: 1.0, y: -1.0)
				
				context.setFillColor(bkgColor.cgColor)
				context.fill(CGRect(origin: .zero, size: imageContextSize))
				
				context.draw(resizedImage.cgImage!, in: CGRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height), byTiling: true)
			}
			let img = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
			
			UIGraphicsBeginImageContextWithOptions(size, false, 1.0/*self.scaleFactor*/)//UIGraphicsBeginImageContext(size)
			imgCanvas.draw(at: .zero)
			img.draw(at: CGPoint(x: insets.left, y: insets.top))
			let imgResult = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
			
			return imgResult
		} else {
			return repeatHorizontal(image: resizedImage, repeat: fullCount, height: size.height, insets: insets, bkgColor: bkgColor)
		}
	}
	
	static func repeatHorizontal(image: UIImage, repeat count: Int, height: CGFloat, insets: UIEdgeInsets, bkgColor: UIColor = .clear) -> UIImage? {
		let availableHeight = height - insets.top - insets.bottom
		
		var resizedImage = image
		if availableHeight < image.size.height {
			resizedImage = self.resize(image: image, fitSize: CGSize(width: availableHeight, height: availableHeight))!
		}
		
		let imgCanvasContextSize = CGSize(width: resizedImage.size.width * CGFloat(count) + insets.left + insets.right, height: height)
		let imageContextSize = CGSize(width: resizedImage.size.width * CGFloat(count), height: resizedImage.size.height)
		
		UIGraphicsBeginImageContextWithOptions(imgCanvasContextSize, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(imgCanvasContextSize)
		if let context: CGContext = UIGraphicsGetCurrentContext() {
			context.translateBy(x: 0, y: height)
			context.scaleBy(x: 1.0, y: -1.0)
			
			context.setFillColor(bkgColor.cgColor)
			context.fill(CGRect(origin: .zero, size: imgCanvasContextSize))
		}
		let imgCanvas = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		
		UIGraphicsBeginImageContextWithOptions(imageContextSize, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(imageContextSize)
		if let context: CGContext = UIGraphicsGetCurrentContext() {
			context.translateBy(x: 0, y: resizedImage.size.height)
			context.scaleBy(x: 1.0, y: -1.0)
			
			context.setFillColor(bkgColor.cgColor)
			context.fill(CGRect(origin: .zero, size: imageContextSize))
			
			context.draw(resizedImage.cgImage!, in: CGRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height), byTiling: true)
		}
		let img = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		
		UIGraphicsBeginImageContextWithOptions(imgCanvasContextSize, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(imgCanvasContextSize)
		imgCanvas.draw(at: .zero)
		img.draw(at: CGPoint(x: insets.left, y: insets.top))
		let imgResult = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		
		return imgResult
	}
	
	static func repeatVertical(image: UIImage, to size: CGSize, insets: UIEdgeInsets, clip: Bool, bkgColor: UIColor = .clear) -> UIImage? {
		let availableSize = CGSize(width: size.width - insets.left - insets.right, height: size.height - insets.top - insets.bottom)
		let minSide = min(availableSize.width, availableSize.height)
		let resizedImage: UIImage = self.resize(image: image, fitSize: CGSize(width: minSide, height: minSide))!
		let fullCount = Int(availableSize.height / resizedImage.size.height)
		let imageContextSize = CGSize(width: resizedImage.size.width, height: availableSize.height)
		
		if !clip {
			UIGraphicsBeginImageContextWithOptions(size, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(size)
			if let context: CGContext = UIGraphicsGetCurrentContext() {
				context.translateBy(x: 0, y: size.height)
				context.scaleBy(x: 1.0, y: -1.0)
				
				context.setFillColor(bkgColor.cgColor)
				context.fill(CGRect(origin: .zero, size: size))
			}
			let imgCanvas = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
			
			UIGraphicsBeginImageContextWithOptions(imageContextSize, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(imageContextSize)
			if let context: CGContext = UIGraphicsGetCurrentContext() {
				context.translateBy(x: 0, y: resizedImage.size.height)
				context.scaleBy(x: 1.0, y: -1.0)
				
				context.setFillColor(bkgColor.cgColor)
				context.fill(CGRect(origin: .zero, size: imageContextSize))
				
				context.draw(resizedImage.cgImage!, in: CGRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height), byTiling: true)
			}
			let img = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
			
			UIGraphicsBeginImageContextWithOptions(size, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(size)
			imgCanvas.draw(at: .zero)
			img.draw(at: CGPoint(x: insets.left, y: insets.top))
			let imgResult = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()
			
			return imgResult
		} else {
			return repeatVertical(image: resizedImage, repeat: fullCount, width: size.width, insets: insets, bkgColor: bkgColor)
		}
	}
	
	static func repeatVertical(image: UIImage, repeat count: Int, width: CGFloat, insets: UIEdgeInsets, bkgColor: UIColor = .clear) -> UIImage? {
		let availableWidth = width - insets.left - insets.right
		let resizedImage = self.resize(image: image, fitSize: CGSize(width: availableWidth, height: availableWidth))!
		let imgCanvasContextSize = CGSize(width: width, height: resizedImage.size.height * CGFloat(count) + insets.top + insets.bottom)
		let imageContextSize = CGSize(width: resizedImage.size.width, height: resizedImage.size.height * CGFloat(count))
		
		UIGraphicsBeginImageContextWithOptions(imgCanvasContextSize, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(imgCanvasContextSize)
		if let context: CGContext = UIGraphicsGetCurrentContext() {
			context.translateBy(x: 0, y: imgCanvasContextSize.height)
			context.scaleBy(x: 1.0, y: -1.0)
			
			context.setFillColor(bkgColor.cgColor)
			context.fill(CGRect(origin: .zero, size: imgCanvasContextSize))
		}
		let imgCanvas = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		
		UIGraphicsBeginImageContextWithOptions(imageContextSize, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(imageContextSize)
		if let context: CGContext = UIGraphicsGetCurrentContext() {
			context.translateBy(x: 0, y: imageContextSize.height)
			context.scaleBy(x: 1.0, y: -1.0)
			
			context.setFillColor(bkgColor.cgColor)
			context.fill(CGRect(origin: .zero, size: imageContextSize))
			
			context.draw(resizedImage.cgImage!, in: CGRect(x: 0, y: 0, width: resizedImage.size.width, height: resizedImage.size.height), byTiling: true)
		}
		let img = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		
		UIGraphicsBeginImageContextWithOptions(imgCanvasContextSize, false, image.scale/*self.scaleFactor*/)//UIGraphicsBeginImageContext(imgCanvasContextSize)
		imgCanvas.draw(at: .zero)
		img.draw(at: CGPoint(x: insets.left, y: insets.top))
		let imgResult = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		
		return imgResult
	}
	
	// MARK: - Mask methods
	
	/// Mask should be created in screen/device scale factor, i.e. retina & etc.
	static func rectMask(rect: CGRect, size: CGSize, inverted: Bool) -> UIImage?
	{
		let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
		
		// Create a bitmap graphics context the size of the image
		// kCGImageAlphaPremultipliedLast
		if let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
			
			// Creating mask image
			
			// Drawing clipping rect
			context.addRect(CGRect(x: rect.origin.x, y: size.height - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height))
			
			if inverted {
				
				// Clip unfilled rect
				context.addRect(context.boundingBoxOfClipPath)
				context.closePath()
				context.clip(using: .evenOdd)
				
				// Drawing filled rect
				context.addRect(CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
			}
			
			context.closePath()
			context.setFillColor(UIColor.white.cgColor)
			context.fillPath()
			
			// Get a UIImage from the image context clean up drawing environment
			guard let imageRef = context.makeImage() else { return nil }
			return UIImage(cgImage: imageRef, scale: self.scaleFactor, orientation: .up)
		}
		return nil
	}
	
	/// Mask should be created in screen/device scale factor, i.e. retina & etc.
	static func circleMask(in rect: CGRect, size: CGSize, inverted: Bool) -> UIImage? {
		let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
		
		// Create a bitmap graphics context the size of the image
		// kCGImageAlphaPremultipliedLast
		if let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
			// Creating mask image
			
			// Drawing clipping circle
			context.addEllipse(in: CGRect(x: rect.origin.x, y: size.height - rect.origin.y - rect.size.height, width: rect.size.width, height: rect.size.height))
			
			if inverted {
				
				// Clip unfilled rect
				context.addRect(context.boundingBoxOfClipPath)
				context.closePath()
				context.clip(using: .evenOdd)
				
				// Drawing filled rect
				context.addRect(CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
			}
			
			context.closePath()
			context.setFillColor(UIColor.white.cgColor)
			context.fillPath()
			
			// Get a UIImage from the image context clean up drawing environment
			guard let imageRef = context.makeImage() else { return nil }
			return UIImage(cgImage: imageRef, scale: self.scaleFactor, orientation: .up)
		}
		return nil
	}
	
	/// Apply mask to image & return result image with applied mask. I.e. size, scale & orientation will be as in original image
	static func mask(image: UIImage, with mask: UIImage) -> UIImage? {
		if let cgImage = image.cgImage, let cgMask = mask.cgImage, let dataProvider = cgMask.dataProvider {
			if let mask = CGImage(
				maskWidth: cgMask.width,
				height: cgMask.height,
				bitsPerComponent: cgMask.bitsPerComponent,
				bitsPerPixel: cgMask.bitsPerPixel,
				bytesPerRow: cgMask.bytesPerRow,
				provider: dataProvider,
				decode: nil,
				shouldInterpolate: true
				) {
				if let maskedImage = cgImage.masking(mask) {
					return UIImage(cgImage: maskedImage, scale: image.scale, orientation: image.imageOrientation)
				}
			}
		}
		return nil
	}
	
	// MARK: - "Threadsafe Methods"
	
	static func crop(image: UIImage, rect: CGRect) -> UIImage? {
		// cgImage cropping method works with pixel representation of image, but image have size divided to it scale, i.e. when image size = 200x100 and it scale = 2.0, then cgImage size will by 400x200 pixels
		if let croppedCGImage = (image.cgImage?.cropping(to: CGRect(x: rect.origin.x * image.scale, y: rect.origin.y * image.scale, width: rect.size.width * image.scale, height: rect.size.height * image.scale))) {
			return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
		}
		return nil
	}
	
}
