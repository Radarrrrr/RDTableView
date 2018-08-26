//
//  TestCell.m
//  RDTableViewDemo
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//

#import "TestCell.h"

@interface TestCell ()

@property (nonatomic, strong) UILabel *tLabel;

@end


@implementation TestCell

- (void)setCellStyle
{
    //设定cell的样式，所有的组件都放在 self.contentView 上面，做成全局变量，用以支持 setCellData 里边来修改组件的数值
    
    
    //self.backgroundColor = [UIColor yellowColor];
    //self.contentView.backgroundColor = [UIColor redColor];
    //self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    //self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    //add _tLabel
    self.tLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    _tLabel.backgroundColor = [UIColor clearColor];
    _tLabel.textAlignment = NSTextAlignmentCenter;
    _tLabel.font = [UIFont boldSystemFontOfSize:16.0];
    _tLabel.textColor = [UIColor blueColor];
    [self.contentView addSubview:_tLabel];
    
    //add line
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, 99, 375, 1)];
    line.backgroundColor = [UIColor darkGrayColor];
    [self.contentView addSubview:line];
    
    
}
- (NSNumber*)setCellData:(id)data atIndexPath:(NSIndexPath*)indexPath
{
    //根据data设定cell上组件的属性，并返回计算以后的cell高度, 用number类型装进去，[重要]cell高度必须要做计算并返回，如果返回nil就使用默认的44高度了
    _tLabel.text = (NSString *)data;
    
    return [NSNumber numberWithFloat:100];
}


@end
