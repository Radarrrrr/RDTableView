//
//  RDTableView.h
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//
//
//[重要] 使用本类前，请仔细阅读以下说明：
//
//PS: 本类所使用的tableviewcell类，必须声明并实现-(void)setCellData:(id)data方法，否则无法传递参数
//PS: 区分多个本类，可以使用tag
//PS: 如果要修改cell的风格，必须在cell类里边修改。
//PS: 本类的目标是简化列表类tableview的创建和使用，并不想处理复杂的tableview的页面交互，比如row行拖动，这种效果需要单独制作页面来做(不然要SDK干嘛...)
//PS: 本类要使用，必须有继承自RDSuperCell的cell类才可以，不能单独使用
//PS: 本tableview中使用的cell，必须继承自RDSuperCell，并且必须实现 setCellStyle 和 setCellData 两个方法，否则无法传递参数
//


//使用方法:
/*
1. 添加本类头文件
#import "RDTableView.h"
 
 
2. 实现代理协议
<RDTableViewDelegate>
 
 
3. 添加本类到页面上
//[必须] 创建一个RDTableView
RDTableView *table = [[RDTableView alloc] initWithFrame:CGRectMake(0, 0, 320, 230)];
table.delegate = self;
table.tag = 1000;
table.loadMoreStyle = LoadMoreStyleLoading;
table.refreshStyle = RefreshStyleDropdown;
table.multiSelectEnabled = YES;
table.editRowEnabled = NO;
table.moveRowEnabled = NO;
 
//[可选] 设定tableview的某些风格 (tableViewCell的风格设定放到cell类内部自己去设定，不在这里做)
//table.tableView.backgroundColor = [UIColor whiteColor];             
//table.tableView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
//table.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//table.tableView.separatorColor = [UIColor redColor];
  
//[可选] 设定RDTableView内部控件的某些效果 (这里只起到了抛砖引玉的作用，其实每个内部控件都可以引出来，对里边的属性进行更改，可自由发挥)
//table.refreshControll.tintColor = [UIColor orangeColor];
//table.refreshCover.backgroundColor = [UIColor yellowColor];
//table.refreshCover.waitingLabel.text = @"载入中,请稍候..."; //这个如果不存在，就是点击屏幕刷新的时候只有一个滚球的效果
 
//[必须] 前面设定完毕了，可以添加到需要的页面上了
[self.view addSubview:table];
 
 
4.设定section的属性 (可根据需求选择用或者不用)
//[可选] 设定header和footer的view
UIView *hview = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)] autorelease];
hview.backgroundColor = [UIColor redColor];
UIView *fview = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)] autorelease];
fview.backgroundColor = [UIColor greenColor];
[table setSection:0 headerView:hview footerView:fview];
 
//[可选] 设定header和footer的高度 //除非想做空白区域出来，否则尽量不要使用此方法
[table setSection:0 headerHeight:20 footerHeight:30];

//[可选] 覆盖设定加载更多view，如果不设定，则使用默认效果
UIView *moreView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
moreView.backgroundColor = [UIColor blueColor];
table.moreLoadingView = moreView;
 
 
5. 组合数据源，当然此数据源可能来源于各种不同的方式，注意：data对应的元素必须与要显示的Cell需求的data相同类型
//[必须] 使用新方法进行页面显示
[table appendData:@"这时第1段" useCell:@"StatusCell" toSection:0];
[table appendData:@"这时第2段" useCell:@"HaloCell" toSection:0];
[table appendData:@"这时第3段" useCell:@"StatusCell" toSection:0];
 
//或者一次性设定相同cell的一个列表内容
[table appendDataArray:@[@"这时第4段",@"这时第5段",@"这时第6段"] useCell:@"StatusCell" toSection:0];
 
 
6.[必须] 刷新页面
[table refreshTable]; 
 
 
7.[可选] 如果外部数据读取异常，可随时添加点击刷新覆盖层
[table showTapRefreshCover];
*/



//另外
/*
 [table insertDataArray:@[@"添加数据第1段",@"添加数据第2段",@"添加数据第3段",@"添加数据第4段"] useCell:@"HaloCell" belowIndexPath:RDIndexPath(0, 3)];
 或者
 [table deleteDataArray:@[@"添加数据第1段",@"添加数据第2段",@"添加数据第3段",@"添加数据第4段"] inSection:0];
 必须配合另一个页面刷新方法使用
 [table refreshTableWithAnimation:UITableViewRowAnimationTop];
*/




