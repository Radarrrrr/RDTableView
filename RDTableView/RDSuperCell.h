//
//  RDSuperCell.h
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface RDSuperCell : UITableViewCell 


#pragma mark - 复写下面两个方法
//设定cell的样式，所有的组件都放在 self.contentView 上面，做成全局变量，用以支持 setCellData 里边来修改组件的数值
- (void)setCellStyle;   


//根据data设定cell上组件的属性，并返回计算以后的cell高度, 用number类型装进去
//[重要] cell高度必须要做计算并返回，如果返回nil就使用默认的44高度了
//此方法中的data就是主类appendData方法中的data，参见：[table appendData:data useCell:@"CELL_NAME" toSection:0];
- (NSNumber*)setCellData:(id)data atIndexPath:(NSIndexPath*)indexPath;  



@end
