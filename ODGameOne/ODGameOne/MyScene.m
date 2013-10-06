//
//  MyScene.m
//  ODGameOne
//
//  Created by 大畅 on 13-9-25.
//  Copyright (c) 2013年 大畅. All rights reserved.
//

@import AVFoundation;
#import "MyScene.h"
#import "GameOverScene.h"

#pragma mark - math utilities

static inline CGFloat ScalarRandomRange(CGFloat min, CGFloat max)
{
    return floorf(((double)arc4random() / ARC4RANDOM_MAX) * (max - min) + min);
}

#pragma mark - constant variables

static const float ZOMBIE_MOVE_POINTS_PER_SEC = 120.0;
static const float CAT_MOVE_POINTS_PER_SEC = 120.0;
static const float BG_MOVE_POINTS_PER_SEC = 50.0;
static const float ZOMBIE_ROTATE_RADIANS_PER_SEC = 2 * M_PI;

@implementation MyScene
{
    SKSpriteNode *_zombie;
    NSTimeInterval _lastUpdateTime;
    NSTimeInterval _dt;
    CGPoint _velocity; //here CGPoint is used to represent a 2D vector
    CGPoint _lastTouchedLocation;
    SKAction *_zombieAnimation;
    SKAction *_catCollisionSound;
    SKAction *_enemyCollisionSound;
    SKAction *_zombieBlinkAction;
    BOOL _isZombieInvincible;
    int _lives;
    BOOL _gameOver;
    AVAudioPlayer *_backgroundMusicPlayer;
    SKNode *_bgLayer; //create an empty node that is treated as the "background layer"
    int _numOfCats;
    SKLabelNode *_scoreLabel;
}

- (id) initWithSize:(CGSize)size
{
    if(self = [super initWithSize:size])
    {
        //set game info
        _lives = 5;
        _numOfCats = 0;
        _gameOver = NO;
        //create bg
        _bgLayer = [SKNode node];
        [self addChild:_bgLayer];
        self.backgroundColor = [SKColor whiteColor];
        for (int i = 0; i < 2; i++)
        {
            SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
            bg.anchorPoint = CGPointZero;
            bg.position = CGPointMake(i * bg.size.width, 0);
            bg.name = @"bg";
            [_bgLayer addChild:bg];
        }
        //create background music
        [self playBackgroundMusic:@"bgMusic.mp3"];
        //create HUD
        [self setupUI];
        //create zombie
        _zombie = [SKSpriteNode spriteNodeWithImageNamed:@"zombie1"];
        _zombie.position = CGPointMake(100.0f, 100.0f);
        _zombie.zPosition = 100;
        _isZombieInvincible = NO;
        [_bgLayer addChild:_zombie];
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
        //create enemy
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction performSelector:@selector(spawnEnemy) onTarget:self], [SKAction waitForDuration:2.0]]]]];
        //create cat
        [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[[SKAction performSelector:@selector(spawnCat) onTarget:self], [SKAction waitForDuration:1.0]]]]];
        _catCollisionSound = [SKAction playSoundFileNamed:@"hitCat.wav" waitForCompletion:NO];
        _enemyCollisionSound = [SKAction playSoundFileNamed:@"hitCatLady.wav" waitForCompletion:NO];
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
    
//    CGPoint offset = CGPointSubstract(_lastTouchedLocation, _zombie.position);
//    CGFloat remainLength = CGPointLength(offset);
//    if(remainLength < ZOMBIE_MOVE_POINTS_PER_SEC * _dt)
//    {
//        _zombie.position = _lastTouchedLocation;
//        _velocity = CGPointZero;
//        [self stopZombieAnimation];
//    }
//    else
//    {
        [self moveSprite:_zombie velocity:_velocity];
        [self bounceCheckPlayer];
        [self rotateSprite:_zombie toDirection:_velocity rotateRadiansPerSec:ZOMBIE_ROTATE_RADIANS_PER_SEC];
//    }
    [self moveTrain];
    [self moveBackground];
    [self updateUI];
    //check lose condition
    if(_lives < 0 && !_gameOver)
    {
        [_backgroundMusicPlayer stop];
        _gameOver = YES;
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size won:NO];
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:gameOverScene transition:reveal];
    }
}

- (void)moveSprite:(SKSpriteNode*)sprite velocity:(CGPoint)velocity
{
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, _dt);
    sprite.position = CGPointAdd(sprite.position, amountToMove);
}

- (void)moveZombieToward:(CGPoint)location
{
    [self startZombieAnimation];
    _lastTouchedLocation = location;
    CGPoint offset = CGPointSubtract(location, _zombie.position);
    CGPoint direction = CGPointNormalize(offset);
    _velocity = CGPointMultiplyScalar(direction, ZOMBIE_MOVE_POINTS_PER_SEC);
}
#pragma mark - touch handler

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:_bgLayer];
    [self moveZombieToward:touchLocation];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:_bgLayer];
    [self moveZombieToward:touchLocation];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInNode:_bgLayer];
    [self moveZombieToward:touchLocation];
}

