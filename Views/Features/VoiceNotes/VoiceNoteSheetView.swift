//
//  VoiceNoteSheetView.swift
//  Hexagon
//
//  Created by Kieran Lynch on 13/09/2024.
//

import SwiftUI
import AVFoundation

struct VoiceNoteSheetView: View {
    @Environment(\.appTintColor) var appTintColor
    @Environment(\.colorScheme) var colorScheme
    @Binding var voiceNoteData: Data?
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recordingURL: URL?
    @State private var recordingDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var waveformSamples: [CGFloat] = Array(repeating: 0, count: 50)
    
    var body: some View {
        VStack {
            Text(timeString(from: recordingDuration))
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            if isRecording || voiceNoteData != nil {
                WaveformView(samples: waveformSamples)
                    .frame(height: 100)
                    .padding()
            }
            
            Spacer()
            
            HStack {
                if let _ = voiceNoteData {
                    Button(action: {
                        if isPlaying {
                            stopPlayback()
                        } else {
                            startPlayback()
                        }
                    }) {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .foregroundColor(appTintColor)
                            .font(.system(size: 44))
                    }
                    
                    Button(action: {
                        deleteVoiceNote()
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 44))
                    }
                }
            }
            .padding()

            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .foregroundColor(isRecording ? .red : appTintColor)
                    .font(.system(size: 60))
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Voice Note")
        .onDisappear {
            stopRecording()
            stopPlayback()
        }
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            recordingURL = audioFilename
            recordingDuration = 0
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingDuration += 0.1
                updateWaveform()
            }
        } catch {
            return
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        
        if let url = recordingURL {
            do {
                voiceNoteData = try Data(contentsOf: url)
            } catch {
                return
            }
        }
    }
    
    private func startPlayback() {
        guard let data = voiceNoteData else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
            isPlaying = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingDuration = audioPlayer?.currentTime ?? 0
                updateWaveform()
            }
        } catch {
            return
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        timer?.invalidate()
    }
    
    private func deleteVoiceNote() {
        voiceNoteData = nil
        stopPlayback()
        recordingDuration = 0
        waveformSamples = Array(repeating: 0, count: 50)
    }
    
    private func updateWaveform() {
        if isRecording {
            audioRecorder?.updateMeters()
            let normalizedValue = (CGFloat(audioRecorder?.averagePower(forChannel: 0) ?? -160) + 160) / 160
            waveformSamples.append(normalizedValue)
            if waveformSamples.count > 50 {
                waveformSamples.removeFirst()
            }
        } else if isPlaying {
            audioPlayer?.updateMeters()
            let normalizedValue = (CGFloat(audioPlayer?.averagePower(forChannel: 0) ?? -160) + 160) / 160
            waveformSamples.append(normalizedValue)
            if waveformSamples.count > 50 {
                waveformSamples.removeFirst()
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct WaveformView: View {
    let samples: [CGFloat]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width / CGFloat(samples.count)
                let midY = geometry.size.height / 2
                let scale = geometry.size.height / 2
                
                for (index, sample) in samples.enumerated() {
                    let x = CGFloat(index) * width
                    let y = midY - (sample * scale)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                
                for (index, sample) in samples.enumerated().reversed() {
                    let x = CGFloat(index) * width
                    let y = midY + (sample * scale)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom))
        }
    }
}
