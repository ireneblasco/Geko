//
//  NotionFeedbackService.swift
//  Geko
//
//  Submits user feedback to a Notion database via the Notion API.
//

import Foundation

/// Submits feedback entries to a Notion database with columns "ID" and "Feedback".
struct NotionFeedbackService {
    static let shared = NotionFeedbackService()

    private static let notionVersion = "2022-06-28"
    private static let createPageURL = URL(string: "https://api.notion.com/v1/pages")!

    private let token: String?
    private let databaseId: String?

    init(token: String? = nil, databaseId: String? = nil) {
        if let token, let databaseId {
            self.token = token
            self.databaseId = databaseId
        } else if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
                  let dict = try? NSDictionary(contentsOf: url) as? [String: String] {
            self.token = dict["NOTION_INTEGRATION_TOKEN"]
            self.databaseId = dict["NOTION_DATABASE_ID"]
        } else {
            self.token = nil
            self.databaseId = nil
        }
    }

    /// Submits feedback to the Notion database. Throws if secrets are missing or the request fails.
    func submit(feedback: String) async throws {
        guard let token, let databaseId, !token.isEmpty, !databaseId.isEmpty else {
            throw NotionError.missingSecrets
        }

        let id = UUID().uuidString
        let body: [String: Any] = [
            "parent": ["database_id": databaseId],
            "properties": [
                "ID": [
                    "rich_text": [
                        ["type": "text", "text": ["content": id]]
                    ]
                ],
                "Feedback": [
                    "rich_text": [
                        ["type": "text", "text": ["content": feedback]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: Self.createPageURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NotionError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw NotionError.requestFailed(statusCode: http.statusCode)
        }
    }
}

enum NotionError: Error, Equatable {
    case missingSecrets
    case invalidResponse
    case requestFailed(statusCode: Int)
}
