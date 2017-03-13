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
@end

@implementation H264Encoder

- (void)prepareEncodeWithWidth:(int)width height:(int)height {
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
    
}

#pragma mark - 获取编码后的数据
void didCompressionCallBack (void * CM_NULLABLE outputCallbackRefCon,
                             void * CM_NULLABLE sourceFrameRefCon,
                             OSStatus status,
                             VTEncodeInfoFlags infoFlags,
                             CM_NULLABLE CMSampleBufferRef sampleBuffer ) {
    NSLog(@"编码出一帧一帧的图像");
}

@end
