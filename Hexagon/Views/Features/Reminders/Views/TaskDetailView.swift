//
//  TaskDetailView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 29/08/2024.
//

import SwiftUI
import AVFoundation


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
    @StateObject var viewModel: TaskDetailViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.scenePhase) private var scenePhase
    @State private var loadedImages = [Int: UIImage]()
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                titleSection
                
                if viewModel.hasDates {
                    dateSectionView
                }
                
                if !viewModel.tags.isEmpty {
                    tagsSectionView
                }
                
                if viewModel.hasURL {
                    urlSectionView
                }
                
                if !viewModel.notifications.isEmpty {
                    notificationsSectionView
                }
                
                if !viewModel.photos.isEmpty {
                    photosSectionView
                }
                
                if viewModel.hasVoiceNote {
                    voiceNoteSectionView
                }
                
                if let notes = viewModel.reminder.notes, !notes.isEmpty {
                    notesSectionView(notes)
                }
                
                prioritySectionView
            }
            .padding()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                Task {
                    await viewModel.cleanup()
                }
            case .inactive:
                viewModel.pausePlayback()
            default:
                break
            }
        }
        .task {
            await viewModel.reloadReminder()
        }
        .task(id: viewModel.reminder.notifications) {
            await viewModel.reloadReminder()
        }
        .onDisappear {
            Task {
                await viewModel.cleanup()
            }
        }
        .adaptiveBackground()
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.reminder.title ?? "Untitled")
                .font(.title)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            if let list = viewModel.reminder.list {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(Color(UIColor.color(data: list.colorData ?? Data()) ?? .gray))
                    Text(list.name ?? "Unknown List")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var dateSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dates")
                .font(.headline)
            
            if let startDate = viewModel.reminder.startDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(appSettings.appTintColor)
                    Text("Starts: \(DateFormatter.sharedDateFormatter.string(from: startDate))")
                }
            }
            
            if let endDate = viewModel.reminder.endDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(appSettings.appTintColor)
                    Text("Ends: \(DateFormatter.sharedDateFormatter.string(from: endDate))")
                }
            }
        }
    }
    
    private var tagsSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)
            
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .foregroundColor(appSettings.appTintColor)
                ForEach(viewModel.tags, id: \.self) { tag in
                    Text(tag)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(appSettings.appTintColor.opacity(0.2))
                        .cornerRadius(16)
                }
            }
        }
    }
    
    private var urlSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("URL")
                .font(.headline)
            
            if let url = viewModel.reminder.url, let urlObj = URL(string: url) {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(appSettings.appTintColor)
                    Link(url, destination: urlObj)
                        .foregroundColor(appSettings.appTintColor)
                }
            }
        }
    }
    
    private var notificationsSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications")
                .font(.headline)
            
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(viewModel.notifications, id: \.self) { notification in
                    if !notification.isEmpty {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(appSettings.appTintColor)
                            Text(notification.replacingOccurrences(of: "time:", with: ""))
                        }
                    }
                }
            }
        }
    }
    
    private var photosSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photos")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(viewModel.photos.indices, id: \.self) { index in
                        AsyncPhotoView(photo: viewModel.photos[index])
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var voiceNoteSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Voice Note")
                .font(.headline)
            
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(appSettings.appTintColor)
                Button(action: {
                    Task {
                        await viewModel.togglePlayback()
                    }
                }) {
                    HStack {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .foregroundColor(appSettings.appTintColor)
                        Text(viewModel.isPlaying ? "Pause" : "Play")
                    }
                    .padding()
                    .background(appSettings.appTintColor.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func notesSectionView(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(appSettings.appTintColor)
                Text(notes)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var prioritySectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority")
                .font(.headline)
            
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(appSettings.appTintColor)
                Text(viewModel.priorityText)
            }
        }
    }
}

struct AsyncPhotoView: View {
    let photo: ReminderPhoto
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .task {
                        if let data = photo.photoData {
                            if let uiImage = UIImage(data: data) {
                                image = uiImage
                            }
                        }
                    }
            }
        }
    }
}

private extension ReminderPhoto {
    var id: String {
        objectID.uriRepresentation().absoluteString
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        return computeSize(rows: rows, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        placeRows(rows, in: bounds)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentRow = 0
        var remainingWidth = proposal.width ?? UIScreen.main.bounds.width
        
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            
            if size.width > remainingWidth {
                currentRow += 1
                rows.append([])
                remainingWidth = (proposal.width ?? UIScreen.main.bounds.width) - size.width - spacing
            } else {
                remainingWidth -= size.width + spacing
            }
            
            rows[currentRow].append(subview)
        }
        
        return rows
    }
    
    private func computeSize(rows: [[LayoutSubview]], proposal: ProposedViewSize) -> CGSize {
        var height: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for row in rows {
            let rowSize = computeRowSize(row, proposal: proposal)
            height += rowSize.height
            maxWidth = max(maxWidth, rowSize.width)
            
            if row != rows.last {
                height += spacing
            }
        }
        
        return CGSize(width: proposal.width ?? maxWidth, height: height)
    }
    
    private func computeRowSize(_ row: [LayoutSubview], proposal: ProposedViewSize) -> CGSize {
        var width: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for (index, subview) in row.enumerated() {
            let size = subview.sizeThatFits(proposal)
            width += size.width
            if index < row.count - 1 {
                width += spacing
            }
            maxHeight = max(maxHeight, size.height)
        }
        
        return CGSize(width: width, height: maxHeight)
    }
    
    private func placeRows(_ rows: [[LayoutSubview]], in bounds: CGRect) {
        var y = bounds.minY
        
        for row in rows {
            let rowSize = computeRowSize(row, proposal: .unspecified)
            var x: CGFloat
            
            switch alignment {
            case .leading:
                x = bounds.minX
            case .center:
                x = bounds.minX + (bounds.width - rowSize.width) / 2
            case .trailing:
                x = bounds.maxX - rowSize.width
            default:
                x = bounds.minX
            }
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            
            y += rowSize.height + spacing
        }
    }
}
