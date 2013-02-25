//
//  StandardTileProvider.h
//  Flyskyhy
//
//  Created by René Dekker on 15/06/2012.
//  Copyright (c) 2012 Renevision. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TileProvider.h"

@interface StandardTileProvider : NSObject<TileProvider>

@property (nonatomic) float tileSizeX;
@property (nonatomic) float tileSizeY;
@property (nonatomic) bool crispX;
@property (nonatomic) bool crispY;
@property (assign) id delegate;

// TileProvider methods
- (bool) validZoomX:(float)zoomX zoomY:(float)zoomY forTile:(Tile *)tile;
- (Tile *) provideTileAtPoint:(CGPoint)point withScaleX:(float)scaleX scaleY:(float)scaleY crisp:(bool)crisp;

@end
