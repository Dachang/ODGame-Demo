//
//  MyScene.m
//  ODGameOne
//
//  Created by 大畅 on 13-9-25.
//  Copyright (c) 2013年 大畅. All rights reserved.
//

#import "MyScene.h"

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 120.0;

@implementation MyScene
{
    SKSpriteNode *_zombie;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    CGPoint _velocity; //here CGPoint is used to represent a 2D vector
}

- (id) initWithSize:(CGSize)size
{
    if(self = [super initWithSize:size])
    {
        self.backgroundColor = [SKColor whiteColor];
        //create bg
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        //create zombie
        _zombie = [SKSpriteNode spriteNodeWithImageNamed:@"zombie1"];
        _zombie.position = CGPointMake(100.0f, 100.0f);
//        [_zombie setScale:2.0];
        
        [self addChild:bg];
        [self addChild:_zombie];
    }
    return self;
}

- (void)update:(NSTimeInterval)currentTime
{
    if(_lastUpdateTime)
    {
        _dt = currentTime - _lastUpdateTime;
    }
    else
    {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;
    [self moveSprite:_zombie velocity:_velocity];
    [self bounceCheckPlayer];
    [self rotateSprite:_zombie toDirection:_velocity];
}

- (void)moveSprite:(SKSpriteNode*)sprite velocity:(CGPoint)velocity
{
    CGPoint amountToMove = CGPointMake(velocity.x * _dt, velocity.y * _dt);
    sprite.position = CGPointMake(sprite.position.x + amountToMove.x, sprite.position.y + amountToMove.y);
}

- (void)moveZombieToward:(CGPoint)location
{
    CGPoint offset = CGPointMake(location.x - _zombie.position.x, location.y - _zombie.position.y);
    CGFloat length = sqrtf(offset.x * offset.x + offset.y * offset.y);
    CGPoint direction = CGPointMake(offset.x/length, offset.y/length);
    _velocity = CGPointMake(direction.x * ZOMBIE_MOVE_POINTS_PER_SEC, direction.y * ZOMBIE_MOVE_POINTS_PER_SEC);
}

#pragma mark - touch handler

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.scene];
    [self moveZombieToward:touchLocation];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.scene];
    [self moveZombieToward:touchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:self.scene];
    [self moveZombieToward:touchLocation];
}

#pragma mark - bounce check 
- (void)bounceCheckPlayer
{
    CGPoint newPostion = _zombie.position;
    CGPoint newVeloctiy = _velocity;
    
    CGPoint leftBottom= CGPointZero;
    CGPoint rightTop = CGPointMake(self.size.width, self.size.height);
    
    if(newPostion.x <= leftBottom.x)
    {
        newPostion.x = leftBottom.x;
        newVeloctiy.x = -newVeloctiy.x;
    }
    if(newPostion.x >= rightTop.x)
    {
        newPostion.x = rightTop.x;
        newVeloctiy.x = -newVeloctiy.x;
    }
    if(newPostion.y <= leftBottom.y)
    {
        newPostion.y = leftBottom.y;
        newVeloctiy.y = - newVeloctiy.y;
    }
    if(newPostion.y >= rightTop.y)
    {
        newPostion.y = rightTop.y;
        newVeloctiy.y = -newVeloctiy.y;
    }
    
    _zombie.position = newPostion;
    _velocity = newVeloctiy;
}

#pragma mark - rotate sprite
- (void)rotateSprite:(SKSpriteNode*)sprite toDirection:(CGPoint)direction
{
    CGFloat rotateAngle = atan2f(direction.y, direction.x);
    sprite.zRotation = rotateAngle;
}

@end
