import Foundation
import SwiftUI

// Định nghĩa class quản lý trạng thái đọc, tuân thủ ObservableObject để hỗ trợ SwiftUI cập nhật giao diện khi dữ liệu thay đổi.
class ReadingStateManager: ObservableObject {
    // Singleton pattern: chỉ có một instance duy nhất dùng chung toàn app.
    static let shared = ReadingStateManager()
    
    // Danh sách các chapter đã đọc, khi thay đổi sẽ thông báo cho các View đang lắng nghe.
    @Published private(set) var lastReadChapters: [LastReadChapter] = []
    
    // Publisher phát thông báo khi trạng thái đọc thay đổi, dùng cho các View lắng nghe.
    let readingStateNotification = NotificationCenter.default.publisher(for: NSNotification.Name("ReadingStateChanged"))
    
    // Hàm khởi tạo private để đảm bảo singleton, tự động gọi refreshLastRead khi khởi tạo.
    private init() {
        refreshLastRead()
    }
    
    // Hàm làm mới danh sách chapter đã đọc từ nguồn lưu trữ (ví dụ UserDefaults, file, database).
    func refreshLastRead() {
        // Thực hiện ở thread nền để tránh block UI.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let chapters = GetLastRead() // Lấy dữ liệu từ nguồn lưu trữ.
            // Quay lại main thread để cập nhật dữ liệu và phát thông báo.
            DispatchQueue.main.async {
                self?.lastReadChapters = chapters
                NotificationCenter.default.post(name: NSNotification.Name("ReadingStateChanged"), object: nil)
            }
        }
    }
    
    // Hàm cập nhật trạng thái đã đọc khi người dùng đọc một chapter mới.
    func updateLastRead(manga: Manga, chapter: FeedChapter) {
        // Tạo đối tượng LastReadChapter mới với thông tin manga và chapter vừa đọc.
        let currentLastRead = LastReadChapter(id: manga.id, MangaDetail: manga, Chapter: chapter)
        // Thực hiện ở thread nền để lưu dữ liệu.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            appendToLastReadChapters(currentLastRead) // Lưu vào nguồn lưu trữ.
            // Quay lại main thread để làm mới dữ liệu và phát thông báo.
            DispatchQueue.main.async {
                self?.refreshLastRead()
            }
        }
    }
    
    // Hàm xóa một hoặc nhiều chapter khỏi danh sách đã đọc.
    func deleteLastRead(at indices: IndexSet) {
        var listOfRead = GetLastRead() // Lấy danh sách hiện tại từ nguồn lưu trữ.
        listOfRead.remove(atOffsets: indices) // Xóa các phần tử theo chỉ số.
        updateLastReadChapter(with: listOfRead) // Lưu lại danh sách mới vào nguồn lưu trữ.
        refreshLastRead() // Làm mới dữ liệu và phát thông báo cho các View.
    }
}
