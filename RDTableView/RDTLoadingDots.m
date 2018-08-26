//
//  RDTLoadingDots.m
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//
#import "RDTLoadingDots.h"


#define dot_width   6  //圆点直径
#define dots_offset 8  //圆点间隔

#define dots_color [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1.0f]


@interface RDTLoadingDots ()

@property (nonatomic, strong) UIView *dot1;
@property (nonatomic, strong) UIView *dot2;
@property (nonatomic, strong) UIView *dot3;

@property (nonatomic) BOOL dotsFlashing;  //是否正在闪烁

@end


@implementation RDTLoadingDots

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        //初始化状态值
        self.dotsFlashing = NO;  //是否正在闪烁
                
        //添加圆点
        self.dot2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, dot_width, dot_width)];
        _dot2.center = CGPointMake(CGRectGetWidth(frame)/2, CGRectGetHeight(frame)/2);
        _dot2.userInteractionEnabled = NO;
        _dot2.backgroundColor = dots_color;
        _dot2.alpha = 0.0;
        [self addRadiusToView:_dot2 radius:dot_width/2];
        [self addSubview:_dot2];
        
        self.dot1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, dot_width, dot_width)];
        _dot1.center = CGPointMake(CGRectGetMidX(_dot2.frame)-dots_offset-dot_width, CGRectGetMidY(_dot2.frame));
        _dot1.userInteractionEnabled = NO;
        _dot1.backgroundColor = dots_color;
        _dot1.alpha = 0.0;
        [self addRadiusToView:_dot1 radius:dot_width/2];
        [self addSubview:_dot1];
        
        self.dot3 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, dot_width, dot_width)];
        _dot3.center = CGPointMake(CGRectGetMidX(_dot2.frame)+dots_offset+dot_width, CGRectGetMidY(_dot2.frame));
        _dot3.userInteractionEnabled = NO;
        _dot3.backgroundColor = dots_color;
        _dot3.alpha = 0.0;
        [self addRadiusToView:_dot3 radius:dot_width/2];
        [self addSubview:_dot3];
        
    }
    return self;
}

- (void)addRadiusToView:(UIView*)view radius:(float)radius
{
    if(!view) return;
    view.layer.cornerRadius = radius;
    view.layer.masksToBounds = YES;
}





//触发等待和结束
- (void)startFlashing
{
    if(_dotsFlashing) return;
    _dotsFlashing = YES;
    
    //先全部还原
    _dot1.alpha = 0.0;
    _dot2.alpha = 0.0;
    _dot3.alpha = 0.0;
    
    //开始闪烁
    [self runFulling];
    
}
- (void)stopFlashing
{
    _dotsFlashing = NO;
}

- (void)runFulling
{
    [UIView animateWithDuration:0.5 animations:^{
        
        self.dot1.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.5 animations:^{
            
            self.dot2.alpha = 1.0;
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.5 animations:^{
                
                self.dot3.alpha = 1.0;
                
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:0.5 animations:^{
                    
                    self.dot1.alpha = 0.0;
                    self.dot2.alpha = 0.0;
                    self.dot3.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    if(self.dotsFlashing)
                    {
                        [self runFulling];
                    }
                }];
  
            }];
        }];
    }];
}



@end