#pragma mark - bounce check 
- (void)bounceCheckPlayer
{
    CGPoint newPostion = _zombie.position;
    CGPoint newVeloctiy = _velocity;
    //here used the convertPoint:fromNode: methods to convert points from one coordinate system to another
    CGPoint leftBottom= [_bgLayer convertPoint:CGPointZero fromNode:self];
    CGPoint rightTop = [_bgLayer convertPoint:CGPointMake(self.size.width, self.size.height) fromNode:self];
    
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
    enemy.name = @"enemy";
    CGPoint enemyScenePos = CGPointMake(self.size.width + enemy.size.width/2, ScalarRandomRange(enemy.size.height/2, self.size.height - enemy.size.height/2));
    enemy.position = [self convertPoint:enemyScenePos toNode:_bgLayer];
    [_bgLayer addChild:enemy];
    
    SKAction *actionMove = [SKAction moveByX: - self.size.width + enemy.size.width y:0 duration:2.0];
    //removeFromParent removes the node that's running the action from its parent
    SKAction *actionRemove = [SKAction removeFromParent];
    [enemy runAction:[SKAction sequence:@[actionMove, actionRemove]]];
}

#pragma mark - spawn cats

- (void)spawnCat
{
    SKSpriteNode *cat = [SKSpriteNode spriteNodeWithImageNamed:@"cat"];
    cat.name = @"cat";
    CGPoint catScenePos = CGPointMake(ScalarRandomRange(0, self.size
                                                        .width), ScalarRandomRange(0, self.size.height));
    cat.position = [self convertPoint:catScenePos toNode:_bgLayer];
    cat.xScale = 0;
    cat.yScale = 0;
    cat.zRotation = 0;
    [_bgLayer addChild:cat];
    
    SKAction *appear = [SKAction scaleTo:1.0 duration:0.5];
    SKAction *leftWiggle = [SKAction rotateByAngle:M_PI/8 duration:0.5];
    SKAction *rightWiggle = [leftWiggle reversedAction];
    SKAction *fullwiggle = [SKAction sequence:@[leftWiggle, rightWiggle]];
    SKAction *scaleUp = [SKAction scaleBy:1.2 duration:0.25];
    SKAction *scaleDown = [scaleUp reversedAction];
    SKAction *fullScale = [SKAction sequence:@[scaleUp, scaleDown, scaleUp, scaleDown]];
    SKAction *group = [SKAction group:@[fullScale, fullwiggle]];
    SKAction *groupWait = [SKAction repeatAction:group count:10];
    SKAction *disappear = [SKAction scaleTo:0.0 duration:0.5];
    SKAction *remove = [SKAction removeFromParent];
    [cat runAction:[SKAction sequence:@[appear, groupWait, disappear, remove]]];
}

#pragma mark - start & stop animation

- (void)startZombieAnimation
{
    if(![_zombie actionForKey:@"animation"])
    {
        [_zombie runAction:[SKAction repeatActionForever:_zombieAnimation] withKey:@"animation"];
    }
}

- (void)stopZombieAnimation
{
    [_zombie removeActionForKey:@"animation"];
}

#pragma mark - blink animation

- (void)blinkAnimation
{
    float blinkTimes = 10;
    float blinkDuration = 3.0;
    _zombieBlinkAction = [SKAction customActionWithDuration:blinkDuration actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float slice = blinkDuration / blinkTimes;
        float remainder = fmodf(elapsedTime, slice);
        node.hidden = remainder > slice / 2;
    }];
}

#pragma mark - check collisions

- (void)checkCollisions
{
    [_bgLayer enumerateChildNodesWithName:@"cat" usingBlock:^(SKNode *node, BOOL *stop){
        SKSpriteNode *cat = (SKSpriteNode*)node;
        if(CGRectIntersectsRect(cat.frame, _zombie.frame))
        {
            [self runAction:_catCollisionSound];
            _numOfCats++;
            cat.name = @"train";
            [cat removeAllActions];
            [cat setScale:1.0];
            cat.zRotation = 0;
            [cat runAction:[SKAction colorizeWithColor:[SKColor greenColor] colorBlendFactor:1.0 duration:0.2]];
        }
    }];
    
    if (_isZombieInvincible) return;
    
    [_bgLayer enumerateChildNodesWithName:@"enemy" usingBlock:^(SKNode *node, BOOL *stop){
        SKSpriteNode *enemy = (SKSpriteNode*)node;
        //shrink the collider box a little bit
        CGRect smallerFrame = CGRectInset(enemy.frame, 20, 20);
        if(CGRectIntersectsRect(smallerFrame, _zombie.frame))
        {
            [self runAction:_enemyCollisionSound];
            [self loseCat];
            if(_numOfCats >= 1)
            {
                _numOfCats--;
            }
            _lives--;
            _isZombieInvincible = YES;
            [self blinkAnimation];
            SKAction *sequence = [SKAction sequence:@[_zombieBlinkAction, [SKAction runBlock:^{
                _zombie.hidden = NO;
                _isZombieInvincible = NO;
            }]]];
            [_zombie runAction:sequence];
        }
    }];
}

