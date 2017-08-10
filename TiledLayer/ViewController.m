//
//  ViewController.m
//  TiledLayer
//
//  Created by René Dekker on 24/02/2013.
//  Copyright (c) 2013 Renevision. All rights reserved.
//

#import "ViewController.h"
#import "StandardTileProvider.h"
#import "TiledLayer.h"

@interface ViewController ()

@end

@implementation ViewController {
    StandardTileProvider *provider;
    TiledLayer *tiledLayer;
    double zoomScale;
    double originalZoomScale;
    CGPoint origin;
    CGPoint originalOrigin;
}

- (void) drawLayer:(CALayer *)aLayer inContext:(CGContextRef)gc
{
    Tile *tile = (Tile *)aLayer;
    
    CGRect rect = CGContextGetClipBoundingBox(gc);
    
    NSLog(@"tile bounds=%@ rect=%@ zoom=%g / %g\n", NSStringFromCGRect(aLayer.bounds), NSStringFromCGRect(rect), tile.nativeZoomX, zoomScale);
    // fill the background with white
    CGContextSetGrayFillColor(gc, 1, 1);
    CGContextFillRect(gc, rect);
    
    // draw the boundary of the tile for debugging
    UIColor *debugColor = [UIColor colorWithWhite:0.8 alpha:1];
    CGContextSetStrokeColorWithColor(gc, debugColor.CGColor);
    CGContextSetLineWidth(gc, 2);
    CGContextStrokeRect(gc, CGRectInset(rect, 5, 5));
    
    // draw the explanatory text for debugging
    // the new 'drawAtPoint:' makes this extremely complex because if flips the text upside down
    NSString *text = [NSString stringWithFormat:@"%g,%g x%g", rect.origin.x, rect.origin.y, tile.nativeZoomX];
    CGContextSaveGState(gc);
    UIGraphicsPushContext(gc);
    CGContextScaleCTM(gc, 1, -1);
    [text drawAtPoint:CGPointMake(10 + rect.origin.x, 10 - rect.size.height - rect.origin.y)
       withAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Helvetica" size:14],
                        NSForegroundColorAttributeName:debugColor}];
    UIGraphicsPopContext();
    CGContextRestoreGState(gc);
    
    // draw the real (example) contents of the tile
    CGContextScaleCTM(gc, 1/tile.nativeZoomX, 1/tile.nativeZoomY);
    CGContextSetLineWidth(gc, 30);
    CGContextSetRGBStrokeColor(gc, 1, 1, 0, 1);
    CGContextStrokeRect(gc, CGRectMake( -100, -200, 200, 300 ));
}

- (void) updateTransform:(TiledLayerFlags)flags
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CATransform3D transform = CATransform3DMakeScale(1/zoomScale, 1/zoomScale, 1.0f);
    tiledLayer.transform = CATransform3DTranslate(transform, origin.x, origin.y, 0);
    
    [CATransaction commit];
    
    [tiledLayer layoutTilesWithFlags:flags];
}

- (IBAction) handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        originalZoomScale = zoomScale;
    }
    zoomScale = originalZoomScale / sender.scale;
    
    if (zoomScale < 1) {
        zoomScale = 1;
    }

    [self updateTransform:TiledLayerAfterZoom];
}

- (IBAction) handlePanGesture:(UIPanGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        originalOrigin = origin;
    }
    CGPoint translation = [sender translationInView:self.view];
    origin = CGPointMake(originalOrigin.x + translation.x * zoomScale, originalOrigin.y + translation.y * zoomScale);
    
    [self updateTransform:0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    zoomScale = 1;
    
    CGRect frame = self.view.bounds;
    UIScrollView *view = [[UIScrollView alloc] initWithFrame:frame];
    [self.view addSubview:view];
    provider = [[StandardTileProvider alloc] init];
    provider.tileSizeX = 160;
    provider.tileSizeY = 160;
    provider.delegate = self;
    
    CALayer *centerLayer = [CALayer layer];
    centerLayer.position = CGPointMake(frame.size.width/2, frame.size.height/2);
    centerLayer.bounds = CGRectMake(-frame.size.width/2, -frame.size.height/2, frame.size.width, frame.size.height);
    centerLayer.masksToBounds = YES;
    centerLayer.backgroundColor = [UIColor whiteColor].CGColor;
    [[self.view layer] addSublayer:centerLayer];
    
    tiledLayer = [TiledLayer layer];
    tiledLayer.provider = provider;
    tiledLayer.geometryFlipped = YES;
    [centerLayer addSublayer:tiledLayer];
    
    UIGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinch];
    
    UIGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.view addGestureRecognizer:pan];
    
    [tiledLayer layoutTilesWithFlags:TiledLayerAfterZoom];
}

@end
