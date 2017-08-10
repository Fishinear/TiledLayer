//
//  TiledLayer.m
//  Flyskyhy
//
//  Created by René Dekker on 31/05/2012.
//  Copyright (c) 2012-2017 Renevision. All rights reserved.
//

#import "TiledLayer.h"
#import <stdatomic.h>

#define ZPOS_VALIDZOOM 1
#define ACC  (1e-3f)

@interface InsertPoint : NSObject
@property (nonatomic) int index;
@property (nonatomic, strong) Tile *tile;
@end

@implementation InsertPoint
@synthesize index;
@synthesize tile;

- (id) initWithIndex:(int)anIndex tile:(Tile *)aTile
{
    if (!(self = [super init])) {
        return nil;
    }
    index = anIndex;
    tile = aTile;
    return self;
}

@end

@implementation TiledLayer {
    CGRect exposedRect;
    float zoomScaleX;
    float zoomScaleY;
    NSMutableArray *tempTiles;
    NSMutableArray *insertions;
    _Atomic TiledLayerFlags neededFlags;
    atomic_flag redrawNeeded;
    NSSet *theTiles;
    NSMutableSet *totalTilesToKeep;
    bool isBlocked;
}

@synthesize provider;
@synthesize marginX;
@synthesize marginY;
@synthesize keepOffScaleTiles;

- (void) insertNewTile:(Tile *)newTile afterIndex:(int)index
{
    CGFloat minY = CGRectGetMinY(newTile.frame);
    for (; index < tempTiles.count; index++) {
        Tile *tile = [tempTiles objectAtIndex:index];
        if (CGRectGetMinY(tile.frame) < minY) {
            break;
        }
    }
    [tempTiles insertObject:newTile atIndex:index];
    [insertions addObject:[[InsertPoint alloc] initWithIndex:index tile:newTile]];
}

- (void) removeTile:(Tile *)tile
{
    [tile removeFromSuperlayer];
    tile.contents = nil;
    // inform provider
    if ([provider respondsToSelector:@selector(discardTile:)]) {
        [provider discardTile:tile];
    }
}

- (void) removeTilesPassingTest:(BOOL (^)(Tile *obj))mustRemove
{
    NSMutableSet *toRemove = [NSMutableSet set];
    for (Tile *tile in self.sublayers) {
        if (mustRemove(tile)) {
            [toRemove addObject:tile];
        }
    }
    for (Tile *tile in toRemove) {
        [self removeTile:tile];
    }
}

- (Tile *) addNewTileForPoint:(CGPoint)point atIndex:(int)idx crisp:(bool)crisp
{
    Tile *newTile = [provider provideTileAtPoint:point withScaleX:zoomScaleX scaleY:zoomScaleY crisp:crisp];
    newTile.actions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"zPosition", nil];
    newTile.zPosition = ZPOS_VALIDZOOM;
    newTile.transform = CATransform3DMakeScale(newTile.nativeZoomX, newTile.nativeZoomY, 1.0);
    newTile.edgeAntialiasingMask = 0;
    
    // safety check: check that tile actually includes point
    CGFloat accX = MAX(zoomScaleX / 2, 1); // accuracy is half a pixel
    CGFloat accY = MAX(zoomScaleY / 2, 1);
    if (!CGRectContainsPoint(CGRectInset(newTile.frame, -accX, -accY), point)) {
        [self removeTile:newTile];
        return nil;
    }
    
    [self insertNewTile:newTile afterIndex:idx];
    
    return newTile;
}

- (void) filter:(NSMutableSet *)tiles withMaxY:(CGFloat)maxY
{
    NSMutableSet *toRemove = [NSMutableSet set];
    for (Tile *tile in tiles) {
        if (CGRectGetMaxY(tile.frame) <= maxY) {
            [toRemove addObject:tile];
        }
    }
    [tiles minusSet:toRemove];
}

static double distanceBetweenTwoPoints(CGPoint point1,CGPoint point2)
{
    double dx = point2.x - point1.x;
    double dy = point2.y - point1.y;
    return hypot(dx, dy);
};

