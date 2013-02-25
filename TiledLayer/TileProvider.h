//
//  TileProvider.h
//  Flyskyhy
//
//  Created by René Dekker on 26/05/2012.
//  Copyright (c) 2012 Renevision. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "Tile.h"

@protocol TileProvider <NSObject>

// A TiledLayer assumes the world is fully covered with tiles. Each tile is independent and represents a patch of ground.

//
// Returns whether the tile is applicable for the given zoom scale. Scale is given in world units per pixel.
// Typically it will return true when the tile's nativeZoom properties are 'near' the given zoom values.
//
- (bool) validZoomX:(float)scaleX 
              zoomY:(float)scaleY 
            forTile:(Tile *)tile;

//
// Returns a tile that covers the given point with a scale as close as possible to the given scale.
// The point is given in real world units. Scale is given in world units per pixel.
// The bounds of the tile should be set to the position and size the tile in real world units.
// The tiles contents property should be set to the image, or the tile must do its drawing in drawRect:
// The tiles nativeZoom properties must be set to the actual world unit / pixel scale of the image.
// IMPORTANT: They must be set such that a call to validZoomX:zoomY:forTile: with the same zoom scales would return true.
// If no image is available at this time, then return a tile with its hidden property set to true. Once the image becomes
// available, set the tile's contents property and set the hidden property to false.
// If the crisp parameter is true, then you MUST return a tile with nativeZoom exactly equal to the given scale. Crisp will
// only be true when TiledLayer layoutTilesWrtRoot: has been called with crisp parameter set.
//
// This method assumes the world is fully covered with tiles: you must always return a tile that covers the point. If part
// of the world is empty, then return a tile with the correct bounds and keep its hidden property true. 
//
- (Tile *) provideTileAtPoint:(CGPoint)point 
                   withScaleX:(float)scaleX 
                       scaleY:(float)scaleY
                        crisp:(bool)crisp;


@optional

//
// Will by called by TiledLayer after a tile is removed from the TiledLayer (typically shortly after it is no longer
// visible).
// Any cleanup action that is required may be done from here. The removeFromSuperlayer: method of the tile is already
// called prior to this method, and therefore does not need to be called again.
//
- (void) discardTile:(Tile *)tile;

@end
