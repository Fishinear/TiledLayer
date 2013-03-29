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
}

- (void) drawLayer:(CALayer *)aLayer inContext:(CGContextRef)gc
{
    Tile *tile = (Tile *)aLayer;
    
    CGRect rect = CGContextGetClipBoundingBox(gc);
    
    NSLog(@"tile bounds=%@ rect=%@ zoom=%g\n", NSStringFromCGRect(aLayer.bounds), NSStringFromCGRect(rect), tile.nativeZoomX);
    CGContextSetRGBFillColor(gc, 1/tile.nativeZoomX, 1/tile.nativeZoomX, 1/tile.nativeZoomX, 1);
    CGContextSetRGBFillColor(gc, 1, 1, 1, 1);
	CGContextFillRect(gc, rect);
    
    CGContextSetRGBStrokeColor(gc, 0.9, 0.9, 0.9, 1);
    CGContextSetLineWidth(gc, 2);
    rect = CGRectInset(rect, 5, 5);
    CGContextStrokeRect(gc, rect);
    
    CGContextSetRGBFillColor(gc, 0.9, 0.9, 0.9, 1);
    CGContextSelectFont(gc, "Helvetica", 20, kCGEncodingMacRoman);
    char text[20];
    sprintf(text, "%g,%g", aLayer.bounds.origin.x, aLayer.bounds.origin.y);
    CGContextShowTextAtPoint(gc, rect.origin.x + 5, rect.origin.y + 5, text, strlen(text));
    
    CGContextScaleCTM(gc, 1/tile.nativeZoomX, 1/tile.nativeZoomY);
    CGContextSetLineWidth(gc, 30);
    CGContextSetRGBStrokeColor(gc, 1, 1, 0, 1);
    CGContextStrokeRect(gc, CGRectMake( -100, -100, 200, 200 ));
    
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

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CATransform3D transform = CATransform3DMakeScale(1/zoomScale, 1/zoomScale, 1.0f);
    tiledLayer.transform = CATransform3DTranslate(transform, 0, 0, 0);

    [CATransaction commit];
    
    [tiledLayer layoutTilesWithFlags:TiledLayerAfterZoom];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    zoomScale = 1;
    
    CGRect frame = CGRectMake(0, 0, 320, 320);
    UIScrollView *view = [[UIScrollView alloc] initWithFrame:frame];
    [self.view addSubview:view];
    provider = [[StandardTileProvider alloc] init];
    provider.tileSizeX = 150;
    provider.tileSizeY = 150;
    provider.delegate = self;

	CALayer *centerLayer = [CALayer layer];
	centerLayer.position = CGPointMake(160, 160);
    centerLayer.bounds = CGRectMake(-160, -160, 320, 320);
	centerLayer.masksToBounds = YES;
    centerLayer.backgroundColor = [UIColor whiteColor].CGColor;
	[[self.view layer] addSublayer:centerLayer];
    
    tiledLayer = [TiledLayer layer];
    tiledLayer.provider = provider;
    tiledLayer.geometryFlipped = YES;
    [centerLayer addSublayer:tiledLayer];
    
    UIGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pinch];
    
    [tiledLayer layoutTilesWithFlags:TiledLayerAfterZoom];
}

@end
