//
//  RamDisk.swift
//  SwiftDockerCoreLib
//
//  Created by Tyler Anger on 2022-03-29.
//

import Foundation
import SwiftPatches
import RegEx

public class RamDisk {
    
    #if os(macOS)
    public static let ramDiskSupported: Bool = true
    #else
    public static let ramDiskSupported: Bool = false
    #endif
    
    public enum RamDiskError: Error {
        case taskReturnedNonZeroValue(Int32)
        case noOutputFromCommand
        case failedToConvertDataToString(data: Data, encoding: String.Encoding)
        case couldNotCreateRamDisk(String?)
        case couldNotMountRamDisk(disk: String, message: String?)
        case couldNoFindMountPoint(disk: String)
        case failedToFormatDrive(disk: String, message: String)
    }
    
    public static let BLOCK_SIZE: Int = 512
    
    public private(set) var disk: String
    public private(set) var volumeName: String
    public let mountPath: String
    public let systemMountedPath: Bool
    public let createdMountPath: Bool
    public private(set) var size: Int
    public let originalSize: Int
    
    public var fsSize: Int {
        do {
            let attribs = try FileManager.default.attributesOfFileSystem(forPath: self.mountPath)
            return (attribs[.systemSize] as? Int) ?? 0
        } catch {
            return 0
        }
    }
    
    public var fsFreeSize: Int {
        do {
            let attribs = try FileManager.default.attributesOfFileSystem(forPath: self.mountPath)
            return (attribs[.systemFreeSize] as? Int) ?? 0
        } catch {
            return 0
        }
    }
    
    public var fsPercentFree: Int {
        do {
            let attribs = try FileManager.default.attributesOfFileSystem(forPath: self.mountPath)
            guard let totalSize = attribs[.systemSize] as? Int else {
                return 0
            }
            guard let freeSize = attribs[.systemFreeSize] as? Int else {
                return 0
            }
            return Int(((Double(freeSize) / Double(totalSize)) * 100.0))
        } catch {
            return 0
        }
    }
    
    private init(disk: String,
                volumeName: String,
                mountPath: String,
                systemMountedPath: Bool,
                createdMountPath: Bool,
                size: Int) {
        self.disk = disk
        self.volumeName = volumeName
        self.mountPath = mountPath
        self.systemMountedPath = systemMountedPath
        self.createdMountPath = createdMountPath
        self.size = size
        self.originalSize = size
    }
    
    public func resize(newSize: Int) throws {
        #if os(macOS)
        // Create temp dir to remount disk to
        let tempDirectory = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(atPath: tempDirectory,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        
        // Unmount drive
        try RamDisk.unmout(disk: self.disk, force: true)
        
        // Mount to temp dir
        let tempDisk = try RamDisk.mountRamDisk(disk: self.disk,
                                                mountPath: tempDirectory,
                                                blockSize: self.size)
        
        
        var mP: String? = nil
        if !self.systemMountedPath {
            mP = self.mountPath
        }
        var tmpDisk: RamDisk? = nil
        //do {
            tmpDisk = try RamDisk.create(byteSize: newSize,
                                          volumeName: volumeName,
                                          mountPath: mP)
        
            // Move content from temp dir to new mount point
            //print("Copying items from '\(tempDisk.mountPath)' to '\(self.mountPath)'")
            let children = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: tempDisk.mountPath, isDirectory: true), includingPropertiesForKeys: nil )
            for child in children {
                /*guard !child.path.contains(".fseventsd") else {
                    continue
                }
                guard FileManager.default.fileExists(atPath: child.path) else {
                    continue
                }
                guard FileManager.default.isReadableFile(atPath: child.path) else {
                    continue
                }*/
                
                let dest = child.path.replacingOccurrences(of: tempDisk.mountPath,
                                                     with: self.mountPath)
                guard !FileManager.default.fileExists(atPath: dest) else {
                    continue
                }
                //print("Copying items from '\(child.path)' to '\(dest)'")
               
                try FileManager.default.copyItem(atPath: child.path,
                                                 toPath: dest)
                
            }
            
            let oldDisk = self.disk
            
            
            // store new disk name and size
            self.disk = tmpDisk!.disk
            self.size = tmpDisk!.size
            
            // remove old disk
            try RamDisk.remove(disk: oldDisk, removeVolumePath: false)
            try? FileManager.default.removeItem(atPath: tempDirectory)
        
        /*} catch {
            if let disk = tmpDisk {
                
            }
            throw error
        }*/
       
