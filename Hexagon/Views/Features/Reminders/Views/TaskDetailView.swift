//
//  TaskDetailView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import AVFoundation
import CoreLocation
import HexagonData

struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, alignment: alignment, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, alignment: alignment, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let point = result.frames[index].origin
            subview.place(at: CGPoint(x: point.x + bounds.minX, y: point.y + bounds.minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        let frames: [CGRect]
        let size: CGSize
        
        init(in maxWidth: CGFloat, subviews: Subviews, alignment: Alignment, spacing: CGFloat) {
            var frames = [CGRect]()
            var lineOrigin = CGPoint.zero
            var lineSize = CGSize.zero
            var totalSize = CGSize.zero
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if lineOrigin.x + subviewSize.width > maxWidth {
                    lineOrigin.x = 0
                    lineOrigin.y += lineSize.height + spacing
                    lineSize.height = 0
                }
                
                let frame = CGRect(origin: lineOrigin, size: subviewSize)
                frames.append(frame)
                
                lineOrigin.x += subviewSize.width + spacing
                lineSize.height = max(lineSize.height, subviewSize.height)
                lineSize.width = max(lineSize.width, lineOrigin.x)
                
                totalSize.width = max(totalSize.width, lineSize.width)
                totalSize.height = max(totalSize.height, lineOrigin.y + lineSize.height)
            }
            
            self.frames = frames
            self.size = totalSize
        }
    }
}

extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ optional: T?, @ViewBuilder content: (Self, T) -> Content) -> some View {
        if let value = optional {
            content(self, value)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, @ViewBuilder content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }
}

struct TaskDetailView: View {
    @ObservedObject var viewModel: TaskDetailViewModel
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPhoto: ReminderPhoto?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                titleSection
                    .padding(.bottom, 8)
                
                Group {
                    if viewModel.hasDates {
                        datesSection
                    }
                    
                    if let list = viewModel.reminder.list, !(list.name?.isEmpty ?? true) {
                        listSection
                    }
                    
                    if let subHeading = viewModel.reminder.subHeading?.title, !subHeading.isEmpty {
                        subHeadingSection
                    }
                    
                    if !viewModel.tags.isEmpty {
                        tagsSection
                    }
                    
                    if viewModel.reminder.priority > 0 {
                        prioritySection
                    }
                    
                    if !viewModel.notifications.isEmpty {
                        notificationsSection
                    }
                    
                    if !(viewModel.reminder.url?.isEmpty ?? true) {
                        urlSection
                    }
                    
                    if !(viewModel.reminder.notes?.isEmpty ?? true) {
                        notesSection
                    }
                    
                    if !viewModel.photos.isEmpty {
                        photosSection
                    }
                    
                    if viewModel.reminder.location != nil {
                        locationSection
                    }
                    
                    if viewModel.reminder.voiceNote?.audioData != nil {
                        voiceNoteSection
                    }
                }
                .padding(.leading, 16)
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .sheet(item: $selectedPhoto) { photo in
            ZoomableScrollView {
                if let imageData = photo.photoData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("Unable to load image")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
            }
        }
        .onReceive(viewModel.$reminder) { _ in
            viewModel.loadReminderDetails()
        }
    }
    
    private var titleSection: some View {
        Text(viewModel.reminder.title ?? "Untitled Task")
            .font(.largeTitle)
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Dates").font(.headline)
                Image(systemName: "calendar")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            if let startDate = viewModel.reminder.startDate {
                HStack {
                    Text("Start:")
                    Text(DateFormatter.sharedDateFormatter.string(from: startDate))
                }
            }
            if let endDate = viewModel.reminder.endDate {
                HStack {
                    Text("Due:")
                    Text(DateFormatter.sharedDateFormatter.string(from: endDate))
                }
            }
        }
    }
    
    private var listSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("List").font(.headline)
                Image(systemName: "list.bullet")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            if let list = viewModel.reminder.list, !(list.name?.isEmpty ?? true) {
                Text(list.name ?? "")
            }
        }
    }
    
    private var subHeadingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Subheading").font(.headline)
                Image(systemName: "text.alignleft")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            if let subHeading = viewModel.reminder.subHeading?.title, !subHeading.isEmpty {
                Text(subHeading)
            }
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tags").font(.headline)
                Image(systemName: "tag.fill")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            FlowLayout(alignment: .leading, spacing: 8) {
                ForEach(viewModel.tags, id: \.self) { tag in
                    Text(tag)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(appTintColor)
                        .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Priority").font(.headline)
                Image(systemName: "flag.fill")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            Text(viewModel.priorityText)
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Notifications").font(.headline)
                Image(systemName: "bell.fill")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            ForEach(viewModel.notifications, id: \.self) { notification in
                Text(notification)
            }
        }
    }
    
    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Link").font(.headline)
                Image(systemName: "link")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            if let urlString = viewModel.reminder.url, let url = URL(string: urlString), !urlString.isEmpty {
                Link(destination: url) {
                    Text(url.absoluteString)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes").font(.headline)
                Image(systemName: "note.text")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            if let notes = viewModel.reminder.notes, !notes.isEmpty {
                Text(notes)
            }
        }
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Photos").font(.headline)
                Image(systemName: "photo.fill")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.photos, id: \.self) { photo in
                        if let imageData = photo.photoData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .cornerRadius(4)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                        }
                    }
                }
            }
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Location").font(.headline)
                Image(systemName: "location.fill")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            if let location = viewModel.reminder.location {
                Text(location.name ?? "Unknown")
                Text("Latitude: \(location.latitude), Longitude: \(location.longitude)")
                Text("Radius: \(viewModel.reminder.radius ?? 0) meters")
            }
        }
    }
    
    private var voiceNoteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Voice Note").font(.headline)
                Image(systemName: "waveform")
            }
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            
            if viewModel.reminder.voiceNote?.audioData != nil {
                HStack {
                    Button(action: viewModel.togglePlayback) {
                        Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                            .foregroundColor(appTintColor)
                            .font(.system(size: 30))
                    }
                    Text(viewModel.isPlaying ? "Playing..." : "Tap to play")
                }
            }
        }
    }
}
