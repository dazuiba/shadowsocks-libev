//
//  FileMonitor.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 20.09.24.
//

import Foundation

class FileMonitor {
    private let filePath: String
    private var fileHandle: FileHandle?
    private var source: DispatchSourceFileSystemObject?
    private var block:(String)->(Void)

    init(filePath: String,block: @escaping (String)->(Void)) {
        self.filePath = filePath
        self.block = block
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard FileManager.default.fileExists(atPath: filePath) else {
            print("File does not exist: \(filePath)")
            return
        }
        
        do {
            fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: filePath))
            fileHandle?.seekToEndOfFile()
            
            let descriptor = fileHandle!.fileDescriptor
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: descriptor,
                eventMask: .write,
                queue: DispatchQueue.global(qos: .default)
            )
            
            source.setEventHandler { [weak self] in
                self?.handleFileChange()
            }
            
            source.setCancelHandler { [weak self] in
                self?.fileHandle?.closeFile()
                self?.fileHandle = nil
            }
            
            source.resume()
            self.source = source
        } catch {
            print("Error opening file: \(error)")
        }
    }
    
    private func handleFileChange() {
        guard let data = fileHandle?.availableData, !data.isEmpty else { return }
        
        if let newContent = String(data: data, encoding: .utf8) {
            self.block(newContent)
        }
        
        fileHandle?.seekToEndOfFile()
    }
    
    func stopMonitoring() {
        source?.cancel()
        source = nil
    }
}
