import XCTest
@testable import AsyncHotStream

final class AsyncHotStreamTests: XCTestCase
{
    func testAsyncHotStream() async throws
    {
        let (hotStream, continuation) = AsyncStream<Int>.makeHotStream()

        let accumulator = Accumulator<Int>()

        let consumerTask = Task {
            for await x in hotStream {
                var values = await accumulator.values
                values.append(x)
                await accumulator.update(values: values)
            }
            await accumulator.update(isCompleted: true)
        }

        // Comment-Out:
        // Other task can't await on same `stream`.
        // Otherwise, "Fatal error: attempt to await next() on more than one task" will occur.
//        let task1b = Task {
//            for await x in stream {
//                print(x)
//            }
//        }

        let loopCount = 3
        let concurrentCount = 3

        let producerTask = Task {
            for i in 1 ... loopCount {
                // try await Task.sleep(nanoseconds: 100_000_000)

                // Concurrent produce.
                await withTaskGroup(of: Void.self) { group in
                    for _ in 1 ... concurrentCount {
                        group.addTask {
                            continuation.yield(i)
                        }
                    }
                }

                let (values, isCompleted) = await (accumulator.values, accumulator.isCompleted)
                XCTAssertEqual(values, (1 ... i).flatMap { Array.init(repeating: $0, count: concurrentCount) })
                XCTAssertFalse(isCompleted)
            }

            continuation.finish()

            // NOTE: Needs a bit of delay to check for `isCompleted`.
            try await Task.sleep(nanoseconds: 100_000_000)

            let (values, isCompleted) = await (accumulator.values, accumulator.isCompleted)
            XCTAssertEqual(values, (1 ... loopCount).flatMap { Array.init(repeating: $0, count: concurrentCount) })
            XCTAssertTrue(isCompleted)
        }

        async let result1: () = consumerTask.value
        async let result2: () = producerTask.value

        _ = try await (result1, result2)

        let reConsumerTask = Task {
            for await _ in hotStream {
                XCTFail("No calls because `hotStream` is already terminated")
            }
        }

        await reConsumerTask.value
    }
}

// MARK: - Private

private actor Accumulator<T>
{
    var values: [T] = []
    var isCompleted: Bool = false

    init() {}

    func update(values: [T]? = nil, isCompleted: Bool? = nil)
    {
        if let values = values {
            self.values = values
        }
        if let isCompleted = isCompleted {
            self.isCompleted = isCompleted
        }
    }
}