- (bool) determineZoom:(CALayer *)rootLayer flags:(TiledLayerFlags)flags
{
    //    DLog(@"%p rootLayer=%@ flags=%d", self, rootLayer, flags);
    CGPoint zero = [self convertPoint:CGPointZero toLayer:rootLayer];
    CGPoint xpoint = [self convertPoint:CGPointMake(100, 0) toLayer:rootLayer];
    CGPoint ypoint = [self convertPoint:CGPointMake(0, 100) toLayer:rootLayer];
    float zoomX = 100/distanceBetweenTwoPoints(zero, xpoint);
    float zoomY = 100/distanceBetweenTwoPoints(zero, ypoint);
    bool crisp = (flags & (TiledLayerCrisp|TiledLayerAll)) != 0;
    double allOffset = (flags & TiledLayerAll) != 0 ? 0.1 : 0;
    if (!crisp && fabs(zoomX / zoomScaleX - 1) < ACC && fabs(zoomY / zoomScaleY - 1) < ACC) {
        return YES;
    }
    int outdatedTiles = 0;
    for (Tile *tile in self.sublayers) {
        if (!crisp && [provider validZoomX:zoomX zoomY:zoomY forTile:tile]) {
            tile.zPosition = ZPOS_VALIDZOOM;
        } else {
            double pos = (zoomX * zoomY) / (tile.nativeZoomX * tile.nativeZoomY);
            if (pos > 1) {
                pos = 1/pos;
            }
            pos -= allOffset;
            tile.zPosition = pos;
            if (pos != 1) {
                outdatedTiles++;
            }
        }
        //        DLog(@"tile=%@ zpos=%g", tile, tile.zPosition);
    }
    zoomScaleX = zoomX;
    zoomScaleY = zoomY;
    return outdatedTiles == 0;
}

- (void) updateExposedRectWithTile:(CGRect)frame outsideBounds:(CGRect)bounds
{
    CGFloat minx = CGRectGetMinX(frame);
    if (minx <= CGRectGetMinX(bounds) && minx > CGRectGetMinX(exposedRect)) {
        exposedRect.size.width -= minx - exposedRect.origin.x;
        exposedRect.origin.x = minx;
    }
    CGFloat miny = CGRectGetMinY(frame);
    if (miny <= CGRectGetMinY(bounds) && miny > CGRectGetMinY(exposedRect)) {
        exposedRect.size.height -= miny - exposedRect.origin.y;
        exposedRect.origin.y = miny;
    }
    CGFloat maxx = CGRectGetMaxX(frame);
    if (maxx >= CGRectGetMaxX(bounds) && maxx < CGRectGetMaxX(exposedRect)) {
        exposedRect.size.width = maxx - exposedRect.origin.x;
    }
    CGFloat maxy = CGRectGetMaxY(frame);
    if (maxy >= CGRectGetMaxY(bounds) && maxy < CGRectGetMaxY(exposedRect)) {
        exposedRect.size.height = maxy - exposedRect.origin.y;
    }
}

