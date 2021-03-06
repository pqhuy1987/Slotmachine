//
//  GameModel.m
//  Slot Machine
//
//  Created by Student on 5/6/14.
//  Copyright (c) 2014 Carl Milazzo and Bob Schrupp. All rights reserved.
//

#import "GameModel.h"

static int const kMaxPulls = 5;
static int const kMinBet = 1;
static int const kMaxBet = 10;
static int const kBetIncrement = 1;
static int const kStartAmount = 9;

@implementation GameModel{
    //private ivars
    int _pullsLeft;
    
    Reel *_leftReel;
    Reel *_middleReel;
    Reel *_rightReel;
    
    Lever *_lever;
}

// public
-(id)init:(CGSize)size :(CGPoint)pos
{
    self = [super init];
    
    _pullsLeft = kMaxPulls;
    _bet = kMinBet;
    
    // Reels //
    // setup reels
    [Reel initStatic];
    _leftReel = [[Reel alloc] init:0];
    _middleReel = [[Reel alloc] init:1];
    _rightReel = [[Reel alloc] init:2];
    
    // positions
    CGPoint left = CGPointMake(pos.x - size.width/3, pos.y-230);
    CGPoint middle = CGPointMake(pos.x, pos.y-230);
    CGPoint right = CGPointMake(pos.x + size.width/3, pos.y-230);
    
    // place reels
    _leftReel.zPosition = -1;
    _leftReel.position = left;
    [self addChild:_leftReel];
    
    _middleReel.zPosition = -1;
    _middleReel.position = middle;
    [self addChild:_middleReel];
    
    _rightReel.zPosition = -1;
    _rightReel.position = right;
    [self addChild:_rightReel];
    
    // Lever //
    // setup lever
    _lever = [[Lever alloc] init];
    
    // position and place lever
    CGPoint leverPos = CGPointMake(pos.x*2, pos.y-150);
    _lever.position = leverPos;
    
    // add lever
    [self addChild:_lever];
    
    _amount = kStartAmount;
    
    return self;
}

-(void)updateGameStage:(CGFloat)dt{
    // Game logic //
    // update Lever visuals accordingly
    [_lever update];
    
    // Player stage
    if (_gameStage == kGameStagePlayer) {
        return;
    } // end player stage
    
    // Spin stage
    if (_gameStage == kGameStageSpin) {
        //NSLog(@"GameModel - GameStageSpin Active: SPINNING!");
        
        // if reels have actions, continue // SKNode
        [_leftReel update:dt];
        [_middleReel update:dt];
        [_rightReel update:dt];
        
        // if not spinning move on to results stage
        if(!_rightReel.spinning)
        {
            // reset lever
            _lever.isRising = YES;
            
            // move to next stage
            _gameStage = kGameStageResult;
        }
        return;
    } // end spin stage
    
    // Result stage
    if (_gameStage == kGameStageResult) {
        // check for winnings
        if([self didWin])
        {
            // calc results
            _winnings = [self didWin];
            _amount += _winnings;
            _shouldFlash = YES;
        }
        _pullsLeft--;
        //NSLog(@"Pulls Left: %d",_pullsLeft);
        
        // check if game ended
        if(_pullsLeft == 0 || _amount <= 0)
        {
            //[self addChild:_spark1];
            [self notifyGameDidEnd];
        } else {
            // adjust amount left for bet
            _amount -= _bet;
            
            // check amount
            while (_amount <= 0) {
                _bet -= kBetIncrement;
                _amount += kBetIncrement;
            }
            
            // after adjustment, if the player can't bet anymore, end game
            if (_bet <= 0) {
                [self notifyGameDidEnd];
            } else {
                _gameStage = kGameStagePlayer;
            }
        }
        
        
    }
} // end updateGameStage

-(void)reset{
    _gameStage = kGameStagePlayer;
    _pullsLeft = kMaxPulls;
    _amount = kStartAmount;
}

-(void)spinReels
{
    [_leftReel spin];
    [_middleReel spin];
    [_rightReel spin];
}

