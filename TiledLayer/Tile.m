//
//  Tile.m
//  Flyskyhy
//
//  Created by René Dekker on 26/05/2012.
//  Copyright (c) 2012 Renevision. All rights reserved.
//

#import "Tile.h"

@implementation Tile

@synthesize nativeZoomX;
@synthesize nativeZoomY;

- (NSString *) description
{
    return [NSString stringWithFormat:@"[%p frame=%@ zoomX=%g zoomY=%g hidden=%d valid=%d]", self, NSStringFromCGRect(self.frame), nativeZoomX, nativeZoomY, self.hidden, self.zPosition == 1];
}

// disable all animations on tiles
- (id <CAAction>) actionForKey:(NSString *)key
{
    return nil;
}

- (void) drawInContext:(CGContextRef)ctx
{
    [super drawInContext:ctx];
}

- (void) redraw
{
    if (self.delegate != nil) {
        
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGSize size = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef gc = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
        CGContextSetFillColorSpace(gc, rgbColorSpace);
        CGContextSetStrokeColorSpace(gc, rgbColorSpace);
        CGContextScaleCTM(gc, scale, scale);
        CGContextTranslateCTM(gc, -self.bounds.origin.x, -self.bounds.origin.y);

        [self.delegate drawLayer:self inContext:gc];
        
        CGImageRef cgImage = CGBitmapContextCreateImage(gc);

        self.contents = (__bridge id) cgImage;
        [CATransaction flush];
        CGImageRelease(cgImage);
        CGContextRelease(gc);
        CGColorSpaceRelease(rgbColorSpace);
    }
}

// do not call setNeedsDisplay on a tile. Call it on the TiledLayer instead
- (void) setNeedsDisplay
{
    assert(NO);
}

- (void) setNeedsDisplayInRect:(CGRect)r
{
    assert(NO);
}

@end
