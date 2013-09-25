//
//  MyScene.m
//  ODGameOne
//
//  Created by 大畅 on 13-9-25.
//  Copyright (c) 2013年 大畅. All rights reserved.
//

#import "MyScene.h"

@implementation MyScene
{
    SKSpriteNode *_zombie;
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
        
        [self addChild:bg];
        [self addChild:_zombie];
    }
    return self;
}

@end
