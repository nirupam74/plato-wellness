//
//  ProgressPhoto.swift
//  Wellness App
//
//  A private progress photo. The image bytes live in Firebase Storage under
//  users/{uid}/progressPhotos; this record (in Firestore) holds the download
//  URL and the date.
//

import Foundation

struct ProgressPhoto: Codable, Identifiable {
    var id: String
    var url: String
    var recordedAt: Date

    init(id: String = UUID().uuidString, url: String, recordedAt: Date = Date()) {
        self.id = id
        self.url = url
        self.recordedAt = recordedAt
    }
}