- (void) doLayoutTilesWithBounds:(CGRect)bounds crisp:(bool)crisp
{
    CGFloat accX = MAX(zoomScaleX / 2, 1); // accuracy is half a pixel
    CGFloat accY = MAX(zoomScaleY / 2, 1);
    CGPoint point = bounds.origin;
    exposedRect = CGRectInfinite;
    totalTilesToKeep = [NSMutableSet set];
    insertions = [NSMutableArray array];
    CGRect boundsForExposure = CGRectInset(bounds, accX, accY);
    while ((point.x += accX) < CGRectGetMaxX(bounds)) {
        // go through one vertical line at location point.x
        //                DLog(@"----- x line: %g", point.x);
        point.y = CGRectGetMinY(bounds);
        CGFloat nextX = CGRectGetMaxX(bounds);
        CGFloat highestCoveredY = point.y; // until where we have coverage by a hidden or real tile
        CGFloat currentNextY = point.y; // until where we have coverage by a visible tile
        NSMutableSet *tilesToKeep = [NSMutableSet set];
        // tiles in the array are ordered by decreasing minY. We start from the end, therefore with the botttom-most tiles.
        // (with the smallest minY).
        for (int idx = (int) tempTiles.count; idx >= 0; idx--) {
            CGFloat nextY = CGRectGetMaxY(bounds);
            Tile *tile;
            if (idx > 0) {
                tile = [tempTiles objectAtIndex:idx-1];
                //                                DLog(@"Examining tile:%@ for point:%@", tile, NSStringFromCGPoint(point));
                if (CGRectGetMinY(tile.frame) < nextY) {
                    nextY = CGRectGetMinY(tile.frame);
                    CGFloat rightEdge = CGRectGetMaxX(tile.frame);
                    if (rightEdge < point.x) {
                        // if the tile is completely left of the current X, then we have already treated it
                        continue;
                    }
                    if (point.x < CGRectGetMinX(tile.frame)) {
                        // if the tile is completely right of the current X, then we need to make sure we don't forget it
                        rightEdge -= 2 * accX;
                        if (rightEdge < nextX) {
                            nextX = rightEdge;
                        }
                        continue;
                    }
                    // else, the tile covers the current x line, treat it.
                }
            }
            while (nextY > point.y) {
                // we have a gap between the current tile and the previous ones
                Tile *newTile;
                //                                DLog(@"Gap detected: nextY=%g point.y=%g", nextY, point.y);
                if (highestCoveredY + accY < nextY &&
                    // the gap is at least partly real. Request a tile to fill it, then check again.
                    (newTile = [self addNewTileForPoint:CGPointMake(point.x, highestCoveredY + accY) atIndex:idx crisp:crisp]) != nil)
                {
                    // increment the index, so the existing tile is re-examined again in the next cycle of the loop
                    idx++;
                    tile = newTile;
                    nextY = CGRectGetMinY(tile.frame);
                }  else {
                    // gap is fully covered by hidden valid tiles. Keep the tiles that fill the gap.
                    [totalTilesToKeep unionSet:tilesToKeep];
                    [tilesToKeep removeAllObjects];
                    point.y = nextY + accY;
                }
            }
            if (point.y >= CGRectGetMaxY(bounds)) {
                break;
            }
            CGFloat rightEdge = CGRectGetMaxX(tile.frame);
            if (rightEdge < nextX) {
                nextX = rightEdge;
            }
            if (CGRectGetMaxY(tile.frame) < point.y) {
                continue;
            }
            // the tile covers the point. Now check whether it is a valid tile
            if (tile.zPosition == ZPOS_VALIDZOOM) {
                [totalTilesToKeep addObject:tile];
                [self updateExposedRectWithTile:tile.frame outsideBounds:boundsForExposure];
                CGFloat topEdge = CGRectGetMaxY(tile.frame);
                if (topEdge > highestCoveredY) {
                    highestCoveredY = topEdge;
                }
                if (!tile.hidden) {
                    // we have a valid tile. Skip to its bottom side
                    point.y = topEdge + accY;
                    if (topEdge > currentNextY) {
                        currentNextY = topEdge;
                    }
                    // remove the alternative tiles we had for this point so far, as long as they do not cover
                    // the new point as well
                    if (!keepOffScaleTiles) {
                        [self filter:tilesToKeep withMaxY:point.y];
                    }
                } else {
                    // zoom is valid, but the tile is hidden. We assume it will come later, but don't remove any alternative tiles yet
                }
            } else {
                if (!tile.hidden) {
                    // the tile's zoomFactor is not correct, keep looking for a correct one
                    [tilesToKeep addObject:tile];
                    CGFloat bottomEdge = CGRectGetMaxY(tile.frame);
                    if (bottomEdge > currentNextY) {
                        currentNextY = bottomEdge;
                    }
                } else {
                    // tile is useless, and should be removed
                }
            }
        } // end for each tile
        if (nextX > point.x) {
            point.x = nextX;
        } else {
            // internal error: we should have requested a tile in this situation
            point.x += 100;
        }
    }
    tempTiles = nil;
    //    DLog(@"redraw new tiles");
    // make sure the new tiles are up to date
    for (InsertPoint *point in insertions) {
        [point.tile redraw];
    }
}

- (void) updateLayer
{
    //    @autoreleasepool {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    // add the new tiles
    for (InsertPoint *point in insertions) {
        Tile *newTile = point.tile;
        [self insertSublayer:newTile atIndex:point.index];
    }
    // now remove the tiles that are not visible
    [self removeTilesPassingTest:^BOOL(Tile *tile) {
        return ![totalTilesToKeep containsObject:tile];
    }];
    [CATransaction commit];
    insertions = nil;
    //    }
    
    // flags = neededFlags &= ~TiledLayerLayoutOngoing;
    
    TiledLayerFlags flags = atomic_fetch_and(&neededFlags, ~TiledLayerLayoutOngoing);
    if ((flags & TiledLayerLayoutNeeded) != 0) {
        [self layoutTilesWithFlags:flags];
    }
}

