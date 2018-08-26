//
//  ViewController.m
//  RDTableViewDemo
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    float scr_width  = [UIScreen mainScreen].bounds.size.width;
    float scr_height = [UIScreen mainScreen].bounds.size.height;
    
    
    //添加左右上角按钮
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction:)];
    self.navigationItem.rightBarButtonItem = addItem;
    
    UIBarButtonItem *editItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(editAction:)];
    self.navigationItem.leftBarButtonItem = editItem;
 
    
    // 添加本类到页面上
    //[必须] 创建一个RDTableView
    RDTableView *table = [[RDTableView alloc] initWithFrame:CGRectMake(0, 0, scr_width, scr_height-64)];
    table.delegate = self;
    table.tag = 1000;
    table.loadMoreStyle = LoadMoreStyleLoading;
    table.refreshStyle = RefreshStyleDropdown;
    table.multiSelectEnabled = NO;
    table.editRowEnabled = YES;
    table.moveRowEnabled = YES;

    //[可选] 设定tableview的某些风格 (tableViewCell的风格设定放到cell类内部自己去设定，不在这里做)
    //table.tableView.backgroundColor = [UIColor whiteColor];             
    //table.tableView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    table.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //table.tableView.separatorColor = [UIColor redColor];
    
    //[可选] 设定RDTableView内部控件的某些效果 (这里只起到了抛砖引玉的作用，其实每个内部控件都可以引出来，对里边的属性进行更改，可自由发挥)
    //table.refreshControll.tintColor = [UIColor blueColor];
    //table.refreshControll.backgroundColor = [UIColor greenColor];
    //table.refreshCover.backgroundColor = [UIColor yellowColor];
    //table.refreshCover.waitingLabel.text = @"载入中,请稍候..."; //这个如果不存在，就是点击屏幕刷新的时候只有一个滚球的效果
    
    
    //[必须] 前面设定完毕了，可以添加到需要的页面上了
    [self.view addSubview:table];
    
    
    //[可选] 设定header和footer的高度
    //[table setSection:0 headerHeight:50 footerHeight:300]; //除非想做空白区域出来，否则尽量不要使用此方法
    
    //[可选] 设定header和footer的view
//    UIView *hview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scr_width, 20)];
//    hview.backgroundColor = [UIColor redColor];
//    UIView *fview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scr_width, 30)];
//    fview.backgroundColor = [UIColor greenColor];
//    
//    [table setSection:0 headerView:hview footerView:fview];
    
    
    //[可选] 覆盖设定加载更多view，如果不设定，则使用默认效果
//    UIView *moreView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
//    moreView.backgroundColor = [UIColor blueColor];
//    table.moreLoadingView = moreView;
    
    
    // 组合数据源，当然此数据源可能来源于各种不同的方式，注意：data对应的元素必须与要显示的Cell需求的data相同类型
    //[必须] 使用新方法进行页面显示
    [table appendData:@"这时第1段" useCell:@"TestCell" toSection:0];
    [table appendData:@"这时第2段" useCell:@"TestCell" toSection:0];
    [table appendData:@"这时第3段" useCell:@"TestCell" toSection:0];
    [table appendData:@"这时第4段" useCell:@"TestCell" toSection:0];
    [table appendData:@"这时第5段" useCell:@"TestCell" toSection:0];
    [table appendData:@"这时第6段" useCell:@"TestCell" toSection:0];
    [table appendData:@"这时第7段" useCell:@"TestCell" toSection:0];
    [table appendData:@"这时第8段" useCell:@"TestCell" toSection:0];
//    [table appendData:@"这时第9段" useCell:@"TestCell" toSection:0];
//    [table appendData:@"这时第10段" useCell:@"TestCell" toSection:0];
//    [table appendData:@"这时第11段" useCell:@"TestCell" toSection:0];
//    [table appendData:@"这时第12段" useCell:@"TestCell" toSection:0];
//    [table appendData:@"这时第13段" useCell:@"TestCell" toSection:0];
//    [table appendData:@"这时第14段" useCell:@"TestCell" toSection:0];
//    [table appendData:@"这时第15段" useCell:@"TestCell" toSection:0];
    
    //或者一次性设定相同cell的一个列表内容
    //[table appendDataArray:@[@"这时第4段",@"这时第5段",@"这时第6段"] useCell:@"StatusCell" toSection:0];
    
    
    //[必须] 刷新页面
    [table refreshTable:^{
        NSLog(@"初始刷新完成");
    }];
    
    
    //[可选] 如果外部数据读取异常，可随时添加点击刷新覆盖层
    //[table showTapRefreshCover];

    
    //添加一个自定义下拉刷新层
    //[self addDragRefreshView];
    
}



#pragma mark - delegate form RDTableView
- (void)RDTableViewDidTrigger:(TriggerType)triggerType ontable:(RDTableView*)table
{
    if(triggerType == triggerRefresh)
    {
        NSLog(@"下拉刷新触发");
        [self performSelector:@selector(doneRefresh) withObject:nil afterDelay:2];
    }
    else if(triggerType == triggerLoadMore)
    {        
        NSLog(@"懒加载触发");
        [self performSelector:@selector(loadMore) withObject:nil afterDelay:2];
    }
}




#pragma mark - 操作方法
- (void)doneRefresh
{
    RDTableView *table = [self.view viewWithTag:1000];
    
    [table clearDatas];
    
    [table appendData:@"加餐1" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐2" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐3" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐4" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐5" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐6" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐7" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐8" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐9" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐10" useCell:@"TestCell" toSection:0];
    
    [table refreshTable:^{
        NSLog(@"下拉刷新完成");
    }];
    
}

- (void)loadMore
{
    //NSLog(@"加载更多12个");
    
    RDTableView *table = [self.view viewWithTag:1000];
    
//    table.loadMoreStyle = LoadMoreStyleNomore;
//    return;
    
    [table appendData:@"加餐1" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐2" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐3" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐4" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐5" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐6" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐7" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐8" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐9" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐10" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐11" useCell:@"TestCell" toSection:0];
    [table appendData:@"加餐12" useCell:@"TestCell" toSection:0];
    
    [table refreshTable:^{
        NSLog(@"加载更多刷新完成");
        
        table.loadMoreStyle = LoadMoreStyleNomore;
    }];
}

- (void)addAction:(id)sender
{
    RDTableView *table = [self.view viewWithTag:1000];
    
    [table insertData:@"额外插入的数据" useCell:@"TestCell" toIndexPath:RDIndexPath(0, 3)];
    [table refreshTableWithAnimation:UITableViewRowAnimationFade completion:^{
        NSLog(@"插入数据完成");
    }];
}

- (void)editAction:(id)sender
{
    RDTableView *table = [self.view viewWithTag:1000];
    [table setEditing:YES animated:YES];
    
    //[table tableTrigger:triggerRefresh];
}



#pragma mark -添加下拉刷新附加模块
- (void)addDragRefreshView
{
    RDTableView *table = [self.view viewWithTag:1000];
    
    UIView *dragView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 414, 60)];
    dragView.backgroundColor = [UIColor redColor];
        
    [table parasiticRefreshView:dragView kvoHeight:^(float height) {
        
        //NSLog(@"height: %f", height);
    } begain:^{
        
        NSLog(@"开启下拉刷新@@@@@#");
    } complete:^{
        
        NSLog(@"完成下拉刷新@@@@@#");
    }];

}




@end







