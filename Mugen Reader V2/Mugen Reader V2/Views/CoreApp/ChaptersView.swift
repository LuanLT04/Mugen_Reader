//
//  ChaptersView.swift
//  Mugen Reader V2
//
//  create by Nhom 12
//

import SwiftUI

// Định nghĩa View hiển thị danh sách chapter của một Manga.
struct ChaptersView: View {
    // Quản lý trạng thái đọc, dùng singleton pattern.
    @StateObject private var readingStateManager = ReadingStateManager.shared
    // Lưu các chapter được chọn để tải về.
    @State private var selectedChapters = Set<String>()
    // Theo dõi trạng thái tải về của từng chapter.
    @State private var downloadingChapters = [String: Bool]()
    
    // Manga được chọn để hiển thị danh sách chapter.
    let chosenManga: Manga
    
    // Mảng lưu kết quả các chapter lấy từ API.
    @State private var chapterResults = [FeedChapter]()
    // Biến computed property để get/set chapterResults.
    var animateGetChapters : [FeedChapter]{
        get{chapterResults}
        set{chapterResults = newValue }
    }
    
    // View hiển thị danh sách các chapter.
    var ChaptersList : some View{
        List(chapterResults, selection: $selectedChapters) { item in
            HStack{
                // Hiển thị trạng thái tải về của chapter.
                if downloadingChapters[item.id] == true {
                    ProgressView()
                } else if let downloaded = downloadingChapters[item.id], downloaded == false {
                    Text("Downloaded")
                }
                // NavigationLink chuyển sang màn hình đọc chapter.
                NavigationLink(
                    destination: ReadingView(viewChapterID: item.id)
                        .onAppear{
                            // Cập nhật trạng thái đã đọc khi mở chapter.
                            readingStateManager.updateLastRead(manga: chosenManga, chapter: item)
                        },
                    label: {
                        // Hiển thị tên chapter.
                        FeedChapter.buildChapterNameView(item)
                    }) .id(item.id) // Đặt id cho NavigationLink để hỗ trợ scrollTo
                    .contextMenu {
                        // Menu khi nhấn giữ, cho phép tải về chapter.
                        Button("Download"){
                            Task{
                                let chapterName = "\(item.attributes.chapter ?? ""): \(item.attributes.title ?? "")"
                                downloadingChapters[item.id] = true
                                await DownloadedManga.downloadChapter(manga:chosenManga, chapterID: item.id, chapterName: chapterName)
                                downloadingChapters[item.id] = false
                            }
                        }
                    }
            }
        }
        .navigationTitle(chosenManga.attributes.title.en ?? "No English Title")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Khi view xuất hiện, gọi API lấy danh sách chapter.
            await getChapterResults()
        }
    }
    
    // View chính của ChaptersView.
    var body: some View {
        // Nếu có chapter đã đọc trước đó, cho phép scroll tới vị trí đó.
        if let index = getLastReadID(){
            ScrollViewReader { proxy in
                ChaptersList
                    .toolbar{
                        // Nút "Continue" để cuộn tới chapter đã đọc.
                        Button("Continue") {
                            withAnimation{
                                proxy.scrollTo(index, anchor: .top)
                            }
                        }
                        EditButton() // Nút chỉnh sửa (chọn nhiều chapter).
                        Button("Download Selected", action: downloadMultiChapter) // Tải nhiều chapter.
                    }
            }
        }else{
            // Nếu chưa đọc chapter nào, chỉ hiển thị danh sách.
            ChaptersList
                .toolbar{
                    EditButton()
                    Button("Download Selected", action: downloadMultiChapter)
                }
        }
    }
    
    // Hàm tải nhiều chapter đã chọn.
    func downloadMultiChapter(){
        for chapterID in selectedChapters {
            if let chapter = chapterResults.first(where: { $0.id == chapterID }) {
                let chapterName = "\(chapter.attributes.chapter ?? ""): \(chapter.attributes.title ?? "")"
                downloadingChapters[chapterID] = true
                Task {
                    await DownloadedManga.downloadChapter(manga: chosenManga, chapterID: chapter.id, chapterName: chapterName)
                    downloadingChapters[chapterID] = false
                }
            }
        }
    }
    
    // Lấy id của chapter đã đọc gần nhất để scroll tới.
    func getLastReadID() -> String?{
        if let lastRead = readingStateManager.lastReadChapters.first(where: { $0.id == chosenManga.id }) {
            guard let finalIndex = chapterResults.firstIndex(where: { $0.id == lastRead.Chapter.id }) else { return nil }
            return chapterResults[finalIndex].id
        }
        return nil
    }
    
    // Hàm lấy danh sách chapter từ API.
    func getChapterResults() async{
        do{
            var apiChapterResults = try await FeedChapter.getMangaChapterFeed(for: chosenManga.id)
            // Sắp xếp chapter theo thứ tự tăng dần.
            apiChapterResults.sort{
                guard let titleNum0 = $0.attributes.chapter, let titleNum1 = $1.attributes.chapter else{ return false}
                return  titleNum0.localizedStandardCompare(titleNum1) == .orderedAscending
            }
            withAnimation{ chapterResults = apiChapterResults}
        }catch{
            print("Error fetching chapters: \(error)")
        }
    }
}