//===========================================================================================
//dataArray的数据结构说明:
//PS: 本类内部使用的dataArray的数据结构是由appendData和appendDataArray这两个方法添加以后组合成的。
//PS: "data"里边的数据类型，都是和指定cell里边的setCellData类型相同的数据源
/*
//数据类型可以分多个section, 并且所有cell也都可以是不同的,一个字典就是一个section
[
    {
        "section_params":  //此字段可以没有
        {
            "header_height":"20",
            "footer_height":"30",
            "header_view":xxx,     //从外部做好的autoRelease类型的view, 必须每个都单独创建，否则内部重用就乱套了
            "footer_view":xxx      //从外部做好的autoRelease类型的view, 必须每个都单独创建，否则内部重用就乱套了
        },
        "rows":            //此字段必须有，否则无法判断类型
        [
            {"cell":"xxx", "data":xxx},
            {"cell":"xxx", "data":xxx},
            {"cell":"xxx", "data":xxx}
        ]
    },
    ...
]
*/
//===========================================================================================





#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RDTRefreshCover.h"


#define RDTableView_default_row_height          44.0      //默认cell高
#define RDTableView_default_more_height         40.0      //默认加载更多的高度
#define RDTableView_default_loadmore_delta      200.0     //默认懒加载的触发像素高度


typedef enum {
    LoadMoreStyleNone = 0,  //没有加载更多功能
    LoadMoreStyleLoading,   //正在加载中效果  PS: 本类只有在此状态下才可以继续判断是否懒加载触发
    LoadMoreStyleNomore     //默认的“没有更多”效果显示 不管是否外部替换了默认moreFooterView，都要对此状态做修改
} LoadMoreStyle;

typedef enum {
    RefreshStyleNone = 0,   //没有刷新功能
    RefreshStyleDropdown    //有下拉刷新风格 默认是UIRefreshContoller PS:如果使用自定义下拉刷新，就直接在外面创建寄生层，然后使用parasiticRefreshView寄生到refreshControler上就可以了
} RefreshStyle;

typedef enum {
    triggerRefresh = 0,    //触发下拉刷新
    triggerLoadMore        //触发上提读取更多
} TriggerType;




@class RDTableView;
@protocol RDTableViewDelegate <NSObject> 
@optional

- (void)RDTableViewDidSelectIndexPath:(NSIndexPath*)indexPath withData:(id)data ontable:(RDTableView*)table; //点击了某一个cell
- (void)RDTableViewDidDeselectIndexPath:(NSIndexPath*)indexPath withData:(id)data ontable:(RDTableView*)table; //取消了某一个cell的选中状态
- (void)RDTableViewDidTrigger:(TriggerType)triggerType ontable:(RDTableView*)table; //触发下拉刷新或者上提加载更多

- (void)RDTableViewDidDeleteRowAtIndexPath:(NSIndexPath*)indexPath ontable:(RDTableView *)table;//通过编辑模式删除了某一行
- (void)RDTableViewDidMoveRowFrom:(NSIndexPath*)fromIndexPath to:(NSIndexPath*)toIndexPath ontable:(RDTableView*)table; //从一个row移动到另一个row


//供外部某些特殊需求使用的，为了获取内部的tableview的滚动的事件而引出来的方法
- (void)RDTableViewDidScroll:(RDTableView*)table; 
- (void)RDTableViewDidEndDecelerating:(RDTableView *)scrollView;
- (void)RDTableViewDidEndDragging:(RDTableView *)scrollView willDecelerate:(BOOL)decelerate;

@end



@interface RDTableView : UIView <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, RDTRefreshCoverDelegate> 


//供外部设定的属性
@property (weak) id<RDTableViewDelegate> delegate;

@property (nonatomic) RefreshStyle refreshStyle;       //刷新功能触发风格 默认无刷新功能 RefreshStyleNone //PS:可随时更改，下次refreshTable的时候生效
@property (nonatomic) LoadMoreStyle loadMoreStyle;     //上提加载更多功能的触发风格，默认无上提加载更多 LoadMoreStyleNone //PS:可随时更改，下次refreshTable的时候生效

