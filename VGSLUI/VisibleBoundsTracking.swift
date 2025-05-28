// Copyright 2019 Yandex LLC. All rights reserved.

import CoreGraphics
import UIKit

public protocol VisibleBoundsTracking {
  func onVisibleBoundsChanged(from: CGRect, to: CGRect)
}

public protocol VisibleBoundsTrackingContainer: VisibleBoundsTracking {
  var visibleBoundsTrackingSubviews: [VisibleBoundsTrackingView] { get }
}

extension VisibleBoundsTrackingContainer where Self: UICoordinateSpace {
  @preconcurrency @MainActor
  public func passVisibleBoundsChanged(from: CGRect, to: CGRect) {
    guard !from.isEmpty || !to.isEmpty else {
      return
    }
    visibleBoundsTrackingSubviews.forEach {
      let fromFrame = convert(from, to: $0)
      let toFrame = convert(to, to: $0)

      $0.onVisibleBoundsChanged(
        from: $0.bounds.intersection(fromFrame),
        to: $0.bounds.intersection(toFrame)
      )
    }
  }

  @preconcurrency @MainActor
  public func onVisibleBoundsChanged(from: CGRect, to: CGRect) {
    passVisibleBoundsChanged(from: from, to: to)
  }
}

public protocol VisibleBoundsTrackingLeaf: VisibleBoundsTracking {}

extension VisibleBoundsTrackingLeaf {
  public func onVisibleBoundsChanged(from _: CGRect, to _: CGRect) {}
}

public typealias VisibleBoundsTrackingView = UIView & VisibleBoundsTracking

public final class VisibileBoundsTrackingRoot: UIView {
  public var content: (VisibleBoundsTracking & UIView)? {
    didSet {
      if window != nil, let oldValue {
        oldValue.onVisibleBoundsChanged(from: oldValue.bounds, to: .zero)
      }
      oldValue?.removeFromSuperview()
      addSubviews(content.asArray())
      setNeedsLayout()
    }
  }

  public override var intrinsicContentSize: CGSize {
    content?.intrinsicContentSize ?? .zero
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    guard let content else { return }
    let oldBounds = content.bounds
    content.frame = bounds
    content.onVisibleBoundsChanged(from: oldBounds, to: content.bounds)
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    guard let content else { return }

    if window == nil {
      content.onVisibleBoundsChanged(from: content.bounds, to: .zero)
    } else {
      content.onVisibleBoundsChanged(from: .zero, to: content.bounds)
    }
  }
}
