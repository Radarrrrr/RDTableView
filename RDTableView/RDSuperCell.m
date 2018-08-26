//
//  RDSuperCell.m
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//


#import "RDSuperCell.h"


@interface RDSuperCell ()
- (void)confirmCellHeight:(NSNumber*)height; //设定cell的行高,供主类使用，不需要复写
@end


@implementation RDSuperCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
        [self setCellStyle];
    }
    return self;
}

- (void)confirmCellHeight:(NSNumber*)height
{
    CGRect newRect = self.contentView.frame;
    newRect.size.height = [height floatValue];
    
    self.contentView.frame = newRect;
    self.frame = newRect;
}


#pragma mark - 复写下面两个方法
- (void)setCellStyle
{
    //设定cell的样式，所有的组件都放在 self.contentView 上面，做成全局变量，用以支持 setCellData 里边来修改组件的数值
    
    //...复写此方法
}

-(NSNumber*)setCellData:(id)data atIndexPath:(NSIndexPath*)indexPath
{
    //根据data设定cell上组件的属性，并返回计算以后的cell高度, 用number类型装进去，[重要]cell高度必须要做计算并返回，如果返回nil就使用默认的44高度了
    
    //...复写此方法
    
    return nil;
}



@end
