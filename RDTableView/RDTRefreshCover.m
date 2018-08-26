//
//  RDTRefreshCover.m
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//

#import "RDTRefreshCover.h"



@interface RDTRefreshCover ()

- (void)triggerRefreshAction:(id)sender;
- (void)restWaitingPosition;

@end



@implementation RDTRefreshCover

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = refresh_cover_back_ground_color;
        
        //add _backGroundButton
        self.backGroundButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _backGroundButton.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [_backGroundButton addTarget:self action:@selector(triggerRefreshAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_backGroundButton];
        
        //add _placeHolderLabel
        self.placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _placeHolderLabel.backgroundColor = [UIColor clearColor];
        _placeHolderLabel.textAlignment = NSTextAlignmentCenter;
        _placeHolderLabel.numberOfLines = 20;
        _placeHolderLabel.font = refresh_cover_place_holder_font;
        _placeHolderLabel.textColor = refresh_cover_place_holder_color;
        _placeHolderLabel.text = refresh_cover_place_holder;
        _placeHolderLabel.alpha = 1.0;
        [self addSubview:_placeHolderLabel];
        
        //add _waitingLabel
        self.waitingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (frame.size.height-20)/2+20, frame.size.width, 20)];
        _waitingLabel.backgroundColor = [UIColor clearColor];
        _waitingLabel.textAlignment = NSTextAlignmentLeft;
        _waitingLabel.font = refresh_cover_waiting_font;
        _waitingLabel.textColor = refresh_cover_waiting_color;
        _waitingLabel.text = refresh_cover_waiting_text;
        _waitingLabel.alpha = 0.0;
        [self addSubview:_waitingLabel];
        
        //add _spinner;
        self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((frame.size.width-20)/2, (frame.size.height-20)/2, 20, 20)];
        _spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [_spinner stopAnimating];
        _spinner.alpha = 0.0;
        [self addSubview:_spinner];
        
    }
    return self;
}




#pragma mark -
#pragma mark in use functions
- (void)triggerRefreshAction:(id)sender
{
    //返回给代理
    if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(refreshCoverDidTapTrigger)])
    {
        [self.delegate refreshCoverDidTapTrigger];
    }
}

- (void)restWaitingPosition
{
    //有等待文字的时候才进行改动，并且此改动可以随时
    if(_waitingLabel && _waitingLabel.text && [_waitingLabel.text compare:@""] != NSOrderedSame)
    {
        //计算waiting文字的长度
        //CGSize size = [_waitingLabel.text sizeWithFont:_waitingLabel.font];
    
        NSDictionary *attributes = @{NSFontAttributeName:_waitingLabel.font};
        CGSize size = [_waitingLabel.text sizeWithAttributes:attributes];
        
        float fw = self.frame.size.width;
        float fh = self.frame.size.height;
        
        float ww = size.width;
        float wh = size.height;
        
        float sw = _spinner.frame.size.width;
        float sh = _spinner.frame.size.height;
        float sx = (fw-ww-sw-10)/2;
        float sy = (fh-sh)/2;
        
        //重新放置_spinner的位置
        _spinner.frame = CGRectMake(sx, sy, sw, sh);
        
        //重新放置_waitingLabel的位置
        _waitingLabel.frame = CGRectMake(sx+sw+10, (fh-wh)/2, ww, wh);
    }
}



#pragma mark -
#pragma mark out use functions
- (void)startWaiting
{
    [self restWaitingPosition];
    
    [UIView beginAnimations:@"start_wait" context:nil];
	[UIView setAnimationDuration:0.2];
	
    _spinner.alpha = 1.0;
    _waitingLabel.alpha = 1.0;
    _placeHolderLabel.alpha = 0.0;
    
	[UIView commitAnimations];
    
    
    [_spinner startAnimating];
    
}
- (void)stopWaiting
{
    [_spinner stopAnimating];
    
    [UIView beginAnimations:@"stop_wait" context:nil];
	[UIView setAnimationDuration:0.2];
	
    _spinner.alpha = 0.0;
    _waitingLabel.alpha = 0.0;
    _placeHolderLabel.alpha = 1.0;

	[UIView commitAnimations];
    
}



@end
