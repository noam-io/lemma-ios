//
//  GMeterView.m
//  LeMonLate
//
//  Created by Mel He on 7/30/13.
//  Copyright (c) 2013 IDEO. All rights reserved.
//

#import "GMeterView.h"


#define MAX_G           (1.0f)
#define MAX_AGE         (20)


@interface GMeterView ()

@property (nonatomic, strong) UIColor *barColor;
@property (nonatomic, strong) UIColor *capColor;
@property (nonatomic, assign) CGFloat range;
@property (nonatomic, assign) CGFloat maxG;
@property (nonatomic, assign) NSInteger age;

@end


@implementation GMeterView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;
        _age = 0;
        
        /* default params */
        _barColor = COLOUR_GRAYSCALE_A(255, 1.0);
        _capColor = COLOUR_RGB_A(255, 153, 0, 1.0);
        _range = MAX_G;
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame panelColor:(UIColor *)panelColor barColor:(UIColor *)barColor capColor:(UIColor *)capColor range:(CGFloat)range
{
    self = [self initWithFrame:frame];
    if (self) {
        self.backgroundColor = panelColor;
        _barColor = barColor;
        _capColor = capColor;
        _range = fabsf(range);
    }
    return self;
}


- (void)setValue:(CGFloat)newValue
{
    _value = fabsf(newValue);
    
    if (_age > MAX_AGE) {
        _age = 0;
        _maxG = 0.0f;
    }
    
    _maxG = MAX(_maxG, _value);
    
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    [_barColor set];
    UIRectFill(CGRectMake(0, 0, rect.size.width*MIN(1.0f, _value/_range), rect.size.height));
    [_capColor set];
    UIRectFill(CGRectMake(rect.size.width*MIN(1.0f, _maxG/_range), 0, 12/2, rect.size.height));
    _age += 1;
}


@end
