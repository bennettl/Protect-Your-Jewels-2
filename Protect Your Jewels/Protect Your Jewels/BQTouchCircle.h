//
//  BQTouchSprite.h
//  GamePlay
//
//  Created by Brian Quock on 2/22/14.
//  Copyright (c) 2014 Bennett Lee. All rights reserved.
//

#import "GB2Sprite.h"

@class BLSpriteLayer;

@interface BQTouchCircle : GB2Sprite {
    BLSpriteLayer *spriteLayer;
}

- (id)initWithTouch:(UITouch *)touch andGroundBody:(b2Body *)body;

- (BOOL)intersectsWithPoint:(CGPoint)ccLocation;

// Does BQTouchCircle belong to touch object. Use for multi-touch tracking
- (BOOL)belongsToTouch:(UITouch *)touch;

// Reference to the touch that create the object
@property NSUInteger touchHash;

@end