#pragma mark - did evaluate actions

- (void)didEvaluateActions
{
    [self checkCollisions];
}

#pragma mark - generate cat flow

- (void)moveTrain
{
    __block int trainCount = 0;
    __block CGPoint targetPosition = _zombie.position;
    [_bgLayer enumerateChildNodesWithName:@"train" usingBlock:^(SKNode *node, BOOL *stop){
        if(!node.hasActions)
        {
            trainCount++;
            float actionDuration = 0.3;
            CGPoint offset = CGPointSubtract(targetPosition, node.position);
            CGPoint direction = CGPointNormalize(offset);
            CGPoint amountToMovePerSec = CGPointMultiplyScalar(direction, CAT_MOVE_POINTS_PER_SEC);
            CGPoint amountToMove = CGPointMultiplyScalar(amountToMovePerSec, actionDuration);
            SKAction *moveAction = [SKAction moveByX:amountToMove.x y:amountToMove.y duration:actionDuration];
            [node runAction:moveAction];
        }
        targetPosition = node.position;
    }];
    if (trainCount >= 30 && !_gameOver)
    {
        [_backgroundMusicPlayer stop];
        _gameOver = YES;
        SKScene *gameOverScene = [[GameOverScene alloc] initWithSize:self.size  won:YES];
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:gameOverScene transition:reveal];
    }
}

#pragma mark - helper method keep track of how mant cats have been removed from the line

- (void)loseCat
{
    __block int loseCount = 0;
    [_bgLayer enumerateChildNodesWithName:@"train" usingBlock:^(SKNode *node, BOOL *stop){
        CGPoint randomSpot = node.position;
        randomSpot.x += ScalarRandomRange(-100, 100);
        randomSpot.y += ScalarRandomRange(-100, 100);
        
        node.name = @"";
        [node runAction:[SKAction sequence:@[[SKAction group:@[[SKAction rotateByAngle:M_PI * 4 duration:1.0], [SKAction moveTo:randomSpot duration:1.0], [SKAction scaleTo:0 duration:1.0]]],[SKAction removeFromParent]]]];
        
        loseCount++;
        if(loseCount >= 1)
        {
            *stop = YES;
        }
    }];
}

#pragma mark - background Music
- (void)playBackgroundMusic:(NSString *)filename
{
    NSError *error;
    NSURL *backgroundMusicURL = [[NSBundle mainBundle] URLForResource:filename withExtension:nil];
    _backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
    _backgroundMusicPlayer.numberOfLoops = -1;
    [_backgroundMusicPlayer prepareToPlay];
    [_backgroundMusicPlayer play];
}

#pragma mark - background movement

- (void)moveBackground
{
    CGPoint bgVelocity = CGPointMake(-BG_MOVE_POINTS_PER_SEC, 0);
    CGPoint amountToMove = CGPointMultiplyScalar(bgVelocity, _dt);
    _bgLayer.position = CGPointAdd(_bgLayer.position, amountToMove);
    
    [_bgLayer enumerateChildNodesWithName:@"bg" usingBlock:^(SKNode *node, BOOL *stop){
        SKSpriteNode *bg = (SKSpriteNode*)node;
        CGPoint bgScreenPos = [_bgLayer convertPoint:bg.position toNode:self];
        if(bgScreenPos.x <= -bg.size.width)
        {
            bg.position = CGPointMake(bg.position.x + bg.size.width * 2, bg.position.y);
        }
    }];
}

#pragma mark - game UI

- (void)setupUI
{
    _scoreLabel = [[SKLabelNode alloc] initWithFontNamed:@"Gill Sans"];
    _scoreLabel.fontSize = 20.0;
    _scoreLabel.text = @"Score: 0";
    _scoreLabel.name = @"scoreLabel";
    _scoreLabel.verticalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    _scoreLabel.position = CGPointMake(self.size.width - _scoreLabel.frame.size.width + 20, self.size.height - _scoreLabel.frame.size.height - 10);
    [self addChild:_scoreLabel];
}

- (void)updateUI
{
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", _numOfCats];
}

@end
