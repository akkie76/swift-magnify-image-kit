//
//  MagnifyImageView.swift
//  MagnifyImageKit
//
//  A UIViewRepresentable that provides pinch‑to‑zoom and double‑tap zooming
//  for UIImage in SwiftUI by wrapping UIScrollView + UIImageView.
//
//  Copyright (c) 2025 Akihiko Sato
//  Released under the MIT License.
//  See LICENSE file in the project root for full license information.
//

import SwiftUI
import UIKit

public struct MagnifyImageView: UIViewRepresentable {
  private let image: UIImage
  private let viewSize: CGSize?

  private var maximumZoomScale: CGFloat = 3.0
  private var minimumZoomScale: CGFloat = 1.0
  private var zoomScale: CGFloat = 1.0
  private var doubleTapZoomScale: CGFloat = 2.0
  private var showsHorizontalScrollIndicator: Bool = false
  private var showsVerticalScrollIndicator: Bool = false
  private var alwaysBounceVertical: Bool = false
  private var alwaysBounceHorizontal: Bool = false
  private var contentMode: UIView.ContentMode = .scaleAspectFit

  private var scrollViewFrame: CGRect {
    if let viewSize = viewSize {
      return CGRect(x: 0, y: 0, width: viewSize.width, height: viewSize.height)
    }
    if #available(iOS 13.0, *) {
      let window = UIApplication.shared.connectedScenes.first as? UIWindowScene
      return if let window = window { window.screen.bounds } else {
        CGRect.zero
      }
    }
    return CGRect.zero
  }

  public init(image: UIImage, viewSize: CGSize? = nil) {
    self.image = image
    self.viewSize = viewSize
  }

  public func makeUIView(context: Context) -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.frame = scrollViewFrame
    scrollView.delegate = context.coordinator
    scrollView.maximumZoomScale = maximumZoomScale
    scrollView.minimumZoomScale = minimumZoomScale
    scrollView.zoomScale = zoomScale
    scrollView.bouncesZoom = true
    scrollView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
    scrollView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
    scrollView.alwaysBounceVertical = alwaysBounceVertical
    scrollView.alwaysBounceHorizontal = alwaysBounceHorizontal

    let imageView = UIImageView(image: image)
    imageView.contentMode = contentMode
    imageView.isUserInteractionEnabled = true

    scrollView.addSubview(imageView)
    context.coordinator.imageView = imageView

    let doubleTapGesture = UITapGestureRecognizer(
      target: context.coordinator,
      action: #selector(context.coordinator.handleDoubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    scrollView.addGestureRecognizer(doubleTapGesture)

    let singleTapGesture = UITapGestureRecognizer(
      target: context.coordinator,
      action: #selector(context.coordinator.handleSingleTap(_:)))
    singleTapGesture.numberOfTapsRequired = 1

    singleTapGesture.require(toFail: doubleTapGesture)
    scrollView.addGestureRecognizer(singleTapGesture)

    context.coordinator.scrollView = scrollView
    context.coordinator.imageView = imageView
    context.coordinator.doubleTapZoomScale = doubleTapZoomScale
    context.coordinator.updateContent()

    return scrollView
  }

  public func updateUIView(_ uiView: UIScrollView, context: Context) {
    context.coordinator.updateContent(isViewUpdated: true)
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public class Coordinator: NSObject, UIScrollViewDelegate {
    weak var scrollView: UIScrollView?
    weak var imageView: UIImageView?
    var doubleTapZoomScale: CGFloat = 0.0

    func updateContent(isViewUpdated: Bool = false) {
      guard let scrollView = scrollView, let imageView = imageView,
        let image = imageView.image
      else { return }

      // Apply pending layout changes to make sure scrollView.bounds is accurate
      scrollView.layoutIfNeeded()

      if scrollView.bounds.width <= 0 || scrollView.bounds.height <= 0 {
        DispatchQueue.main.async { [weak self] in
          self?.updateContent(isViewUpdated: isViewUpdated)
        }
        return
      }

      if image.size.width <= 0 || image.size.height <= 0 {
        return
      }

      let boundsSize = scrollView.bounds.size
      let imageSize = image.size

      let widthScale = boundsSize.width / imageSize.width
      let heightScale = boundsSize.height / imageSize.height
      let minScale = min(widthScale, heightScale)

      let safeMinScale = max(minScale, 0.1)

      scrollView.minimumZoomScale = safeMinScale

      if isViewUpdated || abs(scrollView.zoomScale - 1.0) < 0.01 {
        scrollView.zoomScale = safeMinScale
      }

      let scaledImageSize = CGSize(
        width: imageSize.width * scrollView.zoomScale,
        height: imageSize.height * scrollView.zoomScale
      )
      imageView.frame = CGRect(origin: .zero, size: scaledImageSize)

      scrollView.contentSize = imageView.frame.size

      updateContentInset()
    }

    private func updateContentInset() {
      guard let scrollView = scrollView else { return }
      let insetX = max(
        (scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
      let insetY = max(
        (scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
      scrollView.contentInset = UIEdgeInsets(
        top: insetY, left: insetX, bottom: insetY, right: insetX)
    }

    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
      guard let scrollView = scrollView, let imageView = imageView else {
        return
      }

      if abs(scrollView.zoomScale - scrollView.minimumZoomScale) < 0.01 {
        let tapPoint = sender.location(in: imageView)

        let zoomRectWidth = scrollView.bounds.width / doubleTapZoomScale
        let zoomRectHeight = scrollView.bounds.height / doubleTapZoomScale

        let zoomRect = CGRect(
          x: tapPoint.x - (zoomRectWidth / 2),
          y: tapPoint.y - (zoomRectHeight / 2),
          width: zoomRectWidth,
          height: zoomRectHeight
        )

        scrollView.zoom(to: zoomRect, animated: true)
      } else {
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
      }
    }

    @objc func handleSingleTap(_ sender: UITapGestureRecognizer) {
      guard let scrollView = scrollView, imageView != nil else {
        return
      }

      if scrollView.zoomScale > scrollView.minimumZoomScale {
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
      }
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return imageView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
      updateContentInset()
    }
  }
}

extension MagnifyImageView {
  public func maximumZoomScale(_ maximumZoomScale: CGFloat) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.maximumZoomScale = maximumZoomScale
    return magnifyImageView
  }

  public func minimumZoomScale(_ minimumZoomScale: CGFloat) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.minimumZoomScale = minimumZoomScale
    return magnifyImageView
  }

  public func zoomScale(_ zoomScale: CGFloat) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.zoomScale = zoomScale
    return magnifyImageView
  }

  public func doubleTapZoomScale(_ doubleTapZoomScale: CGFloat) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.doubleTapZoomScale = doubleTapZoomScale
    return magnifyImageView
  }

  public func showsHorizontalScrollIndicator(_ showsIndicator: Bool) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.showsHorizontalScrollIndicator = showsIndicator
    return magnifyImageView
  }

  public func showsVerticalScrollIndicator(_ showsIndicator: Bool) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.showsVerticalScrollIndicator = showsIndicator
    return magnifyImageView
  }

  public func alwaysBounceVertical(_ alwaysBounceVertical: Bool) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.alwaysBounceVertical = alwaysBounceVertical
    return magnifyImageView
  }

  public func alwaysBounceHorizontal(_ alwaysBounceHorizontal: Bool) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.alwaysBounceHorizontal = alwaysBounceHorizontal
    return magnifyImageView
  }

  public func contentMode(_ contentMode: UIView.ContentMode) -> MagnifyImageView {
    var magnifyImageView = self
    magnifyImageView.contentMode = contentMode
    return magnifyImageView
  }
}
