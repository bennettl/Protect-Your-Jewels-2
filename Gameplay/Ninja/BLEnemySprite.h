//
//  BLEnemySprite.h
//  GamePlay
//
//  Created by Bennett Lee on 2/20/14.
//  Copyright 2014 Bennett Lee. All rights reserved.
//

#import "GB2Sprite.h"
#import "BLSpriteLayer.h"

@interface BLEnemySprite : GB2Sprite {
    BLSpriteLayer *spriteLayer; // weak reference
}

+(BLEnemySprite *)enemySprite;

- (id)initWithSpriteLayer:(BLSpriteLayer *)sl;
-(BOOL)intersectsWithPoint:(CGPoint)ccLocation;

@end
