// Copyright 2016 Yandex LLC. All rights reserved.

#if canImport(UIKit)
import CoreGraphics
import Foundation
import UIKit

public final class LinearGradientView: UIView {
  private var gradientLayer: LinearGradientLayer {
    layer as! LinearGradientLayer
  }

  public func set(gradient: Gradient.Linear) {
    gradientLayer.gradient = gradient
  }

  public init(_ gradient: Gradient.Linear) {
    super.init(frame: .zero)
    set(gradient: gradient)
    isOpaque = false
    layer.needsDisplayOnBoundsChange = true
  }

  public convenience init(
    startColor: Color,
    endColor: Color,
    direction: Gradient.Linear.Direction
  ) {
    self.init(.init(
      startColor: startColor,
      endColor: endColor,
      direction: direction
    ))
  }

  @available(*, unavailable)
  public required init(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override class var layerClass: AnyClass {
    LinearGradientLayer.self
  }
}

// https://stackoverflow.com/questions/38821631/cagradientlayer-diagonal-gradient/43176174
public final class LinearGradientLayer: CALayer {
  public var gradient: Gradient.Linear? {
    didSet {
      guard gradient != oldValue else { return }
      setNeedsDisplay()
    }
  }

  public override func draw(in ctx: CGContext) {
    guard let gradient else {
      return
    }

    guard let cgGradient = CGGradient(
      colorsSpace: CGColorSpaceCreateDeviceRGB(),
      colors: gradient.colors.map(\.cgColor) as CFArray,
      locations: gradient.locations
    ) else {
      assertionFailure()
      return
    }

    let (startPoint, endPoint) = switch gradient.direction {
    case let .angle(angle):
      bounds.gradientDelta(angle: angle)
    case let .relative(from: from, to: to):
      (from.absolutePosition(in: bounds), to.absolutePosition(in: bounds))
    }

    ctx.drawLinearGradient(
      cgGradient,
      start: startPoint,
      end: endPoint,
      options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
  }
}

extension CGRect {
  fileprivate func gradientDelta(
    angle: Double
  ) -> (startPoint: CGPoint, endPoint: CGPoint) {
    let halfWidth = width / 2
    let halfHeight = height / 2

    let angleRad = angle / 180.0 * .pi
    let gradientWidth = abs(width * cos(angleRad)) + abs(height * sin(angleRad))
    let widthDelta = (cos(angleRad) * gradientWidth / 2)
    let heightDelta = (sin(angleRad) * gradientWidth / 2)

    return (
      CGPoint(x: halfWidth - widthDelta, y: halfHeight + heightDelta),
      CGPoint(x: halfWidth + widthDelta, y: halfHeight - heightDelta)
    )
  }
}
#endif