-(void)checkTouch:(CGPoint)location :(BOOL)touchedEnded{
    // if the touch has ended, check if final touch is within lever 'area'
    if (touchedEnded) {
        if (location.x >= _lever.position.x && location.x <= _lever.position.x + _lever.leverWidth) {
            // if lever was pulled far, set lever to down position and end stage
            if ([_lever isPulledFar]) {
                // set lever down
                _lever.isRising = YES;
                _lever.leverTouched = NO;
                
                // spin reels
                [self spinReels];
                
                // end stage
                _gameStage = kGameStageSpin;
                
                return;
            }
        }
        // lever is reset if let go outside lever or wasn't pulled far
        _lever.isRising = YES;
    } else {
        // Check if touch location is on lever
        if ([_lever containsPoint:location] ) {//|| _lever.leverTouched) {
            // if so, set _leverTouched to YES
            if (_lever.leverTouched == NO) _lever.leverTouched = YES;
            
            // set lever distance accordingly
            _lever.distance = (_lever.position.y + _lever.leverHeight) - location.y;
            
            _lever.isRising = NO;
            return;
        }
    }
    
    _lever.leverTouched = NO;
}

-(void)increaseBet{
    // increase bet amount
    _bet += kBetIncrement;
    // check if increase will move past max amount
    if (_bet > kMaxBet) {
        _bet = kMaxBet;
    } else {
        // adjust amount
        _amount -= kBetIncrement;
    }
    
    // if bet causes amount to go negative, reverse everything
    if (_amount < 0) {
        _bet -= kBetIncrement;
        _amount += kBetIncrement;
    }
}

-(void)decreaseBet{
    // increase bet amount
    _bet -= kBetIncrement;
    // check if decrease will move past max amount
    if (_bet < kMinBet) {
        _bet = kMinBet;
    } else {
        // adjust amount
        _amount += kBetIncrement;
    }
}

// private
-(CGFloat)didWin
{
    CGFloat winnings = 0;
    
    for(int i = 1; i < 4; i++)
    {
        //NSLog(@"Line %d,|%@|%@|%@|",i,_leftReel.nodeNumbers[i],_middleReel.nodeNumbers[i],_rightReel.nodeNumbers[i]);
    }
    //check middle line
    winnings += [self winningLine:_leftReel.nodeNumbers[2] node2:_middleReel.nodeNumbers[2] node3:_rightReel.nodeNumbers[2]];
    //check upper line
    winnings += [self winningLine:_leftReel.nodeNumbers[1] node2:_middleReel.nodeNumbers[1] node3:_rightReel.nodeNumbers[1]];
    //check lower line
    winnings += [self winningLine:_leftReel.nodeNumbers[3] node2:_middleReel.nodeNumbers[3] node3:_rightReel.nodeNumbers[3]];
    //check descending diagonal line
    winnings += [self winningLine:_leftReel.nodeNumbers[1] node2:_middleReel.nodeNumbers[2] node3:_rightReel.nodeNumbers[3]];
    //check accending diagonal line
    winnings += [self winningLine:_leftReel.nodeNumbers[3] node2:_middleReel.nodeNumbers[2] node3:_rightReel.nodeNumbers[1]];
    //NSLog(@"total winnings: %f",winnings);
    return winnings * _bet;
}

-(CGFloat)winningLine:(NSNumber *)nodeOne node2: (NSNumber *)nodeTwo node3: (NSNumber *)nodeThree
{
    
    //NSLog(@"Checking, |%d|%d|%d|",nodeOne.intValue,nodeTwo.intValue,nodeThree.intValue);
    int winnings = 0;
    if(nodeOne.intValue == nodeTwo.intValue && nodeTwo.intValue == nodeThree.intValue)
    {
        switch (nodeOne.intValue) {
            case 1: //7
                return 100;
                break;
            case 2: //bell
                return 60;
                break;
            case 3: //bar
                return 30;
                break;
            case 4: //watermellon
                return 20;
                break;
            case 5: //cherry
                return 10;
                break;
            default:
                break;
        }
    }
    return winnings;
}

-(void) notifyGameDidEnd{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // wrap a Boolean into an NSNumber object using literals syntax
    //NSNumber *didDealerWin = @(_didDealerWin);
    NSNumber *winnings = [NSNumber numberWithInt:_amount]; // dictionary can only store objects ... so we turned the int into an object
    
    // create a dictionary using literals syntax
    NSDictionary *dict = @{@"winnings":winnings};
    
    // "publish" nofitication
    [notificationCenter postNotificationName:kNotificationGameDidEnd object:self userInfo:dict];
}

@end