// View đọc một chapter cụ thể.
struct ReadingView : View {
    // ID của chapter cần đọc.
    var viewChapterID: String
    // Quản lý trạng thái đọc.
    @StateObject private var readingStateManager = ReadingStateManager.shared
    
    // Thông báo lỗi khi tải trang.
    @State private var messageAlertError = ""
    @State private var showingChapterAlert = false
    // Mảng lưu link ảnh của các trang trong chapter.
    @State private var chapterPages = [String]()
    // Theo dõi các ảnh đang hiển thị.
    @State private var visibleImages = Set<String>()
    // Lưu trữ ảnh đã tải về.
    @State private var loadedImages = [String: UIImage]()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Lặp qua từng trang của chapter.
                ForEach(chapterPages, id: \.self) { pageLink in
                    if let image = loadedImages[pageLink] {
                        // Nếu đã tải ảnh, hiển thị ảnh.
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .onDisappear {
                                // Khi ảnh không còn hiển thị, giải phóng bộ nhớ nếu cần.
                                if !visibleImages.contains(pageLink) {
                                    loadedImages[pageLink] = nil
                                }
                            }
                    } else {
                        // Nếu chưa tải ảnh, hiển thị ProgressView và bắt đầu tải.
                        ProgressView()
                            .padding(150)
                            .onAppear {
                                visibleImages.insert(pageLink)
                                loadImage(from: pageLink)
                            }
                    }
                }
            }
        }
        .alert("There was an error", isPresented: $showingChapterAlert) {
        } message: {
            Text(messageAlertError)
        }
        .task {
            // Khi view xuất hiện, lấy danh sách trang của chapter.
            await getChapterPages()
        }
    }
    
    // Hàm tải ảnh từ url.
    func loadImage(from url: String) {
        guard let imageUrl = URL(string: url) else { return }
        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            if let error = error {
                print("Error loading image: \(error)")
                return
            }
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                // Nếu trang vẫn đang hiển thị, lưu ảnh vào loadedImages.
                if visibleImages.contains(url) {
                    loadedImages[url] = image
                }
            }
        }.resume()
    }
    
    // Hàm lấy danh sách link ảnh của chapter.
    func getChapterPages() async {
        do {
            let decodedResponse = try await FeedChapter.getChapterPageImageURLs(chapterID: viewChapterID)
            withAnimation {
                chapterPages = decodedResponse
            }
        } catch {
            showingChapterAlert = true
            messageAlertError = "Failed to load chapter pages. Please try again."
        }
    }
}

// View preview cho Xcode.
struct ChaptersView_Previews: PreviewProvider {
    static var previews: some View {
        ChaptersView(chosenManga: Manga.produceExampleManga())
    }
}

