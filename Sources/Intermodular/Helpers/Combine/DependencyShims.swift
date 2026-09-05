// Stand-ins for the Merge and Swallow helpers upstream Coordinator uses, so this fork depends on SwiftUIX only.

import Combine
import Foundation
import os

extension Publisher {
    func handleOutput(_ receiveOutput: @escaping (Output) -> Void) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: receiveOutput)
    }

    func onOutput(do action: @autoclosure @escaping () -> Void) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { _ in action() })
    }

    /// Subscribes and keeps the subscription alive until the publisher completes.
    func retainSink() {
        var cancellable: AnyCancellable?
        cancellable = sink(receiveCompletion: { _ in cancellable = nil }, receiveValue: { _ in })
    }
}

extension AnyPublisher {
    static func failure(_ failure: Failure) -> Self {
        Fail(error: failure).eraseToAnyPublisher()
    }
}

extension Future {
    static func just(_ result: Result<Output, Failure>) -> Future<Output, Failure> {
        Future { promise in
            promise(result)
        }
    }
}

struct UnwrappingError: Error {}

extension Optional {
    func unwrap() throws -> Wrapped {
        guard let wrapped = self else {
            throw UnwrappingError()
        }
        return wrapped
    }
}

public enum RuntimeIssueReason: Error {
    case unavailable
}

private let runtimeIssueLog = OSLog(subsystem: "com.apple.runtime-issues", category: "Coordinator")

public func runtimeIssue(_ message: String) {
    os_log(.fault, log: runtimeIssueLog, "%{public}s", message)
}

@discardableResult
public func runtimeIssue(_ error: Error) -> Error {
    runtimeIssue(String(describing: error))
    return error
}

@discardableResult
public func runtimeIssue(_ reason: RuntimeIssueReason) -> Error {
    runtimeIssue(reason as Error)
}

struct _PlaceholderError: Error {}

extension Publisher {
    func handleSubscription(_ receiveSubscription: @escaping (Subscription) -> Void) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveSubscription: receiveSubscription)
    }
}

final class Cancellables {
    private var cancellables = Set<AnyCancellable>()

    func insert(_ cancellable: AnyCancellable) {
        cancellables.insert(cancellable)
    }
}

extension Publisher {
    func subscribe<S: Subject>(_ subject: S, in cancellables: Cancellables) where S.Output == Output, S.Failure == Failure {
        cancellables.insert(subscribe(subject))
    }
}

protocol PropertyWrapper {
    associatedtype WrappedValue

    var wrappedValue: WrappedValue { get }
}