@property (nonatomic) BOOL multiSelectEnabled; //default is NO //是否允许多重选择cell，如果是，那么选择的时候就没有列表移动
@property (nonatomic) BOOL editRowEnabled;     //default is NO //是否可编辑   此处如果为NO，则可移动属性无效
@property (nonatomic) BOOL moveRowEnabled;     //default is NO //是否可移动行  此处如想为YES，则必须先设定 editRowEnabled为YES


//供外部使用的属性
@property (nonatomic, strong) UITableView         *tableView;            //本类中使用的tableview，供外面引用以后改变风格使用
@property (nonatomic, strong) NSMutableArray      *dataArray;            //供cell使用的数据数组，可以多种类型，但必须是由array封装起来的，data元素必须和cell里边的-(void)setCellData:(id)data的需求的data是同一个类型
@property (nonatomic, strong) UIView              *moreLoadingView;      //用做上提加载更多的footerView, 可从外部自己做一个view覆盖设定属性，然后各种动画和提示都可以以自己做了
@property (nonatomic, strong) RDTRefreshCover     *refreshCover;         //用做点击页面刷新的coverView，外部可拿到此属性来做样式更改
@property (nonatomic, strong) UIRefreshControl    *refreshControll;      //用作下拉刷新得效果controller, 这个属性只有在 RefreshStyleDropdown 的情况下才有意义




#pragma mark - [必须] 数据封装方法   配合 -(void)refreshTable: 页面刷新
//追加组装数据源
//追加每个section里边的row的数据，是最主要的数据源设定方法，理论上讲，配合reloadData这两个就可以完成列表了
//每一行cell的数据源都必须调用此方法一次，这个必须在程序外部使用for循环来实现
//PS: data的类型，必须是和cell里边的SetCellData使用的数据相同类型
//    cellClassName,是要用来显示此行row的cell的类名如: @"StatusCell"
//PS: data不能为空，即使cell里边不需要使用data，也至少写成@""，否则，模块会认为数据错误而不进行该cell的追加
- (void)appendData:(id)data useCell:(NSString*)cellClassName toSection:(NSInteger)section;

//极为简单的方法，仅能用于设定相同cell的列表，可以一次性追加组装一个数组
- (void)appendDataArray:(NSArray*)dataArr useCell:(NSString*)cellClassName toSection:(NSInteger)section;


#pragma mark - [可选] 数据插入方法   配合 -(void)refreshTableWithAnimation: 页面刷新
//插入数据源 //PS: indexPath 可用 RDIndexPath(s, r) 宏来写
//插入一些数据，可使用不同的cell，需要使用refreshTableWithAnimation方法进行刷新，才能有动画效果 
- (void)insertData:(id)data useCell:(NSString*)cellClassName toIndexPath:(NSIndexPath*)indexPath;

//极为简单的方法，仅能用于插入相同cell的列表，可以一次性插入一个数组，
//PS: 必须从indexPath所指定的行下面开始插入，因为一大堆数据插入的话，肯定是要放下面的，所以其他情况不必处理，这种情况也只能都插入到同一个section里面去
- (void)insertDataArray:(NSArray*)dataArr useCell:(NSString*)cellClassName belowIndexPath:(NSIndexPath*)indexPath;


#pragma mark - [可选] 数据删除方法   配合 -(void)refreshTableWithAnimation: 页面刷新
//删除数据源 //PS: indexPath 可用 RDIndexPath(s, r) 宏来写
- (void)deleteDataAtIndexPath:(NSIndexPath*)indexPath;

//极为简单的方法，一次性删除一个数组
- (void)deleteDataArrayByIndexPaths:(NSArray*)indexPathArray;
- (void)deleteDataArray:(NSArray*)dataArr inSection:(NSInteger)section; //PS: 使用这个方法，前提条件是，该section里边，如果有重复数据源，也会被同时移除



#pragma mark - [必须] 页面刷新方法
//使用前面封装好的数据源刷新页面，必须做的工作
- (void)refreshTable:(void(^)(void))completion;

//配合 insertData 和 deleteData 使用的刷新列表方法，选择使用哪种动画方式进行刷新 //PS: 请注意，插入和删除，一次只能做一件事，否则会出现冲突
- (void)refreshTableWithAnimation:(UITableViewRowAnimation)animation completion:(void(^)(void))completion; 



