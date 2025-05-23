//
//  Downloads.swift
//  Mugen Reader V2
//
//  create by Nhom 12
//


import SwiftUI

class DownloadsManager: ObservableObject {
    @Published var downloadsJSON: [DownloadedManga] = []
    
    init() {
        self.downloadsJSON = DownloadedManga.GetDownloads()
    }
    
    func refreshDownloads() {
        self.downloadsJSON = DownloadedManga.GetDownloads()
    }
}

struct Downloads: View {
    @StateObject private var downloadsManager = DownloadsManager()
    
    var body: some View {
        VStack {
            if downloadsManager.downloadsJSON.isEmpty {
                Text("Downloads = \(downloadsManager.downloadsJSON.count)")
                Text("If you've downloaded something and it's not showing up please pull down")
            }
            
            List(downloadsManager.downloadsJSON.indices, id: \.self) { manga in
                let mangaData = downloadsManager.downloadsJSON[manga]
                let title = mangaData.MangaDetail.attributes.title.en ?? "Unknown Title"
                NavigationLink(title, destination: chooseChapter(DownManga: mangaData))
            }
            .refreshable {
                downloadsManager.refreshDownloads()
            }
            .onAppear {
                downloadsManager.refreshDownloads()
            }
        }
        .onReceive(DownloadedManga.downloadUpdateNotification) { _ in
            downloadsManager.refreshDownloads()
        }
    }
}

struct chooseChapter : View {
    @StateObject private var downloadsManager = DownloadsManager()
    @State var DownManga : DownloadedManga
    
    func deleteDownloadedChapter(at offsets : IndexSet) {
        var allDownloads = DownloadedManga.GetDownloads()
        var DIndex = allDownloads.firstIndex(where: {$0.MangaDetail.id == DownManga.MangaDetail.id})
        
        //Delete from Storage
        offsets.sorted(by: > ).forEach { (i) in
            var chaptereDele = allDownloads[DIndex!].chapters[i]
            let name = chaptereDele.chapterName
            let pagesDele = chaptereDele.chapterPages
            print("Deleting \(name)")
            deleteDownChapters(pagesDele)
        }
        
        //Update JSON Data
        allDownloads[DIndex!].chapters.remove(atOffsets: offsets)
        if allDownloads[DIndex!].chapters.isEmpty {
            allDownloads.remove(at: DIndex!)
        }
        DownloadedManga.updateDownloads(with: allDownloads)
        
        //Update UI
        withAnimation {
            DownManga.chapters.remove(atOffsets: offsets)
            downloadsManager.refreshDownloads()
        }
    }
    
    var body: some View {
        let title = DownManga.MangaDetail.attributes.title.en ?? "Unknown Title"
        
        List {
            ForEach(DownManga.chapters.indices, id: \.self) { i in
                let chap = DownManga.chapters[i]
                let title = chap.chapterName
                NavigationLink(title, destination: ReadDownload(chapterPages: chap.chapterPages))
            }
            .onDelete(perform: deleteDownloadedChapter)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
    }
}

struct ReadDownload: View {
    
    var chapterPages: [String]
    
    @State private var uiImages = [String: UIImage]()
    
    var body: some View {
        ScrollView {
            VStack{
                ForEach(chapterPages, id: \.self) { pageLink in
                    if let uiImage = uiImages[pageLink] {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView() // Shows loading indicator until image is loaded
                            .onAppear {
                                loadImage(from: pageLink)
                            }
                    }
                }
            }
        }
    }
    
    func loadImage(from pageLink: String) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = URL(string: pageLink)!.lastPathComponent
        let fileURL = documents.appendingPathComponent(fileName)
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageData = try? Data(contentsOf: fileURL),
               let uiImage = UIImage(data: imageData) {
                DispatchQueue.main.async {
                    self.uiImages[pageLink] = uiImage
                }
            }
        }
    }
}

struct Downloads_Previews: PreviewProvider {
    static var previews: some View {
        Downloads()
    }
}
