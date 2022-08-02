//
//  FileManager+DockerHubList.swift
//  docker-hub-list
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftPatches

public extension FileManager {
    func modificationDateForItem(atPath path: String) throws -> Date? {
        let attr = try self.attributesOfItem(atPath: path)
        return attr[FileAttributeKey.modificationDate] as? Date
    }
    func modificationDateForItemNoThrow(atPath path: String) -> Date? {
        do {
            return try self.modificationDateForItem(atPath: path)
        } catch {
            return nil
        }
    }
    
    @discardableResult
    func enumerating<Results>(at url: URL,
                              includingPropertiesForKeys: [URLResourceKey]? = nil,
                              initialResults results: Results,
                              filtering: (URL) -> Bool = { _ in return true },
                              _ nextPartialResult: (Results, URL) throws -> Results) throws -> Results {
        
        var workingResults = results
        let children = try self.contentsOfDirectory(at: url,
                                                    includingPropertiesForKeys: includingPropertiesForKeys)
        for child in children { 
            if filtering(child) {
                workingResults = try nextPartialResult(workingResults, child)
                if (try child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false {
                    // We will traverse sub directories
                    workingResults = try self.enumerating(at: child,
                                                          includingPropertiesForKeys: includingPropertiesForKeys,
                                                          initialResults: workingResults,
                                                          filtering: filtering,
                                                          nextPartialResult)
                }
            }
        }
        
        return workingResults
        
    }
    
    
    func fileAllocatedSize(atPath path: String,
                            filtering: (URL) -> Bool = { _ in return true }) throws -> Int? {
        var isDir: Bool = false
        guard self.fileExists(atPath: path, isDirectory: &isDir) else {
            return nil
        }
        
        guard isDir else {
            return try URL(fileURLWithPath: path, isDirectory: false).resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0
        }
        
        return try self.enumerating(at: URL(fileURLWithPath: path, isDirectory: true),
                                    includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
                                    initialResults: 0,
                                    filtering: filtering) { (currentSize, url) throws -> Int in
            return currentSize + (try url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize ?? 0)
        }
        
    }
    
    func fileSize(atPath path: String,
                  filtering: (URL) -> Bool = { _ in return true }) throws -> Int? {
        var isDir: Bool = false
        guard self.fileExists(atPath: path, isDirectory: &isDir) else {
            return nil
        }
        
        guard isDir else {
            return try URL(fileURLWithPath: path, isDirectory: false).resourceValues(forKeys: [.totalFileSizeKey]).totalFileSize ?? 0
        }
        
        return try self.enumerating(at: URL(fileURLWithPath: path, isDirectory: true),
                                    includingPropertiesForKeys: [.totalFileSizeKey],
                                    initialResults: 0,
                                    filtering: filtering) { (currentSize, url) throws -> Int in
           
            return currentSize + (try url.resourceValues(forKeys: [.totalFileSizeKey]).totalFileSize ?? 0)
        }
        
    }
}
