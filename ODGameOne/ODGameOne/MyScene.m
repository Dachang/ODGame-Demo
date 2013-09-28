//
//  MyScene.m
//  ODGameOne
//
//  Created by 大畅 on 13-9-25.
//  Copyright (c) 2013年 大畅. All rights reserved.
//

#import "MyScene.h"

#define ARC4RANDOM_MAX 0x100000000

#pragma mark - math utilities

static inline CGPoint CGPointAdd(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointSubstract(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a, const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

static inline CGFloat CGPointLength(const CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}

static inline CGPoint CGPointNormalize(const CGPoint a)
{
    CGFloat length = CGPointLength(a);
    return CGPointMake(a.x / length, a.y / length);
}

static inline CGFloat CGPointToAngle(const CGPoint a)
{
    return atan2f(a.y, a.x);
}

static inline CGFloat ScalarSign(CGFloat a)
{
    return a >= 0 ? 1 : -1;
}

static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max)
{
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

//return shortest angle between two angles, between -M_PI and M_PI
static inline CGFloat ScalarShortestAngleBetween(const CGFloat a, const CGFloat b)
{
    CGFloat difference = b - a;
    CGFloat angle = fmodf(difference, M_PI * 2);
    if(angle > M_PI)
    {
        angle -= M_PI*2;
    }
    return angle;
}

#pragma mark - constant variables

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 120.0;
static const float ZOMBIE_ROTATE_RADIANS_PER_SEC = 2 * M_PI;

@implementation MyScene
{
    SKSpriteNode *_zombie;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    CGPoint _velocity; //here CGPoint is used to represent a 2D vector
    CGPoint _lastTouchedLocation;
    SKAction *_zombieAnimation;
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
        //add to scene
        [self addChild:bg];
        [self addChild:_zombie];
        //create zombie animation
        NSMutableArray *textures = [NSMutableArray arrayWithCapacity:10];
        for (int i = 1; i < 4; i++)
        {
            NSString *textureName = [NSString stringWithFormat:@"zombie%d", i];
            SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
            [textures addObject:texture];
        }
        for (int i = 4; i > 1; i--)
        {
            NSString *textureName = [NSString stringWithFormat:@"zombie%d",i];
            SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
            [textures addObject:texture];
        }
        _zombieAnimation = [SKAction animateWithTextures:textures timePerFrame:0.1];
        [_zombie runAction:[SKAction repeatActionForever:_zombieAnimation]];
        //create enemy
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction performSelector:@selector(spawnEnemy) onTarget:self], [SKAction waitForDuration:2.0]]]]];
         
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
    
    CGPoint offset = CGPointSubstract(_lastTouchedLocation, _zombie.position);
    CGFloat remainLength = CGPointLength(offset);
    if(remainLength < ZOMBIE_MOVE_POINTS_PER_SEC * _dt)
    {
        _zombie.position = _lastTouchedLocation;
        _velocity = CGPointZero;
    }
    else
    {
        [self moveSprite:_zombie velocity:_velocity];
        [self bounceCheckPlayer];
        [self rotateSprite:_zombie toDirection:_velocity rotateRadiansPerSec:ZOMBIE_ROTATE_RADIANS_PER_SEC];
    }
}

- (void)moveSprite:(SKSpriteNode*)sprite velocity:(CGPoint)velocity
{
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, _dt);
    sprite.position = CGPointAdd(sprite.position, amountToMove);
}

- (void)moveZombieToward:(CGPoint)location
{
    _lastTouchedLocation = location;
    CGPoint offset = CGPointSubstract(location, _zombie.position);
    CGPoint direction = CGPointNormalize(offset);
    _velocity = CGPointMultiplyScalar(direction, ZOMBIE_MOVE_POINTS_PER_SEC);
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
- (void)rotateSprite:(SKSpriteNode*)sprite toDirection:(CGPoint)direction rotateRadiansPerSec:(CGFloat)rotateRadiansPerSec
{
    CGFloat currentAngle = sprite.zRotation;
    CGFloat rotateAngle = CGPointToAngle(direction);

    CGFloat shortest =ScalarShortestAngleBetween(currentAngle, rotateAngle);
    CGFloat amountToRotate = ABS(shortest) < ABS(rotateRadiansPerSec * _dt) ? ABS(shortest) : rotateRadiansPerSec * _dt;
    
    sprite.zRotation += ScalarSign(shortest) * amountToRotate;
}

#pragma mark - spawn enemies
- (void)spawnEnemy
{
    SKSpriteNode *enemy = [[SKSpriteNode alloc] initWithImageNamed:@"enemy"];
    enemy.position = CGPointMake(self.size.width + enemy.size.width/2, ScalarRandomRange(enemy.size.height/2, self.size.height - enemy.size.height/2));
    [self addChild:enemy];
    
    SKAction *actionMove = [SKAction moveToX:-enemy.size.width/2 duration:2.0];
    //removeFromParent removes the node that's running the action from its parent
    SKAction *actionRemove = [SKAction removeFromParent];
    [enemy runAction:[SKAction sequence:@[actionMove, actionRemove]]];
}

@end
