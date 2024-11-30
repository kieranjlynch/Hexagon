//
//  MediaManager..swift
//  Hexagon
//
//  Created by Kieran Lynch on 04/11/2024.
//

import UIKit
import AVFoundation


class MediaManager {
    static func saveVoiceNoteDataToFile(data: Data) -> URL? {
        let audioFilename = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("voiceNote.m4a")
        do {
            try data.write(to: audioFilename)
            return audioFilename
        } catch {
            return nil
        }
    }
    
    static func loadPhotos(from reminders: Set<ReminderPhoto>) -> [UIImage] {
        reminders.compactMap { UIImage(data: $0.photoData ?? Data()) }
    }
}