#pragma mark - [可选] section的属性设置方法
//设定section的属性，包括header和footer的高度或者headerView和footerView，目前只有这两种，以后可能会有更多
//PS: 两个设定section的属性的方法，可以随时使用，然后使用refreshTable刷新一次，如果没有该section的属性，就会加上，如果有就会覆盖
//    如果不需要设定section的属性，则无需调用这个两个方法

//设定section的headerView和footerView，如果想移除其中一个，就设定为nil即可，系统会自动以此方法设定的header和footer高度为优先级，自动检测高度
- (void)setSection:(NSInteger)section headerView:(UIView*)hView footerView:(UIView*)fView;

//手动设定section的header和footer的高度，尽量不要使用此方法, 除非想做空白的一个header和footer的区域出来。因为系统会自动根据前面方法设定的header和footer检测高度的。
- (void)setSection:(NSInteger)section headerHeight:(float)hHeight footerHeight:(float)fHeight;



#pragma mark - [可选] 数据清理方法
//如果数据有更改，使用下面方法改动数据源以后，再重复调用第一步重新
- (void)clearParamsOfSection:(NSInteger)section;   //清空某个section的属性设置，但是里边的row数据不变
- (void)clearDatasOfSection:(NSInteger)section;    //清空某个section里边所有的row数据，但是section的属性不变
- (void)clearTableDatasAndParams;   //清空所有的数据,包括section所设定的属性,如果压根没设定section的属性，那么这个方法和clearDatas是一个显示效果

//[重要] 清空所有section的Row的数据,但是section所设定的属性不变,重置列表数据源主要用这个
- (void)clearDatas;           





#pragma mark - 外部配套使用方法，供外部使用对内部的列表进行一些其他操作，更多方法随版本升级逐渐扩展...
//[重要] 从外部触发tableView的刷新或者读取更多，使用触发类型
- (void)tableTrigger:(TriggerType)triggerType; 

//[重要] 如果数据读取出现了异常，那么可以使用这个方法来附加一层点击刷新的覆盖层，返回事件和下拉刷新一样，同样会触发下拉刷新一次
//PS:此方法会清空当前列表中的所有数据并重新刷新一次页面（section的属性设置除外）
- (void)showTapRefreshCover; 

//选择某一个index对应的cell, 可以设定选中时候的滚动状态
- (void)selectIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition;

//取消选择某一个index对应的cell
- (void)deselectIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated;

//取消选择某一个section里边所有cell的选中状态
- (void)deselectAllInSection:(NSInteger)section animated:(BOOL)animated;

//设定编辑状态
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

//[重要] 寄生一个下拉刷新view，用于外部添加自定义下拉刷新效果，该view会寄生在refreshControl上面，获取它的高度及触发状态，寄生view可根据返回的状态改变自己的状态
- (void)parasiticRefreshView:(UIView*)refreshView
                   kvoHeight:(void(^)(float height))refreshHeight 
                      begain:(void(^)(void))refreshBegain
                    complete:(void(^)(void))refreshComplete;



#pragma mark - 外部配套使用方法，数据相关方法，供外部对内部的数据进行某些操作，更多方法随版本升级逐渐扩展...
- (BOOL)checkIfDatasClear; //检查是否数据已经被清空或者完全无数据，不考虑section的属性
- (id)cellDataOfRow:(NSInteger)row inSection:(NSInteger)section;        //获取在section，row这个cell上的data，是{"cell":"xxx", "data":xxx}里边的"data"部分，纯数据
- (NSString*)cellNameOfRow:(NSInteger)row inSection:(NSInteger)section; //获取在section，row这个cell的className，是{"cell":"xxx", "data":xxx}里边的"cell"部分，纯数据字符串
- (NSIndexPath*)indexPathForData:(id)data inSection:(NSInteger)section; //获取在section里边，data数据对应的indexPath，如果对应不上，返回nil



#pragma mark - 一些类方法
//组装一个NSIndexPath
+ (NSIndexPath*)indexPathWithSection:(NSInteger)section row:(NSInteger)row;

//方法宏 -> 组装一个NSIndexPath
#define RDIndexPath(s, r) [RDTableView indexPathWithSection:s row:r]




@end
