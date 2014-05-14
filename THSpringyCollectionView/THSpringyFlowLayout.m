//
//  THSpringyFlowLayout.m
//  CollectionViewTest
//
//  Created by Tristan Himmelman on 2013-09-22.
//  Copyright (c) 2013 Tristan Himmelman. All rights reserved.
//

#import "THSpringyFlowLayout.h"

@implementation THSpringyFlowLayout {
    UIDynamicAnimator *_animator;
    NSMutableSet *_visibleIndexPaths;    
    CGPoint _lastContentOffset;
    CGFloat _lastScrollDelta;
    CGPoint _lastTouchLocation;
}

#define kScrollPaddingRect              100.0f
#define kScrollRefreshThreshold         50.0f
#define kScrollResistanceCoefficient    1 / 600.0f

-(void)setup{
    _animator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
    _visibleIndexPaths = [NSMutableSet set];
}

- (id)init {
    self = [super init];
    if (self){
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self){
        [self setup];
    }
    return self;
}

- (void)prepareLayout {
    [super prepareLayout];

    CGPoint contentOffset = self.collectionView.contentOffset;

    // only refresh the set of UIAttachmentBehaviours if we've moved more than the scroll threshold since last load
    if (fabsf(contentOffset.y - _lastContentOffset.y) < kScrollRefreshThreshold && _visibleIndexPaths.count > 0){
        return;
    }
    _lastContentOffset = contentOffset;

    CGFloat padding = kScrollPaddingRect;
    CGRect currentRect = CGRectMake(0, contentOffset.y - padding, self.collectionView.frame.size.width, self.collectionView.frame.size.height + 3 * padding);
    
    NSArray *itemsInCurrentRect = [super layoutAttributesForElementsInRect:currentRect];
    NSSet *indexPathsInVisibleRect = [NSSet setWithArray:[itemsInCurrentRect valueForKey:@"indexPath"]];

    // Remove behaviours that are no longer visible
    [_animator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *behaviour, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = [[behaviour.items firstObject] indexPath];
        
        BOOL isInVisibleIndexPaths = [indexPathsInVisibleRect member:indexPath] != nil;
        if (!isInVisibleIndexPaths){
            [_animator removeBehavior:behaviour];
            [_visibleIndexPaths removeObject:[[behaviour.items firstObject] indexPath]];
        }
    }];

    // Find newly visible indexes
    NSArray *newVisibleItems = [itemsInCurrentRect filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *item, NSDictionary *bindings) {

        BOOL isInVisibleIndexPaths = [_visibleIndexPaths member:item.indexPath] != nil;
        return !isInVisibleIndexPaths;
    }]];

    [newVisibleItems enumerateObjectsUsingBlock:^(UICollectionViewLayoutAttributes *attribute, NSUInteger idx, BOOL *stop) {
        UIAttachmentBehavior *spring = [[UIAttachmentBehavior alloc] initWithItem:attribute attachedToAnchor:attribute.center];
        spring.length = 0;
        spring.frequency = 1.5;
        spring.damping = 0.6;

        // If our touchLocation is not (0,0), we need to adjust our item's center
        if (_lastScrollDelta != 0) {
            [self adjustSpring:spring centerForTouchPosition:_lastTouchLocation scrollDelta:_lastScrollDelta];
        }
        [_animator addBehavior:spring];
        [_visibleIndexPaths addObject:attribute.indexPath];
    }];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    CGFloat padding = kScrollPaddingRect;
    rect.size.height += 3*padding;
    rect.origin.y -= padding;
    return [_animator itemsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    id layoutAttributes = [_animator layoutAttributesForCellAtIndexPath:indexPath];
    if (!layoutAttributes)
        layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    return layoutAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    UIScrollView *scrollView = self.collectionView;
    _lastScrollDelta = newBounds.origin.y - scrollView.bounds.origin.y;
    
    _lastTouchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
    
    [_animator.behaviors enumerateObjectsUsingBlock:^(UIAttachmentBehavior *spring, NSUInteger idx, BOOL *stop) {
        [self adjustSpring:spring centerForTouchPosition:_lastTouchLocation scrollDelta:_lastScrollDelta];
        [_animator updateItemUsingCurrentState:[spring.items firstObject]];
    }];
    
    return NO;
}

- (void)adjustSpring:(UIAttachmentBehavior *)spring centerForTouchPosition:(CGPoint)touchLocation scrollDelta:(CGFloat)scrollDelta {
    CGFloat distanceFromTouch = fabsf(touchLocation.y - spring.anchorPoint.y);
    CGFloat scrollResistance = distanceFromTouch * kScrollResistanceCoefficient;
    
    UICollectionViewLayoutAttributes *item = [spring.items firstObject];
    CGPoint center = item.center;
    if (_lastScrollDelta < 0) {
        center.y += MAX(_lastScrollDelta, _lastScrollDelta * scrollResistance);
    } else {
        center.y += MIN(_lastScrollDelta, _lastScrollDelta * scrollResistance);
    }
    item.center = center;
}

- (void)resetLayout{
    [_animator removeAllBehaviors];
    [_visibleIndexPaths removeAllObjects];
}

@end
