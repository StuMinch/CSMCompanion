import Foundation
import SwiftData

@Model
final class NewsItem {
    var id: UUID = UUID()
    var account: Account?
    var headline: String = ""
    var sourceName: String = ""
    var urlString: String = ""
    var publishedDate: Date = Date()
    var summary: String?
    var fetchedDate: Date = Date()

    init(headline: String, sourceName: String, urlString: String, publishedDate: Date) {
        self.headline = headline
        self.sourceName = sourceName
        self.urlString = urlString
        self.publishedDate = publishedDate
    }

    var url: URL? { URL(string: urlString) }
}
