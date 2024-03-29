//
//  PYJTutorialLayer.mm
//  Protect Your Jewels
//
//  Created by Brian Quock on 4/14/14.
//  Copyright (c) 2014 ITP382RBBM. All rights reserved.
//

#import "PYJTutorialLayer.h"
#import "PYJMainMenuLayer.h"
#import "PYJThemeManager.h"
#import "cocos2d.h"
#import "PYJBGLayer.h"
#import "PYJBoxNode.h"
#import "PYJJewelSprite.h"
#import "PYJTouchCircle.h"
#import "PYJBombSprite.h"


@interface PYJTutorialLayer(){
    b2World *world;
    float enemyLaunchForce;             // adjust this to toggle difficulty (higher = more difficult)
    CCLabelTTF *instructions;
    CCSpriteBatchNode *objectLayer;
    GB2Node *boxNode;
    int waveNum;
    int currentTouches;
}

@property NSMutableArray *enemies;
@property NSMutableArray *touchCircles;
@property PYJJewelSprite *j;
@property PYJBombSprite *b;

@end

@implementation PYJTutorialLayer

-(id) init
{
	if( (self=[super init]) )
	{
		CGSize size = [[CCDirector sharedDirector] winSize];
		
        // Create menu logo and background
		PYJBGLayer *background = [PYJThemeManager sharedManager].background;
        
		[self addChild: background z:-1];
        
        // Menu items
		[CCMenuItemFont setFontSize:23];
        [CCMenuItemFont setFontName:FONT_NAME];
		
        CCMenuItem *itemMainMenu = [CCMenuItemFont itemWithString:@"Main Menu" block:^(id sender){
            [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.5 scene:[PYJMainMenuLayer node]]];}];
        
        CCMenuItem *itemNext = [CCMenuItemFont itemWithString:@"Next" block:^(id sender){
            [self nextScreen];}];
        
        CCMenu *mainMenu = [CCMenu menuWithItems:itemMainMenu, nil];
        CCMenu *nextMenu = [CCMenu menuWithItems:itemNext, nil];
        mainMenu.color = ccBLACK;
        nextMenu.color = ccBLACK;
        
        [mainMenu alignItemsVerticallyWithPadding:10];
        [nextMenu alignItemsVerticallyWithPadding:10];
        [mainMenu setPosition:ccp(60, size.height-30)];
        [nextMenu setPosition:ccp(size.width-30, size.height/2)];
        
        // Add main menu to the layer
        [self addChild:mainMenu];
        //[self addChild:previousMenu];
        [self addChild:nextMenu];
        
        // Load sprite atlases
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"Sprites.plist"];
        
        // Load physic shapes into shape cache
        [[GB2ShapeCache sharedShapeCache] addShapesWithFile:@"Shapes.plist"];
        
        // Add object layer
        objectLayer = [CCSpriteBatchNode batchNodeWithFile:@"Sprites.pvr.ccz" capacity:150];
        [self addChild:objectLayer z:10];
        
        // Initializations
        enemyLaunchForce    = 1000.0f;
        self.enemies        = [[NSMutableArray alloc] init];
        self.touchCircles   = [[NSMutableArray alloc] init];
        [self schedule:@selector(resetSprites) interval:0];
    }
    return self;
}

-(void)startTutorial{
    CGSize size = [[CCDirector sharedDirector] winSize];
    [self initJewel];
    
    // Creates bounding box
    boxNode = [[PYJBoxNode alloc] init];
    
    // Touching
    self.touchEnabled = YES;
    currentTouches = 0;
    
    self.screen = jewel;
    
    instructions = [CCLabelTTF labelWithString:@"This is your jewel. \n Don't let enemies grab your jewel." fontName:FONT_NAME fontSize:17];
    instructions.color = ccBLACK;
    [instructions setPosition:ccp(size.width / 2, size.height/3)];
    [self addChild:instructions];
}

-(void) nextScreen{
    if(self.screen == jewel){
        self.screen = swipe;
        // prepare swipe screen
        [self.j removeJewel];
        [self removeChild:self.j.ccNode];
        [self removeEnemies];
        instructions.string = [NSString stringWithFormat:@"Enemies will attack from both sides. \n Swipe the enemy away."];
        [self spawnEnemy];
    }
    else if(self.screen == swipe){
        self.screen = grab;
        [self removeEnemies];
        instructions.string = @"Knock enemies into each other to get combo points. \n Grab and throw an enemy now.";
        [self spawnEnemy];
    }
    else if(self.screen == grab){
        self.screen = bomb;
        [self removeEnemies];
        instructions.string = @"Do not touch the bombs!";
        [self spawnBomb];

    }
    else if(self.screen == bomb){
        self.screen = modes;
        [self.b removeBomb];
        [self removeEnemies];
        instructions.string = @"Play with lives on classic mode or timed in arcade mode. \n Get a temporary shield every 30 points.";
    }
    else if(self.screen == modes){
        self.screen = jewel;
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.5 scene:[PYJMainMenuLayer node]]];
    }
}

