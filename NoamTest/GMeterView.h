//
//  GMeterView.h
//  LeMonLate
//
//  Created by Mel He on 7/30/13.
//  Copyright (c) 2013 IDEO. All rights reserved.
//

#import <UIKit/UIKit.h>


#pragma mark - colours


#define COLOUR_RGB_A(r255, g255, b255, a)  \
[UIColor colorWithRed:((r255)/255.0) green:((g255)/255.0) blue:((b255)/255.0) alpha:(a)]


#define COLOUR_GRAYSCALE_A(g255, a)  \
COLOUR_RGB_A((g255), (g255), (g255), a)


@interface GMeterView : UIView


@property (nonatomic, assign) CGFloat value;


- (id)initWithFrame:(CGRect)frame panelColor:(UIColor *)panelColor barColor:(UIColor *)barColor capColor:(UIColor *)capColor range:(CGFloat)range;


@end
