//
// Copyright (c) Vatsal Manot
//

#if os(iOS) || targetEnvironment(macCatalyst)

import Combine
import SwiftUI

@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
private struct KeyboardAvoidance: ViewModifier {
    let isSimple: Bool
    let animation: Animation?
    
    @State var padding: CGFloat = 0
    
    func body(content: Content) -> some View {
        Group {
            if isSystemEnabled {
                content
            } else {
                GeometryReader { geometry in
                    content
                        .padding(.bottom, self.padding)
                        .onReceive(self.keyboardHeightPublisher, perform: { (keyboardHeight: CGFloat) in
                            if self.isSimple {
                                self.padding = keyboardHeight > 0 ? keyboardHeight - geometry.safeAreaInsets.bottom : 0
                            } else {
                                let leftCalc: CGFloat = UIResponder.firstResponder?.globalFrame?.maxY ?? 0
                                let rightCalc: CGFloat = geometry.frame(in: .global).height - keyboardHeight
                                let leftMin: CGFloat = leftCalc - rightCalc
                                let rightMin: CGFloat = keyboardHeight
                                let leftMax: CGFloat = 0
                                let rightMax: CGFloat = min(leftMin, rightMin) - geometry.safeAreaInsets.bottom
                                self.padding = max(leftMax, rightMax)
                            }
                        })
                        .animation(self.animation)
                }
            }
        }
    }
    
    private var keyboardHeightPublisher: Publishers.Merge<Publishers.CompactMap<NotificationCenter.Publisher, CGFloat>, Publishers.Map<NotificationCenter.Publisher, CGFloat>> {
        Publishers.Merge(
            NotificationCenter
                .default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap({ $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect })
                .map({ $0.height }),
            
            NotificationCenter
                .default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map({ _ in 0 })
        )
    }
    
    private var isSystemEnabled: Bool {
        if #available(iOS 14.0, *) {
            return true
        } else {
            return false
        }
    }
}

#endif

// MARK: - API -

public enum KeyboardPadding {
    case keyboard
}

@available(macCatalystApplicationExtension, unavailable)
@available(iOSApplicationExtension, unavailable)
extension View {
    /// Pads this view with the active system height of the keyboard.
    public func padding(_: KeyboardPadding, animation: Animation = .spring()) -> some View {
        #if os(iOS) || targetEnvironment(macCatalyst)
        return modifier(KeyboardAvoidance(isSimple: true, animation: animation))
        #else
        return self
        #endif
    }
}
