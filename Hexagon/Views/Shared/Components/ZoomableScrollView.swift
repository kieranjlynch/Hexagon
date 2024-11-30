//
//  ZoomableScrollView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        
        let hostedView = UIHostingController(rootView: content)
        hostedView.view.translatesAutoresizingMaskIntoConstraints = false
        hostedView.view.backgroundColor = UIColor.clear 
        scrollView.addSubview(hostedView.view)
        
        NSLayoutConstraint.activate([
            hostedView.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let hostedView = uiView.subviews.first?.subviews.first as? UIView {
            let updatedHostingController = UIHostingController(rootView: content)
            updatedHostingController.view.frame = hostedView.bounds
            updatedHostingController.view.backgroundColor = .clear
            hostedView.removeFromSuperview()
            uiView.addSubview(updatedHostingController.view)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        
        init(_ parent: ZoomableScrollView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
    }
}
