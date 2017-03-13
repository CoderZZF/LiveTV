//
//  H264Encoder.h
//  直播
//
//  Created by zhangzhifu on 2017/3/13.
//  Copyright © 2017年 seemygo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface H264Encoder : NSObject

- (void)prepareEncodeWithWidth:(int)width height:(int)height;
- (void)encodeFrame:(CMSampleBufferRef)sampleBuffer;


- (void)endEncode;
@end
