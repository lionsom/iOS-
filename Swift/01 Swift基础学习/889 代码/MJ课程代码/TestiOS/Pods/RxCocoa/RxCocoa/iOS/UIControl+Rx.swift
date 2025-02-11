//
//  UIControl+Rx.swift
//  RxCocoa
//
//  Created by Daniel Tartaglia on 5/23/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

    import RxSwift
    import UIKit

    public extension Reactive where Base: UIControl {
        /// Bindable sink for `enabled` property.
        var isEnabled: Binder<Bool> {
            return Binder(base) { control, value in
                control.isEnabled = value
            }
        }

        /// Bindable sink for `selected` property.
        var isSelected: Binder<Bool> {
            return Binder(base) { control, selected in
                control.isSelected = selected
            }
        }

        /// Reactive wrapper for target action pattern.
        ///
        /// - parameter controlEvents: Filter for observed event types.
        func controlEvent(_ controlEvents: UIControl.Event) -> ControlEvent<Void> {
            let source: Observable<Void> = Observable.create { [weak control = self.base] observer in
                MainScheduler.ensureRunningOnMainThread()

                guard let control = control else {
                    observer.on(.completed)
                    return Disposables.create()
                }

                let controlTarget = ControlTarget(control: control, controlEvents: controlEvents) { _ in
                    observer.on(.next(()))
                }

                return Disposables.create(with: controlTarget.dispose)
            }
            .takeUntil(deallocated)

            return ControlEvent(events: source)
        }

        /// Creates a `ControlProperty` that is triggered by target/action pattern value updates.
        ///
        /// - parameter controlEvents: Events that trigger value update sequence elements.
        /// - parameter getter: Property value getter.
        /// - parameter setter: Property value setter.
        func controlProperty<T>(
            editingEvents: UIControl.Event,
            getter: @escaping (Base) -> T,
            setter: @escaping (Base, T) -> Void
        ) -> ControlProperty<T> {
            let source: Observable<T> = Observable.create { [weak weakControl = base] observer in
                guard let control = weakControl else {
                    observer.on(.completed)
                    return Disposables.create()
                }

                observer.on(.next(getter(control)))

                let controlTarget = ControlTarget(control: control, controlEvents: editingEvents) { _ in
                    if let control = weakControl {
                        observer.on(.next(getter(control)))
                    }
                }

                return Disposables.create(with: controlTarget.dispose)
            }
            .takeUntil(deallocated)

            let bindingObserver = Binder(base, binding: setter)

            return ControlProperty<T>(values: source, valueSink: bindingObserver)
        }

        /// This is a separate method to better communicate to public consumers that
        /// an `editingEvent` needs to fire for control property to be updated.
        internal func controlPropertyWithDefaultEvents<T>(
            editingEvents: UIControl.Event = [.allEditingEvents, .valueChanged],
            getter: @escaping (Base) -> T,
            setter: @escaping (Base, T) -> Void
        ) -> ControlProperty<T> {
            return controlProperty(
                editingEvents: editingEvents,
                getter: getter,
                setter: setter
            )
        }
    }

#endif
