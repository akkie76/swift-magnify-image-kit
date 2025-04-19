//
//  MagnifyImageView.swift
//  ZoomableSample
//
//  Created by Akihiko Sato on 2025/04/19.
//

import SwiftUI
import UIKit

public struct MagnifyImageView: UIViewRepresentable {
  public let image: UIImage
  
  public init(image: UIImage) {
    self.image = image
  }
  
  public func makeUIView(context: Context) -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.delegate = context.coordinator
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 3.0
    scrollView.bouncesZoom = true
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    
    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    
    scrollView.addSubview(imageView)
    context.coordinator.imageView = imageView
    
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
      imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
    ])
    
    let doubleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleDoubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    scrollView.addGestureRecognizer(doubleTapGesture)
    
    let singleTapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleSingleTap(_:)))
    singleTapGesture.numberOfTapsRequired = 1
    
    singleTapGesture.require(toFail: doubleTapGesture)
    scrollView.addGestureRecognizer(singleTapGesture)
    
    context.coordinator.scrollView = scrollView
    context.coordinator.imageView = imageView
    
    return scrollView
  }
  
  public func updateUIView(_ uiView: UIScrollView, context: Context) {
    context.coordinator.updateContentInset(in: uiView)
  }
  
  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  
  public class Coordinator: NSObject, UIScrollViewDelegate {
    weak var scrollView: UIScrollView?
    weak var imageView: UIImageView?

    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
      guard let scrollView = scrollView, let imageView = imageView else {
        return
      }
      
      if abs(scrollView.zoomScale - scrollView.minimumZoomScale) < 0.01 {
        let tapPoint = sender.location(in: imageView)
        
        let doubleTapZoomScale = 3.0
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
      updateContentInset(in: scrollView)
    }

    fileprivate func updateContentInset(in scrollView: UIScrollView) {
      guard let iv = imageView else { return }
      let insetX = max((scrollView.bounds.width  - scrollView.contentSize.width)  / 2, 0)
      let insetY = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
      scrollView.contentInset = UIEdgeInsets(
        top:    insetY,
        left:   insetX,
        bottom: insetY,
        right:  insetX
      )
    }
  }
}
