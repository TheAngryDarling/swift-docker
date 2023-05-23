import XCTest
import UnitTestingHelper
#if DEBUG
@testable import SwiftDockerCoreLib
#else
import SwiftDockerCoreLib
#endif



class SwiftDockerTests: XCExtenedTestCase {
    
    override class func setUp() {
        self.initTestingFile()
    }
    
    #if os(macOS)
    func testCreateRamDisk() {
        do {
            let resp = try RamDisk.create(byteSize: 1024 * 1024 * 20, volumeName: "TestVolume")
            print(resp)
            XCTAssertTrue(FileManager.default.fileExists(atPath: resp.mountPath),
                          "Cold not find RamDisk at '\(resp.mountPath)'")
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testDeleteRamDisk() {
        do {
            
            let resp = try RamDisk.create(byteSize: 1024 * 1024 * 20,
                                          volumeName: "TestDeletableVolume",
                                          mountPath: "/Users/tyler/TempDeletableVolume")
            //print(resp)
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: resp.mountPath),
                          "Cold not find RamDisk at '\(resp.mountPath)'")
            
            try FileManager.default.copyItem(atPath: "\(#file)",
                                             toPath: resp.mountPath + "/" + NSString(string: "\(#file)").lastPathComponent)
            
            try resp.resize(addingBytes: resp.originalSize)
            
            try RamDisk.remove(disk: resp.disk, removeVolumePath: resp.createdMountPath)
            if resp.createdMountPath {
                XCTAssertTrue(!FileManager.default.fileExists(atPath: resp.mountPath),
                          "RamDisk at '\(resp.mountPath)' still exists")
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testPS() {
        let appList = AppKit.NSWorkspace.shared.runningApplications
        for app in appList {
            if let e = app.executableURL,
               e.path.lowercased().contains("docker") {
                print(e.path)
            }
            //print(app.)
        }
        
    }
    
    static var allTests = [
        ("testCreateRamDisk", testCreateRamDisk),
        ("testDeleteRamDisk", testDeleteRamDisk),
        ("testPS", testPS)
        
    ]
    
    #else
    func testNothing() {
        // nothing test for linux
    }
    static var allTests = [
        ("testNothing", testNothing)
    ]
    
    #endif

    
    
}


