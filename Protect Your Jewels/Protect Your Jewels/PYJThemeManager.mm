//
//  PYJThemeManager.mm
//  Protect Your Jewels
//
//  Created by Ryan Stack on 3/8/14.
//  Copyright (c) 2014 ITP382RBBM. All rights reserved.
//

#import "PYJThemeManager.h"

@implementation PYJThemeManager

+ (instancetype)sharedManager {
    static PYJThemeManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (id)init {
    // Default theme is MOUNTAIN
    if (self = [super init]) {
        self.theme = MOUNTAIN;
    }
    return self;
}

// Sets the theme (enum)
- (void)setTheme:(Theme)theme{
    _theme = theme;
}

// Return an background layer base on theme
- (PYJBGLayer *)background{
    PYJBGLayer *bg = nil;
    
    switch (_theme) {
        case MOUNTAIN:
            bg = [[[PYJBGLayer alloc] initWithTheme:@"Mountain"] autorelease];
            break;
        case JUNGLE:
            bg = [[[PYJBGLayer alloc] initWithTheme:@"Jungle"] autorelease];
            break;
        case GLADIATOR:
            bg = [[[PYJBGLayer alloc] initWithTheme:@"Temple"] autorelease];
            break;
        default:
            break;
    }
    return bg;
}

// Return an enemy sprite base on theme
- (PYJEnemySprite *)enemySprite{
    
    PYJEnemySprite *es = nil;
    
    switch (_theme) {
        case MOUNTAIN:
            es = [[PYJEnemySprite alloc] initWithTheme:@"Mountain"];
            break;
        case JUNGLE:
            es = [[PYJEnemySprite alloc] initWithTheme:@"Jungle"];
            break;
        case GLADIATOR:
            es = [[PYJEnemySprite alloc] initWithTheme:@"Temple"];
            break;
        default:
            break;
    }
    return es;
}

@end