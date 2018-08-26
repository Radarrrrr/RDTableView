//
//  RDTRefreshCover.h
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//

#import <UIKit/UIKit.h>


#define refresh_cover_back_ground_color   [UIColor colorWithRed:(float)240/255 green:(float)240/255 blue:(float)240/255 alpha:1.0] //[UIColor whiteColor];

#define refresh_cover_place_holder        @"抱歉，数据载入失败\n请点击屏幕刷新"
#define refresh_cover_place_holder_font   [UIFont systemFontOfSize:12.0]          
#define refresh_cover_place_holder_color  [UIColor grayColor]

#define refresh_cover_waiting_text        @""  //@"载入中,请稍候..."
#define refresh_cover_waiting_font        [UIFont systemFontOfSize:12.0]          
#define refresh_cover_waiting_color       [UIColor grayColor]


@class RDTRefreshCover;
@protocol RDTRefreshCoverDelegate <NSObject> 
@optional
- (void)refreshCoverDidTapTrigger;
@end


@interface RDTRefreshCover : UIView 

@property (weak) id<RDTRefreshCoverDelegate> delegate;

@property (nonatomic, strong) UIButton *backGroundButton;       //作为背景用的按钮，可以在外部修改此属性以改动点击或者此footview的背景风格
@property (nonatomic, strong) UIActivityIndicatorView *spinner; //旋转的部分，可以在外面改大小和属性
@property (nonatomic, strong) UILabel *placeHolderLabel;        //默认文字的label,可以在外面修改属性，如果换文字需要换行，参考 @"抱歉，数据载入失败\n请点击屏幕刷新"

//等待旋转时候的等待文字label，可以在外面修改属性，不可以换行, 可以随时修改，下次调用startWaiting的时候效果就会变化
//PS: 默认没有文字，如果有文字的话，将在等待的时候出现在spinner的后面，
//PS: 可以通过外部调用waitingLabel.text来修改文字
@property (nonatomic, strong) UILabel *waitingLabel;           


- (void)startWaiting;
- (void)stopWaiting;


@end

