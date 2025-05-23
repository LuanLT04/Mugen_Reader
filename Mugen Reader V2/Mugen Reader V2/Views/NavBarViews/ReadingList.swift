//
//  ReadingList.swift
//  Mugen Reader V2
//
//  create by Nhom 12
//

// Import thư viện SwiftUI để xây dựng giao diện người dùng.
import SwiftUI

// Định nghĩa một View có tên là ReadingList.
struct ReadingList: View {
    // Khởi tạo một StateObject để quản lý trạng thái đọc, dùng singleton pattern.
    @StateObject private var readingStateManager = ReadingStateManager.shared
    // Khai báo mảng lưu danh sách Manga đã đọc.
    @State private var readingListManga: [Manga] = []
    // Khai báo mảng lưu danh sách Chapter đã đọc.
    @State private var readingListChapters: [FeedChapter] = []
    
    // Hàm cập nhật dữ liệu từ readingStateManager vào hai mảng trên.
    func updateFromManager() {
        // Lấy danh sách Manga từ lastReadChapters.
        readingListManga = readingStateManager.lastReadChapters.map { $0.MangaDetail }
        // Lấy danh sách Chapter từ lastReadChapters.
        readingListChapters = readingStateManager.lastReadChapters.map { $0.Chapter }
    }
    
    // Hàm xóa một item khỏi danh sách đã đọc.
    func deleteItemFromLastRead(at offsets: IndexSet) {
        withAnimation {
            // Xóa Manga tại vị trí chỉ định.
            readingListManga.remove(atOffsets: offsets)
            // Xóa Chapter tại vị trí chỉ định.
            readingListChapters.remove(atOffsets: offsets)
            // Gọi hàm xóa trong readingStateManager để cập nhật trạng thái toàn cục.
            readingStateManager.deleteLastRead(at: offsets)
        }
    }
    
    // View hiển thị danh sách Manga đang đọc.
    var readingMangaListView: some View {
        List {
            // Lặp qua chỉ số của mảng readingListManga.
            ForEach(readingListManga.indices, id: \.self) { index in
                // Lấy Manga và Chapter tương ứng với index.
                let manga = readingListManga[index]
                let chapter = readingListChapters[index]
                // Tạo NavigationLink để chuyển sang màn hình đọc Chapter.
                NavigationLink(destination: ReadingView(viewChapterID: chapter.id)) {
                    HStack {
                        VStack(alignment: .leading) {
                            // Hiển thị thông tin Manga.
                            MangaView(item: manga)
                            // Hiển thị tên Chapter.
                            FeedChapter.buildChapterNameView(chapter)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle()) // Giúp toàn bộ HStack có thể nhận sự kiện click.
                }
                .id(manga.id + chapter.id) // Đặt id duy nhất cho mỗi NavigationLink.
            }
            .onDelete(perform: deleteItemFromLastRead) // Cho phép xóa item bằng thao tác vuốt.
        }
        .refreshable {
            // Khi kéo để làm mới, cập nhật lại danh sách từ readingStateManager.
            readingStateManager.refreshLastRead()
            updateFromManager()
        }
    }
    
    // View chính của ReadingList.
    var body: some View {
        Group {
            // Nếu danh sách Manga không rỗng, hiển thị danh sách.
            if !readingListManga.isEmpty {
                readingMangaListView
            } else {
                // Nếu rỗng, hiển thị thông báo chưa đọc Manga nào.
                Text("You Haven't Started Any Manga \n :D")
            }
        }
        .onAppear {
            // Khi View xuất hiện, cập nhật dữ liệu từ readingStateManager.
            updateFromManager()
        }
        .onReceive(readingStateManager.readingStateNotification) { _ in
            // Khi có thông báo thay đổi trạng thái đọc, cập nhật lại dữ liệu.
            updateFromManager()
        }
    }
}

// View dùng để preview giao diện trong Xcode.
struct ReadingList_Previews: PreviewProvider {
    static var previews: some View {
        ReadingList()
    }
}
