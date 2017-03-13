//
//  H264Encoder.m
//  直播
//
//  Created by zhangzhifu on 2017/3/13.
//  Copyright © 2017年 seemygo. All rights reserved.
//

#import "H264Encoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface H264Encoder ()
@property (nonatomic, assign) VTCompressionSessionRef compressionSession;
@property (nonatomic, assign) int frameIndex;
@end

@implementation H264Encoder

- (void)prepareEncodeWithWidth:(int)width height:(int)height {
    // 0. 设置默认为第0帧
    self.frameIndex = 0;
    
    // 1. 创建VTCompressionSessionRef
    // 1> 参数一: CFAllocatorRef用于coreFoundation中分配内存的模式
    // 2> 参数二: 编码出来视频的宽度
    // 3> 参数三: 编码出来视频的高度
    // 4> 参数四: 编码的标准
    // 5> 参数五/六/七: NULL
    // 6> 参数八: 编码成功后的回调函数
    // 7> 参数九: 可以传递到回调函数中的函数,self:将当前对象传入
    VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, didCompressionCallBack, (__bridge void * _Nullable)(self), &_compressionSession);
    
    // 2. 设置属性
    // 2.1 设置实时输出
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    
    // 2.2 设置帧率
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)(@24));
    
    // 2.3 设置比特率
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef _Nonnull)(@1500000));
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef _Nonnull)(@[@(1500000/8), @1]));
    
    // 2.4 设置gop的大小
    VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef _Nonnull)(@20));
    
    // 3. 准备编码
    VTCompressionSessionPrepareToEncodeFrames(_compressionSession);
}


- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer {
    // 1. 将CMSampleBufferRef转成CVImageBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 开始编码
    // 1. 参数一: compressionSession
    // 2. 参数二: 需要将CMSampleBufferRef转成CVImageBufferRef
    // 3. 参数三: PTS(presentationTimeStamp)/DTS(DecodeTimeStamp)
    // 4. 参数四: kCMTimeInvalid
    // 5. 参数五: 是在回掉函数中的第二个参数
    // 6. 参数六: 是在回掉函数中的第四个参数
    CMTime pts = CMTimeMake(self.frameIndex, 24);
    VTCompressionSessionEncodeFrame(self.compressionSession, imageBuffer, pts, kCMTimeInvalid, NULL, NULL, NULL);
    NSLog(@"开始编码一帧数据");
}

#pragma mark - 获取编码后的数据
void didCompressionCallBack (void * CM_NULLABLE outputCallbackRefCon,
                             void * CM_NULLABLE sourceFrameRefCon,
                             OSStatus status,
                             VTEncodeInfoFlags infoFlags,
                             CM_NULLABLE CMSampleBufferRef sampleBuffer ) {
    //    NSLog(@"编码出一帧图像");
    // 1. 判断该帧是否是关键帧
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFDictionaryRef dict = CFArrayGetValueAtIndex(attachments, 0);
    bool isKeyFrame = !CFDictionaryContainsKey(dict, kCMSampleAttachmentKey_NotSync);
    
    // 2. 如果是关键帧,获取SPS/PPS数据,并且写入文件
    if (isKeyFrame) {
        // 2.1 从CMSampleBufferRef中获取CMFormatDescriptionRef
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 2.2. 获取sps信息: index = 0
        const uint8_t *spsOut;
        size_t spsSize, spsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &spsOut, &spsSize, &spsCount, NULL);
        
        // 2.3 获取pps信息
        const uint8_t *ppsOut;
        size_t ppsSize, ppsCount;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &ppsOut, &ppsSize, &ppsCount, NULL);
        
        // 2.4 将sps/pps转成NSData,并且写入文件
        NSData *spsData = [NSData dataWithBytes:spsOut length:spsSize];
        NSData *ppsData = [NSData dataWithBytes:ppsOut length:ppsSize];
        
        // 2.5 写入文件
        
    }
    
    // 3. 获取编码后的数据,写入文件
    // 3.1 获取CMBlockBufferRef
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    
    // 3.2 从blockBuffer中获取起始位置的内存地址
    size_t totalLength = 0;
    char *dataPointer;
    CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &totalLength, &dataPointer);
    
    // 3.3 一帧图像可能要写入多个NALU单元 -> Slice切片
    static const int H264HeaderLength = 4;
    size_t bufferOffset = 0;
    while (bufferOffset < totalLength - H264HeaderLength) {
        // 3.4 从起始位置拷贝H264HeaderLength长度的地址,计算NALULength
        int NALULength = 0;
        memcpy(&NALULength, dataPointer + bufferOffset, H264HeaderLength);
        
        // 大端模式/小段模式/系统端模式
        // H264编码的数据是大端模式
        NALULength = CFSwapInt32BigToHost(NALULength);
        
        // 3.5 从dataPointer开始,根据长度创建NSData
        NSData *data = [NSData dataWithBytes:dataPointer + bufferOffset + H264HeaderLength length:NALULength];
        
        // 3.6 写入文件
        
        // 3.7 重新设置bufferOffset
        bufferOffset += NALULength + H264HeaderLength;
    }
}

@end