        #endif
        
        
    }
    
    public func resize(addingBytes bytes: Int) throws {
        return try self.resize(newSize: self.size + bytes)
    }
    
    public func remove() throws {
        try RamDisk.remove(disk: self.disk,
                           removeVolumePath: self.createdMountPath)
    }
    
    private static func execute(launchPath: String,
                                arguments: [String],
                                environment: [String: String] = ProcessInfo.processInfo.environment,
                                currentDirectory: URL? = nil,
                                standardInput: Any? = nil) throws -> (terminationStatus: Int32, output: String) {
        let rtn = Process()
        rtn.executable = URL(fileURLWithPath: launchPath)
        rtn.arguments = arguments
        rtn.environment = environment
        if let cd = currentDirectory {
            rtn.currentDirectory = cd
        }
        
        if let sI = standardInput {
            rtn.standardInput = sI
        }
        
        let pipe = Pipe()
        rtn.standardOutput = pipe
        rtn.standardError = pipe
        
        try rtn.execute()
        rtn.waitUntilExit()
        
        let ret = rtn.terminationStatus
        
        var data = pipe.fileHandleForReading.readDataToEndOfFile()
        if data.count > 0 {
            if data[data.endIndex - 1] == 10 {
                // Remove \n
                data.remove(at: data.endIndex - 1)
                if data[data.endIndex - 1] == 13 {
                    // remove \r
                    data.remove(at: data.endIndex - 1)
                }
            }
        }
        guard let string = String(data: data,
                                  encoding: .utf8) else {
            if data.count == 0 {
                throw RamDiskError.noOutputFromCommand
            } else {
                throw RamDiskError.failedToConvertDataToString(data: data,
                                                               encoding: .utf8)
            }
        }
        /*
        if string.hasSuffix("\r\n") {
            string.removeLast(2)
        } else if string.hasSuffix("\n") {
            string.removeLast(1)
        }
        */
        /*print("-------------------------------------------------")
        print(launchPath + " " + arguments.joined(separator: " "))
        print("=================================================")
        print(string)
        print("-------------------------------------------------")
         */
        return (terminationStatus: ret,
                output: string)
        
    }
    
    private static func execute(launchPath: String,
                                arguments: String...,
                                environment: [String: String] = ProcessInfo.processInfo.environment,
                                currentDirectory: URL? = nil,
                                standardInput: Any? = nil) throws -> (terminationStatus: Int32, output: String) {
        return try execute(launchPath: launchPath,
                           arguments: arguments,
                           environment: environment,
                           currentDirectory: currentDirectory,
                           standardInput: standardInput)
    }
    
    private static func createRamDisk(blockSize: Int) throws -> String {
        let response = try execute(launchPath: "/usr/bin/hdiutil",
                                   arguments: "attach", "-nomount", "ram://\(blockSize)")
        guard response.terminationStatus == 0 else {
            throw RamDiskError.taskReturnedNonZeroValue(response.terminationStatus)
        }
        let diskRegEx = try! RegEx(pattern: "/dev/disk(\\d+)", options: .caseInsensitive)
        let failedRegEx = try! RegEx(pattern: "hdiutil: attach failed - (.+)", options: .caseInsensitive)
        let matches = diskRegEx.matches(in: response.output)
        guard matches.count == 1 else {
            let failMatches = failedRegEx.matches(in: response.output)
            guard let match = failMatches.first else {
                throw RamDiskError.couldNotCreateRamDisk(nil)
            }
            throw RamDiskError.couldNotCreateRamDisk(String(response.output[match.range]))
            
        }
        
        return String(response.output[matches[0].range])
    }
    
    private static func formatRamDrive(disk: String, volumeName: String? = nil) throws {
        
        var args: [String] = []
        if let v = volumeName {
            args = ["-v", v]
        }
        args.append(disk.replacingOccurrences(of: "/dev/disk",
                                              with: "/dev/rdisk"))
        /*
        let resp = try execute(launchPath: "/sbin/newfs_hfs",
                               arguments: "-v", volumeName, disk.replacingOccurrences(of: "/dev/disk",
                                                                                      with: "/dev/rdisk"))
        */
        let resp = try execute(launchPath: "/sbin/newfs_hfs",
                               arguments: args)
        
        guard resp.terminationStatus == 0 else {
            throw RamDiskError.failedToFormatDrive(disk: disk, message: resp.output)
        }
    }
    
    private static func mountRamDisk(disk: String,
                                     mountPath: String? = nil,
                                     blockSize: Int) throws -> RamDisk {
        
        
        var createdMountPath: Bool = false
        var systemMountedPath: Bool = true
        var args: [String] = ["mount"]
        if let mp = mountPath {
            if !FileManager.default.fileExists(atPath: mp) {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: mp),
                                                        withIntermediateDirectories: true)
                createdMountPath = true
                
            }
            systemMountedPath = false
            args.append("-mountPoint")
            args.append(mp)
        }
        args.append(disk)
        
        var resp = try execute(launchPath: "/usr/sbin/diskutil",
                               arguments: args)
        
        let diskRegEx = try! RegEx(pattern: "Volume (.+) on \(disk) mounted",
                                   options: .caseInsensitive)
        
        var matches = diskRegEx.matches(in: resp.output)
        guard matches.count == 1 else {
            throw RamDiskError.couldNotMountRamDisk(disk: disk, message: nil)
        }
        
        let volumeName = String(resp.output[matches[0].range(at: 1)!])
        
        
        //let mountPoint = try (mountPath ?? (try { () throws -> String in
        let mountPoint = try { () throws -> String in
            resp = try execute(launchPath: "/usr/sbin/diskutil",
                                   arguments: ["info", disk])
            
            let mountRegEx = try! RegEx(pattern: "Mount Point:\\s+(.+)",
                                       options: .caseInsensitive)
            
            matches = mountRegEx.matches(in: resp.output)
            guard matches.count == 1 else {
                throw RamDiskError.couldNoFindMountPoint(disk: disk)
            }
            
            return String(resp.output[matches[0].range(at: 1)!])
        //}()))
        }()
        
        
        return .init(disk: disk,
                     volumeName: volumeName,
                     mountPath: mountPoint,
                     systemMountedPath: systemMountedPath,
                     createdMountPath: createdMountPath,
                     size: blockSize * RamDisk.BLOCK_SIZE)
    }
    
    
    
    
    /// Create a new RamDisk
    /// - Parameters:
    ///  -  blockSize: The block size of the RamDisk
    ///  - volumeName:The name to give the new volume
    ///  - mountPath:The mounting path for the new volume
    /// - Returns: Returns the name RamDisk
    public static func create(blockSize: Int,
                              volumeName: String? = nil,
                              mountPath: String? = nil) throws -> RamDisk {
        let disk = try createRamDisk(blockSize: blockSize)
        try formatRamDrive(disk: disk, volumeName: volumeName)
        return try mountRamDisk(disk: disk, mountPath: mountPath, blockSize: blockSize)
    }
    
    /// Create a new RamDisk
    /// - Parameters:
    ///  -  byteSize: The size in bytes of the RamDrive to create
    ///  - volumeName:The name to give the new volume
    ///  - mountPath:The mounting path for the new volume
    /// - Returns: Returns the name RamDisk
    public static func create(byteSize: Int,
                              volumeName: String? = nil,
                              mountPath: String? = nil) throws -> RamDisk {
        var byteSize = byteSize
        if byteSize < (RamDisk.BLOCK_SIZE * 1024) { // 512KB
            // hfs has a minimum partition size of 512KB
            byteSize = (RamDisk.BLOCK_SIZE * 1024)
        }
        var blockSize = byteSize / RamDisk.BLOCK_SIZE
        if (byteSize % RamDisk.BLOCK_SIZE > 0) {
            blockSize += 1
        }
        
        return try RamDisk.create(blockSize: blockSize,
                                  volumeName: volumeName,
                                  mountPath: mountPath)
        
    }
    
    /// Get the mount path of the given disk ID
    /// - Parameter disk: The disk ID to look up
    /// - Returns: Returns the volume mount point
    private static func getDiskMountPoint(disk: String) throws -> String {
        let resp = try execute(launchPath: "/sbin/mount")
        
        //let diskRegEx = try! RegEx(pattern: "\(disk) on ([^\\(]+)", options: .caseInsensitive)
        let diskRegEx = try! RegEx(pattern: "\(disk) on (.+) \\(", options: .caseInsensitive)
        let matches = diskRegEx.matches(in: resp.output)
        guard matches.count == 1 else {
            throw RamDiskError.couldNoFindMountPoint(disk: disk)
        }
        
        return String(resp.output[matches[0].range(at: 1)!])
    }
    
    /// Unmounts the given RamDisk
    /// - Parameter disk: The disk ID of the RamDisk to unmount
    private static func unmout(disk: String, force: Bool = true) throws {
        var args: [String] = []
        if force { args = ["-f"] }
        args.append(disk)
        _ = try execute(launchPath: "/sbin/umount",
                        arguments: args)
    }
    /// Detach the given RamDisk
    /// - Parameter disk: The disk ID of the RamDisk to detach
    private static func detach(disk: String) throws {
        _ = try execute(launchPath: "/usr/bin/hdiutil",
                        arguments: "detach", disk)
    }
    
    /// Remove the RamDisk
    /// - Parameters:
    ///   - disk: The disk ID of the RamDisk
    ///   - removeVolumePath: Indicator if the folder where a custom mountPoint was linked should be deleted after remove
    public static func remove(disk: String, removeVolumePath: Bool = false) throws {
        var mountPoint: String? = nil
        
        if removeVolumePath {
            let mp = try getDiskMountPoint(disk: disk)
            if !mp.hasPrefix("/Volumes") {
                mountPoint = mp
            }
        }
        
        try unmout(disk: disk)
        try detach(disk: disk)
        if let mp = mountPoint {
            try FileManager.default.removeItem(atPath: mp)
        }
    }
    
}
