//
//  SetCardGameViewController.m
//  Matchismo
//
//  Created by Marko Tadić on 9/7/13.
//  Copyright (c) 2013. tadija. All rights reserved.
//

#import "SetCardGameViewController.h"
#import "SetCardDeck.h"
#import "SettingsViewController.h"
#import "SetCard.h"
#import "SetCardCollectionViewCell.h"

@interface SetCardGameViewController() <UIAlertViewDelegate>
@property (strong, nonatomic) NSMutableArray *selectedCards; // of SetCards
@property (strong, nonatomic) IBOutletCollection(SetCardView) NSArray *selectedCardViews;
@end

@implementation SetCardGameViewController

@synthesize game = _game;
@synthesize selectedCards = _selectedCards;

#define SET_CARD_COUNT 12
#define MATCH_COUNT 3

- (CardMatchingGame *)game
{
    if (!_game) {
        _game = [[CardMatchingGame alloc] initWithCardCount:SET_CARD_COUNT
                                                  usingDeck:[[SetCardDeck alloc] init]
                                              andMatchCount:MATCH_COUNT
                                               withSettings:[[Settings alloc] initGame:@"Set" WithDifficulty:[SettingsViewController getSavedDifficulty]]];
        self.selectedCards = nil; // reset selectedCardViews if new game is started 
    }
    return _game;
}

- (NSMutableArray *)selectedCards
{
    if (!_selectedCards) _selectedCards = [[NSMutableArray alloc] init];
    return _selectedCards;
}

#define ANIMATION_DURATION 0.2
- (void)setSelectedCards:(NSMutableArray *)selectedCards
{
    _selectedCards = selectedCards;
    
    // update selectedCardViews
    for (int i = 0; i < [self.selectedCardViews count]; i++) {
        SetCardView *setCardView = self.selectedCardViews[i];
        [UIView transitionWithView:setCardView
                          duration:ANIMATION_DURATION
                           options:(i + 1 == [self.selectedCards count]) ? UIViewAnimationOptionTransitionFlipFromTop : UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            if ([self.selectedCards count] > i) {                                
                                SetCard *setCard = self.selectedCards[i];
                                setCardView.number = setCard.number;
                                setCardView.symbol = setCard.symbol;
                                setCardView.shading = setCard.shading;
                                setCardView.color = setCard.color;
                                setCardView.faceUp = setCard.isFaceUp;
                                setCardView.unplayable = setCard.isUnplayable;
                                setCardView.penalty = setCard.isPenalty;
                            } else {
                                setCardView.number = 0;
                                setCardView.symbol = 0;
                                setCardView.shading = 0;
                                setCardView.color = 0;
                                setCardView.faceUp = NO;
                                setCardView.unplayable = NO;
                                setCardView.penalty = NO;
                            }
                        }
                        completion:NULL];
    }
    // reset selectedCardViews
    if ([self.selectedCards count] == [self.selectedCardViews count]) {
        [self.selectedCards removeAllObjects];
    }
}

#pragma mark - updating the UI

- (void)viewDidLoad
{
    // sort selectedCardViews by tag
    NSSortDescriptor *ascendingSort = [[NSSortDescriptor alloc] initWithKey:@"tag" ascending:YES];
    self.selectedCardViews = [self.selectedCardViews sortedArrayUsingDescriptors:[NSArray arrayWithObject:ascendingSort]];
}

- (void)updateCell:(UICollectionViewCell *)cell usingCard:(Card *)card animated:(BOOL)animated
{
    if ([cell isKindOfClass:[SetCardCollectionViewCell class]]) {
        SetCardView *setCardView = ((SetCardCollectionViewCell *)cell).setCardView;
        if ([card isKindOfClass:[SetCard class]]) {
            [UIView transitionWithView:setCardView
                              duration:0.2
                               options:(animated) ? UIViewAnimationOptionTransitionCrossDissolve : UIViewAnimationOptionTransitionNone
                            animations:^{
                                SetCard *setCard = (SetCard *)card;
                                setCardView.number = setCard.number;
                                setCardView.symbol = setCard.symbol;
                                setCardView.shading = setCard.shading;
                                setCardView.color = setCard.color;
                                setCardView.faceUp = setCard.isFaceUp;
                                setCardView.unplayable = setCard.isUnplayable;
                                setCardView.penalty = setCard.isPenalty;
                                setCardView.hint = setCard.isHint;
                            }
                            completion:NULL];
        }
    }
}

#define DISABLED_ALPHA 0.3
#define ENABLED_ALPHA 1.0
- (void)updateCustomUI:(NSInteger)flippedCardIndex
{    
    // manage selectedCards (selectedCardViews)
    NSMutableArray *flippedCards = self.selectedCards;
    Card *flippedCard = [self.game cardAtIndex:flippedCardIndex];
    if (flippedCard) {
        if ([flippedCard isKindOfClass:[SetCard class]]) {
            SetCard *flippedSetCard = (SetCard *)flippedCard;
            flippedCard.isFaceUp ? [flippedCards addObject:flippedSetCard] : [flippedCards removeObject:flippedSetCard];
            self.selectedCards = flippedCards;
        }
    }
    
    // remove unplayable cards
    NSIndexSet *unplayableCardIndexes = [self.game findUnplayableCards];
    if ([unplayableCardIndexes count]) {
        
        NSMutableArray *unplayableCardIndexPaths = [[NSMutableArray alloc] init];
        [unplayableCardIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [unplayableCardIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        }];
        
        [self.cardCollectionView performBatchUpdates:^{
            [self.game deleteCardsAtIndexes:unplayableCardIndexes];
            [self.cardCollectionView deleteItemsAtIndexPaths:unplayableCardIndexPaths];
        } completion:nil];
    }
}

#pragma mark - Target/Action/Gestures

- (IBAction)restartGame
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Restart game" message:@"Are you sure?"
                                                   delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // start new game
    if (buttonIndex == 1) {
        self.game = nil;
        self.multiplayerScores = nil;
        self.currentPlayer = 1;        
        [self.cardCollectionView reloadData];
        [self updateUI:-1];        
    }
}

@end
