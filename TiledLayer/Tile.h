//
//  Tile.h
//  Flyskyhy
//
//  Created by René Dekker on 26/05/2012.
//  Copyright (c) 2012 Renevision. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface Tile : CALayer

@property (nonatomic) float nativeZoomX;
@property (nonatomic) float nativeZoomY;

- (void) redraw;

@end