// Creates jewel
-(void)initJewel{
    CGSize s = [[CCDirector sharedDirector] winSize];
    self.j = [PYJJewelSprite jewelSprite];
    [self.j setPhysicsPosition:b2Vec2FromCC(s.width/2, s.height/2)];
    [objectLayer addChild:self.j.ccNode z:10];
}

// Creates enemy
- (void)spawnEnemy{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint location;
    if(self.screen == grab){
        location = CGPointMake(winSize.width*1/3,winSize.height*2/3);
        PYJEnemySprite *target = [[PYJThemeManager sharedManager] enemySprite];
        target.body->SetGravityScale(0);
        [self.enemies addObject:target];
        [target setPhysicsPosition:b2Vec2FromCC(location.x, location.y)];
        [self addChild:target.ccNode z:10];
        location = CGPointMake(winSize.width*5/6,winSize.height*5/6);
    }
    else{
        location = CGPointMake(winSize.width*2/3,winSize.height*2/3);
    }
    
    PYJEnemySprite *enemy = [[PYJThemeManager sharedManager] enemySprite];
    [self.enemies addObject:enemy];

    enemy.body->SetGravityScale(0); // Toggle gravity
    [enemy setPhysicsPosition:b2Vec2FromCC(location.x, location.y)];
    [self addChild:enemy.ccNode z:10];
}

// Creates bomb
-(void)spawnBomb{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint location = CGPointMake(winSize.width/2,winSize.height/2);
    
    self.b = [[PYJBombSprite alloc] initWithStaticBody:@"bomb" spriteFrameName:@"bomb.png"];
    
    [self.b setPhysicsPosition:b2Vec2FromCC(location.x, location.y)];
    [self addChild:self.b.ccNode z:10];
}


#pragma mark Multi-Touch

// Called at start of touch
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    // Don't process touch if current touches reaches max
    if (currentTouches > MAX_TOUCHES){
        return;
    }
    
    // Process each touch once
    for (UITouch *touch in touches) {
        // If touch is not connected to any enemy, create a touch circle
        if (![self createEnemyJointsWithTouch:touch] && self.screen != grab){
            [self initTouchCircleWithTouch:touch];
        }
        // Don't create any more mouse joints/touch cirlces if current touches reaches maximum
        if (currentTouches > MAX_TOUCHES){
            return;
        }
    }
}

// Called when a touch moves
- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    // Process each touch once
    for (UITouch *touch in touches) {
        // If no enemies joints are updated, update touch circle joints
        if (![self updateEnemyJointsWithTouch:touch]){
            [self updateTouchCircleJointsWithTouch:touch];
        }
    }
}

// Called when a touch no longer exists
- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    // Process each touch once
    for (UITouch *touch in touches){
        // If no enemy joints were removed, then remove touch circle joints
        if (![self removeEnemyJointsWithTouch:touch]){
            [self removeTouchCircleWithTouch:touch];
        }
    }
}

- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    // Process each touch once
    for (UITouch *touch in touches){
        // If no enemy joints were removed, then remove touch circle joints
        if (![self removeEnemyJointsWithTouch:touch]){
            [self removeTouchCircleWithTouch:touch];
        }
    }
}

#pragma mark Enemy Joints

// Called to create a mouse joint (grabbing an enemy). Returns YES if touch is created with enemy
- (BOOL)createEnemyJointsWithTouch:(UITouch *)touch{
    if(self.screen == swipe){
        return NO;
    }
    CGPoint ccLocation  = [[CCDirector sharedDirector] convertTouchToGL:touch];
    b2Vec2 b2Location   = b2Vec2FromCC(ccLocation.x, ccLocation.y);
    
    // Loop through all enemies
    for (PYJEnemySprite *es in self.enemies) {
        // If enemy intersects with point, create mouse joint and store reference to touch in enemy
        if ([es intersectsWithPoint:ccLocation]){
            [es createMouseJointWithGroundBody:boxNode.body target:b2Location maxForce:1000];
            [es canCollideWithJewel:NO];
            [es updateTouch:touch];
            currentTouches++; // keep track of current touches
            return YES; // one touch = intersect with one enemy, no point in looping through the rest
        }
    }
    return NO; // no enemies intersected with touch
}

