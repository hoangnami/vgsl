// Copyright 2016 Yandex LLC. All rights reserved.

import Foundation

@frozen
public enum ModelReusability<Object> {
  case orphan
  case hasReusableObject(Object)
}

extension ModelReusability: Sendable where Object: Sendable {}

public struct ReuseResult<Object, Model> {
  public let modelsReusability: [(Model, ModelReusability<Object>)]
  public let orphanObjects: [Object]

  public init(modelsReusability: [(Model, ModelReusability<Object>)], orphanObjects: [Object]) {
    self.modelsReusability = modelsReusability
    self.orphanObjects = orphanObjects
  }
}

extension ReuseResult: Sendable where Object: Sendable, Model: Sendable {}

@inlinable
public func calculateReusabilityFor<R, M>(
  _ objects: [R],
  with models: [M],
  canBeReused: (R, M) -> Bool
) -> ReuseResult<R, M> {
  var orphanObjects = objects

  let modelsReusability: [(M, ModelReusability<R>)] = models.map { model in
    guard let (index, reusedObject) = zip(orphanObjects.indices, orphanObjects)
      .first(where: { canBeReused($0.1, model) }) else {
      return (model, .orphan)
    }

    orphanObjects.remove(at: index)
    return (model, .hasReusableObject(reusedObject))
  }

  return ReuseResult(
    modelsReusability: modelsReusability,
    orphanObjects: orphanObjects
  )
}