- (CALayer *) determineRootLayer
{
    CALayer *layer = self;
    while (!layer.masksToBounds && layer.superlayer != nil) {
        layer = layer.superlayer;
    }
    return layer;
}

- (void) layoutTilesWithFlags:(TiledLayerFlags)flags
{
    if (isBlocked && (flags & TiledLayerUnblock) == 0) {
        return;
    }
    isBlocked = NO;
    if (provider == nil) {
        return;
    }
    // origFlags = neededFlags;
    // neededFlags |= flags | TiledLayerLayoutNeeded|TiledLayerLayoutOngoing
    // if (origFlags & TiledLayerLayoutOngoing) { return; }
    TiledLayerFlags originalFlags = atomic_fetch_or(&neededFlags, flags | TiledLayerLayoutNeeded|TiledLayerLayoutOngoing);
    if (originalFlags & TiledLayerLayoutOngoing) {
        return;
    }
    CALayer *rootLayer = [self determineRootLayer];
    bool noChange;
    CGRect bounds;
    uint32_t value = 0;
    do {
        flags = neededFlags;
        
        noChange = YES;
        if (flags & (TiledLayerAfterZoom|TiledLayerCrisp|TiledLayerAll)) {
            noChange = [self determineZoom:rootLayer flags:flags];
        }
        CGRect requiredBounds = [self convertRect:rootLayer.bounds fromLayer:rootLayer];
        bounds = CGRectInset(requiredBounds, -(marginX - 0.5) * zoomScaleX, -(marginY - 0.5) * zoomScaleY);
        noChange = noChange && CGRectContainsRect(exposedRect, bounds);
        // if (flags == neededFlags) {
        //    neededFlags = noChange ? 0 : TiledLayerLayoutOngoing;
        //    break;
        // }
        value = noChange ? 0 : TiledLayerLayoutOngoing;
    } while (!atomic_compare_exchange_weak(&neededFlags, &flags, value));
    if (noChange) {
        return;
    }
    
    tempTiles = [NSMutableArray array];
    [tempTiles addObjectsFromArray:self.sublayers];
    
    dispatch_async(queue, ^{
        [self doLayoutTilesWithBounds:bounds crisp:(flags & TiledLayerCrisp) != 0];
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self updateLayer];
        });
    });
}

- (void) layoutTiles
{
    [self layoutTilesWithFlags:0];
}

- (void) removeAllAndBlock:(bool)blocked
{
    isBlocked = blocked;
    [self removeTilesPassingTest:^BOOL(Tile *tile) { return YES; }];
    exposedRect = CGRectNull;
}

- (void) setNeedsDisplay
{
    if (isBlocked) {
        return;
    }
    // if (redrawNeeded == 0) { redrawNeeded = 1; ... }
    if (!atomic_flag_test_and_set(&redrawNeeded)) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1000);
        dispatch_after(popTime, queue, ^{
            // Reset the flag and then do the redraw. If setNeedsDisplay is called during that time,
            // then a new redraw will be queued
            atomic_flag_clear(&redrawNeeded);
            for (Tile *tile in totalTilesToKeep) {
                [tile redraw];
            }
        });
    }
}

#pragma mark - Object Life Cycle

static dispatch_queue_t queue;

+ (void) initialize
{
    if (self != [TiledLayer class]) {
        return;
    }
    queue = dispatch_queue_create("com.renevision.TiledLayer", NULL);
}

- (id) init
{
    if( !(self = [super init]) ) {
        return nil;
    }
    exposedRect = CGRectNull;
    zoomScaleX = 1.0f;
    zoomScaleY = 1.0;
    marginX = 50;
    marginY = 50;
    keepOffScaleTiles = NO;
    atomic_flag_clear(&redrawNeeded);
    isBlocked = NO;
    totalTilesToKeep = [NSMutableSet set];
    neededFlags = 0;
    self.actions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"zPosition", nil];
    self.bounds = CGRectMake(-1, -1, 2, 2);
    
    return self;
}

- (void) setBounds:(CGRect)bounds
{
    // if bounds is zero, then drawInContext will not be called after a setNeedsDisplay, even though
    // masksToBounds is NO
    if (bounds.size.width <= 0) {
        bounds.size.width = 1;
    }
    if (bounds.size.height <= 0) {
        bounds.size.height = 1;
    }
    [super setBounds:bounds];
}

@end
