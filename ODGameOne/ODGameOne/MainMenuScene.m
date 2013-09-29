//
//  StartScene.m
//  ODGameOne
//
//  Created by 大畅 on 13-9-29.
//  Copyright (c) 2013年 大畅. All rights reserved.
//

#import "MyScene.h"
#import "MainMenuScene.h"

@implementation MainMenuScene

-(id)initWithSize:(CGSize)size
{
    if(self = [super initWithSize:size])
    {
        SKSpriteNode *bg = [SKSpriteNode spriteNodeWithImageNamed:@"MainMenu.png"];
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:bg];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    MyScene *myScene = [[MyScene alloc] initWithSize:self.size];
    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:2.0];
    [self.view presentScene:myScene transition:reveal];
}

@end
