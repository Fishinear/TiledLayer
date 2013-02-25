//
//  StandardTileProvider.m
//  Flyskyhy
//
//  Created by René Dekker on 15/06/2012.
//  Copyright (c) 2012 Renevision. All rights reserved.
//

#import "StandardTileProvider.h"

#define HIGHLIMIT 1.5f
#define LOWLIMIT 0.7f

#define ACCURACY 1e-7

double floorMod(double x, double modValue)
{
	return floor(x/modValue + ACCURACY) * modValue;
}

unsigned int floorToFactor2( unsigned int v )
{
    unsigned int zoom = 1;
    while (v >>= 1) {
        zoom <<= 1;
    }
    return zoom;
}

@implementation StandardTileProvider

@synthesize tileSizeX;
@synthesize tileSizeY;
@synthesize crispX;
@synthesize crispY;
@synthesize delegate;

- (void) drawLayer:(CALayer *)tile inContext:(CGContextRef)gc
{
    [delegate drawLayer:tile inContext:gc];
}

#pragma mark - TileProvider protocol

- (bool) validZoomX:(float)zoomX zoomY:(float)zoomY forTile:(Tile *)tile
{
    float xFactor = zoomX / tile.nativeZoomX;
    float yFactor = zoomY / tile.nativeZoomY;
    return LOWLIMIT < xFactor && xFactor < HIGHLIMIT && LOWLIMIT < yFactor && yFactor < HIGHLIMIT;
}

- (Tile *) provideTileAtPoint:(CGPoint)point withScaleX:(float)scaleX scaleY:(float)scaleY crisp:(bool)crisp
{
    if (!crisp) {
        if (!crispX) {
            scaleX = floorToFactor2(scaleX * HIGHLIMIT);
        }
        if (!crispY) {
            scaleY = floorToFactor2(scaleY * HIGHLIMIT);
        }
    }
    point = CGPointMake(point.x/scaleX, point.y/scaleY);
    CGFloat x = floorMod(point.x, tileSizeX);
    CGFloat y = floorMod(point.y, tileSizeY);
    Tile *tile = [Tile layer];
    tile.contentsScale = [UIScreen mainScreen].scale;
    tile.nativeZoomX = scaleX;
    tile.nativeZoomY = scaleY;
    tile.position = CGPointZero;
    tile.bounds = CGRectMake(x, y, tileSizeX, tileSizeY);
    tile.masksToBounds = NO;
    tile.anchorPoint = CGPointMake(-x/tileSizeX, -y/tileSizeY);
    tile.delegate = self;

    return tile;
}

#pragma mark - Object Life Cycle

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    tileSizeX = 300;
    tileSizeY = 300;
    crispX = NO;
    crispY = NO;
    return self;
}

@end
