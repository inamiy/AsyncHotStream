extension AsyncStream
{
    /// Creates "multiple-producer (sender), single-consumer (receiver)" hot-stream by returning 2-tuple:
    /// 1. `AsyncStream` as `for await`-able receiver
    /// 2. `Continuation` as `yield`-able sender
    public static func makeHotStream() -> (Self, Self.Continuation)
    {
        let hot = AsyncHotStream<Element>()
        return (hot.values, hot.continuation)
    }

    /// Creates non-terminal "multiple-producer (sender), single-consumer (receiver)" hot-stream by returning 2-tuple:
    /// 1. `AsyncStream` as `for await`-able receiver
    /// 2. `Continuation` as `yield`-able sender
    public static func makeNonTerminalHotStream() -> (Self, (Element) -> Self.Continuation.YieldResult)
    {
        let hot = AsyncHotStream<Element>()
        return (hot.values, hot.continuation.yield)
    }
}

extension AsyncStream: @unchecked Sendable {}

// MARK: - Private

private struct AsyncHotStream<Element>: Sendable
{
    let values: AsyncStream<Element>

    private let boxedContinuation: BoxedContinuation

    init()
    {
        let boxedContinuation = BoxedContinuation()
        self.boxedContinuation = boxedContinuation

        self.values = AsyncStream { continuation in
            boxedContinuation.value = continuation
        }
    }

    var continuation: AsyncStream<Element>.Continuation
    {
        boxedContinuation.value!
    }
}

extension AsyncHotStream
{
    private final class BoxedContinuation: @unchecked Sendable
    {
        var value: AsyncStream<Element>.Continuation?

        init(_ value: AsyncStream<Element>.Continuation? = nil) {
            self.value = value
        }
    }
}
