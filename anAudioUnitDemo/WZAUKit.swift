//
//  WZAUKit.swift
//  anAudioUnitDemo
//
//  Created by August on 2022/7/5.
//

import AVFoundation


class WZAUKit {
    
    static let share = WZAUKit()
    
    init() { }
    
    static func audioFile(_ name: String = "demo") -> URL? {
        if var first = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if #available(iOS 16.0, *) {
                return first.appending(path: "/a/\(name).wav")
            } else {
                first.appendPathComponent("/a/\(name).wav")
            }
            return first
        }
        return nil
    }
    
    static let kPreferredIOBufferDuration: TimeInterval = 0.005;
    static let kPreferredSampleRate: Double = 48000;
    
    static func checkError<T>(_ f: (T) throws -> (), param: T) -> Bool {
        do {
            try f(param)
        } catch let e {
            debugPrint("Error: \(e), \n >>>> the param: \(param)")
            return false
        }
        return true
    }
    
    ///
    @discardableResult
    static func setupAudioSessionForCategory(_ category: AVAudioSession.Category) -> Bool {
        
        let session = AVAudioSession.sharedInstance()
        
        guard checkError(session.setCategory(_:), param: category) else { return false }
        
        guard checkError(session.setPreferredIOBufferDuration(_:), param: kPreferredIOBufferDuration) else { return false }
        
        guard checkError(session.setPreferredSampleRate(_:), param: kPreferredSampleRate) else { return false }
        func active(_ b: Bool) throws {
            try session.setActive(b)
        }
        guard checkError(active(_:), param: true) else { return false }
        
        return true
    }
    
    static func openFile() {
        
        guard let file = audioFile() else { return debugPrint("no such file path") }
        
        var audioFileID: AudioFileID?
        let state = AudioFileOpenURL(file as CFURL, .readPermission, kAudioFileWAVEType, &audioFileID)
        guard share.checkOSState(state, oprationDes: "AudioFileOpenURL") else { return }
        
    }
    
    func setupAudioUnit(_ io_unit_: inout AudioUnit?) {
        var io_unit_des: AudioComponentDescription = .init(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_RemoteIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
        
        guard let io_unit_ref = AudioComponentFindNext(nil, &io_unit_des) else { return }
        
//        var io_unit_ = io_unit_
        
        guard checkOSState(AudioComponentInstanceNew(io_unit_ref, &io_unit_), oprationDes: "create io unit") else { return }
        
        var enable_input: UInt32 = 1
        guard checkOSState(AudioUnitSetProperty(io_unit_!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enable_input, UInt32(MemoryLayout<UInt32>.size)), oprationDes: "Property_EnableIO") else { return }
        
        var enable_output: UInt32 = 0
        guard checkOSState(AudioUnitSetProperty(io_unit_!, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &enable_output, UInt32(MemoryLayout<UInt32>.size)), oprationDes: "kAudioUnitScope_Output") else { return }
        
        var flag: UInt32 = 1
        guard checkOSState(AudioUnitSetProperty(io_unit_!, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, 1, &flag, UInt32(MemoryLayout<UInt32>.size)), oprationDes: "ShouldAllocateBuffer") else { return }
        
        
        var format: AudioStreamBasicDescription = .init(mSampleRate: 48000, mFormatID: kAudioFormatLinearPCM, mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked, mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2, mChannelsPerFrame: 1, mBitsPerChannel: 16, mReserved: 8)
        
        let size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        guard checkOSState(AudioUnitSetProperty(io_unit_!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &format, size), oprationDes: "StreamFormat_o") else { return }
        
        guard checkOSState(AudioUnitSetProperty(io_unit_!, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &format, size), oprationDes: "StreamFormat_i") else { return }
        
        
        var render: AURenderCallbackStruct = .init(inputProc: { rp, flags, timestamp, bus, numframe, listBuffer in
            
            debugPrint("render call back")
            return 0
            
        }, inputProcRefCon: Unmanaged.passUnretained(self).toOpaque())
        
        guard checkOSState(AudioUnitSetProperty(io_unit_!, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &render, UInt32(MemoryLayout<AURenderCallbackStruct>.size)), oprationDes: "render out input") else { return }
        
        // notification
        
        //
        var success = checkOSState(AudioUnitInitialize(io_unit_!), oprationDes: "init")
        
        while (!success) {
            sleep(100)
            success = checkOSState(AudioUnitInitialize(io_unit_!), oprationDes: "init")
        }
        
        
    }
    
    
    
    @discardableResult
    func checkOSState(_ state: OSStatus, oprationDes: String) -> Bool {
        guard state != 0 else { return true }
        debugPrint("OSStatus Error code: \(state), op: \(oprationDes)")
        return false
    }
    
    
}
