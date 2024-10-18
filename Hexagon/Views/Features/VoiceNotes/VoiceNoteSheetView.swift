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
    @State private var power: CGFloat = 0

    var body: some View {
        VStack {
            Text(timeString(from: recordingDuration))
                .font(.largeTitle)
                .padding()
            
            Spacer()
            
            if isRecording || voiceNoteData != nil {
                WaveView(power: $power)
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
                updatePower()
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
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.play()
            isPlaying = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordingDuration = audioPlayer?.currentTime ?? 0
                updatePower()
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
    }
    
    private func updatePower() {
        if isRecording {
            audioRecorder?.updateMeters()
            let decibels = audioRecorder?.averagePower(forChannel: 0) ?? -160
            power = normalizedPowerLevel(fromDecibels: decibels)
        } else if isPlaying {
            audioPlayer?.updateMeters()
            let decibels = audioPlayer?.averagePower(forChannel: 0) ?? -160
            power = normalizedPowerLevel(fromDecibels: decibels)
        }
    }
    
    private func normalizedPowerLevel(fromDecibels decibels: Float) -> CGFloat {
        let minDb: Float = -80.0
        let maxDb: Float = -10.0
        let clampedDecibels = max(decibels, minDb)
        let normalized = CGFloat((clampedDecibels - minDb) / (maxDb - minDb))
        let level = pow(normalized, 2.0)
        let threshold: CGFloat = 0.05
        return level < threshold ? 0.0 : level
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
