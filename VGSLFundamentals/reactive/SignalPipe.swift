// Copyright 2018 Yandex LLC. All rights reserved.
public struct SignalPipe<T> {
  private let bag = Bag<Observer<T>>()
  public let signal: Signal<T>

  public init() {
    signal = Signal(addObserver: { [weak bag] observer in
      bag?.add(observer) ?? Disposable()
    })
  }

  public func send(_ value: T) {
    bag.forEach { observer in
      let action = observer.action
      action(value)
    }
  }
}

extension SignalPipe where T == Void {
  public func send() { send(()) }
}

private class Bag<T> {
  private final class Container {
    var payload: T?

    init(payload: T) {
      self.payload = payload
    }
  }

  private typealias Key = UInt64
  private var counter: Key = 0
  private var items: [Key: Container] = [:]

  fileprivate init() {}

  fileprivate func add(_ item: T) -> Disposable {
    let key = counter
    counter += 1
    items[key] = Container(payload: item)
    return Disposable { [weak self] in
      guard let self else { return }
      guard let value = self.items.removeValue(forKey: key) else { return }

      value.payload = nil
    }
  }

  fileprivate func forEach(_ block: (T) -> Void) {
    let values = items.values

    for item in values {
      if let payload = item.payload {
        block(payload)
      }
    }
  }
}