// Loop through every enemy. Return 'YES' if an enemy is connected with touch and mousejoint update is sucessful
- (BOOL)updateEnemyJointsWithTouch:(UITouch *)touch{
    // Convert touch -> ccLocation -> b2Location
    CGPoint ccLocation  = [[CCDirector sharedDirector] convertTouchToGL:touch];
    b2Vec2 b2Location   = b2Vec2FromCC(ccLocation.x, ccLocation.y);
    
    // Loop through all enemies
    for (PYJEnemySprite *es in self.enemies) {
        // If enemy is connected with this touch, update its touch and mousejoint
        if ([es hasTouch:touch] && es.mouseJoint){
            es.mouseJoint->SetTarget(b2Location);
            return YES; // one touch = one enemy, return YES
        }
    }
    return NO; // no enemies connected with touch
}

// Loop through every enemy. Return 'YES' if an enemy is connected with touch and mousejoint removal is sucessful
- (BOOL)removeEnemyJointsWithTouch:(UITouch *)touch{
    // Loop through all enemies and see if there's any touches to be removed
    for (PYJEnemySprite *es in self.enemies){
        // If enemy is connected with a touch, remove its touch and mouse joint
        if([es hasTouch:touch]){
            [es updateTouch:nil];
            [GB2Engine sharedInstance].world->DestroyJoint(es.mouseJoint);
            es.mouseJoint = NULL;
            currentTouches--; // keep track of current touches
            return YES;  // one touch = one enemy, return YES
        }
    }
    return NO; // no enemies connected with touch
}

#pragma mark Touch Circle Joints

// Create touch circle
-(void)initTouchCircleWithTouch:(UITouch *)touch{
    PYJTouchCircle *touchCircle = [[PYJTouchCircle alloc] initWithTouch:touch andGroundBody:boxNode.body];
    [self.touchCircles addObject:touchCircle];
    currentTouches++; // keep track of current touches
}

// Called when a touch circle is moved
- (void)updateTouchCircleJointsWithTouch:(UITouch *)touch{
    // Loop through every touch circle
    for (PYJTouchCircle *tc in self.touchCircles) {
        // If touch circle belongs to this touch, then move it
        if ([tc connectedToTouch:touch]){
            CGPoint ccLocation  = [[CCDirector sharedDirector] convertTouchToGL:touch];
            b2Vec2 b2Location   = b2Vec2FromCC(ccLocation.x, ccLocation.y);
            tc.mouseJoint->SetTarget(b2Location);
        }
    }
}

// Called to remove a touch circle and delete the corresponding joint
- (void)removeTouchCircleWithTouch:(UITouch *)touch{
    // Loop through every touch circle
    for (int i = 0; i < self.touchCircles.count; i++){
        PYJTouchCircle *touchCircle = [self.touchCircles objectAtIndex:i];
        // If touch circle belongs to this touch, then remove it
        if ([touchCircle connectedToTouch:touch]){
            [GB2Engine sharedInstance].world->DestroyJoint(touchCircle.mouseJoint);
            touchCircle.deleteLater = true;
            [self.touchCircles removeObject:touchCircle];
            currentTouches--;
        }
    }
}

// Remove all enemies
-(void)removeEnemies{
    @synchronized(self){
        for(PYJEnemySprite *e in self.enemies){
            e.deleteLater = true;
            if (e.mouseJoint){
                currentTouches--; // keep track of current touches
            }
        }
        for(int i = 0; i < self.enemies.count; i++){
            [self removeChild:[self.enemies objectAtIndex:0] cleanup:YES];
        }
        for(PYJTouchCircle *touchCircle in self.touchCircles){
            [GB2Engine sharedInstance].world->DestroyJoint(touchCircle.mouseJoint);
            touchCircle.deleteLater = true;
        }
        [self.enemies removeAllObjects];
        [self.touchCircles removeAllObjects];
    }
}

// Remove PYJEnemySprite from enemies mutable array
- (void)removeEnemyFromSpriteLayer:(PYJEnemySprite *)es{
   
}

-(void)resetSprites{
    [self unscheduleAllSelectors];
    for (b2Body* b = [GB2Engine sharedInstance].world->GetBodyList(); b; b = b->GetNext()) {
        if (b->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *) b->GetUserData();
            [self removeChild:sprite cleanup:YES];
        }
        [GB2Engine sharedInstance].world->DestroyBody(b);
    }
    for (int i = 0; i < [self.enemies count]; i++){
        [self removeChild:[self.enemies objectAtIndex:0] cleanup:YES];
    }
    for (int i = 0; i < [self.touchCircles count]; i++){
        [self removeChild:[self.touchCircles objectAtIndex:0] cleanup:YES];
    }
    [self.enemies removeAllObjects];
    [self.touchCircles removeAllObjects];
    [self startTutorial];
}

- (void) dealloc
{
    [self.enemies dealloc];
    [self.touchCircles dealloc];
    [super dealloc];
}

@end