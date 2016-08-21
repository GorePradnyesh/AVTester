//
//  SimpleEntry.cpp
//  AVTester
//
//  Created by Pradnyesh Gore on 8/20/16.
//  Copyright © 2016 Pradnyesh Gore. All rights reserved.
//

#include <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <AVFoundation/AVFoundation.h>


#include <Photos/Photos.h>

#include "SimpleEntry.h"

// anon
namespace
{
	/*
	void ListCameraRollAssets()
	{
		PHFetchResult *allVideos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
		PHContentEditingInputRequestOptions* options = [[PHContentEditingInputRequestOptions alloc] init];
		[allVideos enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop)
		{
			[asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput* input, NSDictionary* info) {
				NSURL* url = [input fullSizeImageURL];
				NSLog(@"URL : %@", url);
			}];
			
		}];
	}
	 */
}

static NSString* FourCCString(FourCharCode code) {
	NSString* result = [NSString stringWithFormat:@"%c%c%c%c",
						(code >> 24) & 0xff,
						(code >> 16) & 0xff,
						(code >> 8) & 0xff,
						code & 0xff];
	NSCharacterSet* characterSet = [NSCharacterSet whitespaceCharacterSet];
	return [result stringByTrimmingCharactersInSet:characterSet];
}

void AVEntry::xDecodeEntry()
{
	NSBundle* mainBundle = [NSBundle mainBundle];
	NSString* testResourcePath = [mainBundle pathForResource:@"TestResource1" ofType:@"m4v"];
	NSLog(@"Resource : %@", testResourcePath);
	
	if(testResourcePath != nil)
	{
		NSURL* resourceURL = [NSURL fileURLWithPath:testResourcePath];
		AVAsset* resourceAsset = [AVAsset assetWithURL:resourceURL];
		
		NSArray<AVMetadataItem *> *commonMetadata = resourceAsset.commonMetadata;
		NSLog(@"Common metadata size : %d", (int)[commonMetadata count]);
		
		CMTime duration = resourceAsset.duration;
		NSLog(@"Duration : Value : %lld, Timescale : %d", duration.value, duration.timescale);
		
		/*
		NSArray<AVMetadataItem *> *metadata = resourceAsset.metadata;
		for(AVMetadataItem* metadataItem in metadata)
		{
			NSLog(@"Metdata item : %@", metadataItem);
		}
		 */
		
		BOOL canProvidePreciseTiming = resourceAsset.providesPreciseDurationAndTiming;
		NSLog(@"CAn provide precise timing : %d", canProvidePreciseTiming);
		
		
		// AssetReader
		NSError* decodeError;
		AVAssetReader* assetReader = [[AVAssetReader alloc] initWithAsset:resourceAsset error:&decodeError];
		
		if(decodeError != nil)
		{
			NSLog(@"Error !! : %@", decodeError);
		}
		
		NSArray<AVAssetTrack*> *videoTracks = [resourceAsset tracksWithMediaType:AVMediaTypeVideo];
		if([videoTracks count] > 0)
		{
			AVAssetTrack* videoTrack = videoTracks[0];
			NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];			
			AVAssetReaderTrackOutput *assetReaderVideoTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
			
			[assetReader addOutput:assetReaderVideoTrackOutput];
			[assetReader startReading];
			while ([assetReader status] == AVAssetReaderStatusReading)
			{
				CMSampleBufferRef cmSampleBuffer = [assetReaderVideoTrackOutput copyNextSampleBuffer];
				
				// Write sample buffer contents to disk
				#if 0
				CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(cmSampleBuffer);
				CIImage* imageFromPixelBuffer = [CIImage imageWithCVPixelBuffer:pixelBuffer];
				CIContext* context = [CIContext contextWithOptions:nil];
				CGImageRef image = [context createCGImage:imageFromPixelBuffer fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
				UIImage* uiImage = [UIImage imageWithCGImage:image];
				NSString* tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"png"]];
				[UIImagePNGRepresentation(uiImage) writeToFile:tempFile atomically:YES];
				#endif
				
				
				CMTime decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(cmSampleBuffer);
				CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(cmSampleBuffer);
				
				NSLog(@"SampleBuffer Decode : %lld %d", decodeTimeStamp.value, decodeTimeStamp.timescale);
				NSLog(@"SampleBuffer Presentation : %lld %d", presentationTimeStamp.value, presentationTimeStamp.timescale);
			}
		}
		
		NSArray<AVAssetTrack*> *assetTracks = resourceAsset.tracks;
		for(AVAssetTrack* assetTrack in assetTracks)
		{
			if([assetTrack.mediaType isEqualToString:AVMediaTypeVideo])
			{
				NSLog(@"Track Size :%@", NSStringFromCGSize(assetTrack.naturalSize));
				
				NSArray* formats = assetTrack.formatDescriptions;
				for (int i = 0; i < formats.count; i++) {
					CMFormatDescriptionRef desc = (__bridge CMFormatDescriptionRef)formats[i];
					// Get String representation of media type (vide, soun, sbtl, etc.)
					NSString *type = FourCCString(CMFormatDescriptionGetMediaType(desc));
					// Get String representation media subtype (avc1, aac, tx3g, etc.)
					NSString *subType = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
					// Format string as type/subType
					NSLog(@"Format Type :%@, SubType:%@", type, subType);
				}
				
				CMTime frameDuration = assetTrack.minFrameDuration;
				NSLog(@"Frame Duration : %lld, %d", frameDuration.value, frameDuration.timescale);
				
				NSArray<AVMetadataItem *> *trackMetadata = assetTrack.metadata;
				for(AVMetadataItem* trackMetadataItem in trackMetadata)
				{
					NSLog(@"Metdata item : %@", trackMetadataItem);
				}
			}
		}

	}
}
