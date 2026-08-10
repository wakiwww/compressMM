import Foundation

// MARK: - 线程安全原子布尔值

/// 可在任意线程安全读写的布尔标志。
/// 使用 NSLock 保护，避免多线程数据竞争（Data Race）。
/// 标记为 @unchecked Sendable 是因为锁已保证内部一致性。
final class AtomicBool: @unchecked Sendable {
    private var _value: Bool
    private let lock = NSLock()

    init(_ value: Bool = false) {
        _value = value
    }

    var value: Bool {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}
