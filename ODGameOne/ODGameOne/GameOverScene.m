//
//  GameOverScene.m
//  ODGameOne
//
//  Created by 大畅 on 13-9-29.
//  Copyright (c) 2013年 大畅. All rights reserved.
//

#import "MyScene.h"
#import "GameOverScene.h"

@implementation GameOverScene

- (id)initWithSize:(CGSize)size won:(BOOL)won
{
    if (self = [super initWithSize:size])
    {
        SKSpriteNode *bg;
        if(won)
        {
            bg = [SKSpriteNode spriteNodeWithImageNamed:@"YouWin.png"];
            [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.1], [SKAction playSoundFileNamed:@"win.wav" waitForCompletion:NO]]]];
        }
        else
        {
            bg = [SKSpriteNode spriteNodeWithImageNamed:@"YouLose.png"];
            [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.1], [SKAction playSoundFileNamed:@"lose.wav" waitForCompletion:NO]]]];
        }
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild: bg];
        
        SKAction *wait = [SKAction waitForDuration:3.0];
        SKAction *block = [SKAction runBlock:^{
            MyScene *myScene = [[MyScene alloc] initWithSize:self.size];
            SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
            [self.view presentScene:myScene transition:reveal];
        }];
        [self runAction:[SKAction sequence:@[wait, block]]];
    }
    return self;
}

@end
