//
//  TiledLayer.h
//  Flyskyhy
//
//  Created by René Dekker on 31/05/2012.
//  Copyright (c) 2012-2017 Renevision. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TileProvider.h"

@interface TiledLayer : CALayer

enum {
    TiledLayerAfterZoom = 0x01,
    TiledLayerCrisp = 0x02,
    TiledLayerAll = 0x04,
    TiledLayerUnblock = 0x08,
    TiledLayerLayoutNeeded = 0x4000, // private use only
    TiledLayerLayoutOngoing = 0x8000 // private use only
};
typedef uint32_t TiledLayerFlags;    // explicitly declare type of enum

@property (nonatomic, strong) id<TileProvider> provider;
@property (nonatomic) float marginX;
@property (nonatomic) float marginY;
@property (nonatomic) bool keepOffScaleTiles;


// IMPORTANT: TiledLayer MUST have an ancestor CALayer whose masksToBounds property is set. The closest ancestor that
// has that property set MUST have a fixed position wrt the screen of the device and must not be transformed in any way.
// TiledLayer uses this ancestor to determine what area is visible on screen, and how it is transformed before being displayed.

//
// layoutTilesWithFlags: does a new layout of the tiles. The layout and drawing of tiles will be done from a background thread.
//
// This method must be called after each change in visible area, or zoom change.
// It will determine which tiles are visible and valid, and will request new tiles for the areas that are exposed
// and not covered with valid tiles. Each new tile is requested through a call to provideTileAtPoint:withScaleX:scaleY:crisp:
// of the provider; see the TileProvider protocol for details.
// The method will also remove tiles that are no longer visible, and calls discardTile: of the provider for such tiles
// (if implemented by the provider).
//
// Provide the flag TiledLayerAfterZoom if a change of scale of the TiledLayer has occured, or could have occured. Certain
// performance improvements are taken when the flag is not provided.
// Provide the flag TiledLayerCrisp if you require the tiles to exactly match the scale of the TiledLayer. The crisp parameter
// of provideTileAtPoint:withScaleX:scaleY:crisp: will be set for any new tiles if this flag is given. The crisp parameter
// will never be set if the TiledLayerCrisp flag is not given.
// Provide the flag TiledLayerAll if you require all tiles to be replaced, even tiles that are still valid. Note that this
// does not guarantee that all tiles are indeed removed: if provideTileAtPoint:withScaleX:scaleY:crisp: returns a hidden
// tile, then any existing tile covering that area will still remain.
// If the tiled layer is blocked (see removeAllAndBlock:), then this operation is a no-op. Provide the flag TiledLayerUnblock
// to unblock the tiled layer and do a layout.
//
// Note that you should not call layoutTilesWithFlags: if the existing tiles only need to be redrawn. Call setNeedsDisplay
// instead in such a case.
//
- (void) layoutTilesWithFlags:(TiledLayerFlags)flags;

//
// layoutTiles is a short-cut for calling layoutTilesWithFlags:0
//
- (void) layoutTiles;

//
// removeAll removes all existing tiles from the TiledLayer, and calls discardTile: on the provider for them.
// This method does not request new tiles. Call layoutTilesWithFlags: to refill the TiledLayer with tiles.
// If blocked is YES, then subsequent layoutTiles or setNeedsDisplay will have no effect until layoutTilesWithFlags: is called with
// flag TiledLayerUnblock.
//
- (void) removeAllAndBlock:(bool)blocked;

//
// setNeedsDisplay causes all tiles to be redrawn from a background thread. The redraw method of each tile will be called,
// which by default will call the drawLayer:inContext: method of the Tile's delegate.
// setNeedsDisplay is a light-weight method that may be called multiple times. Multiple calls will be coalesced into one
// redraw cycle.
// If the tiled layer is blocked (see removeAllAndBlock:) then this operation is a no-op. To unblock, call layoutTilesWithFlags:
// with flag TiledLayerUnblock.
//
- (void) setNeedsDisplay;

@end
