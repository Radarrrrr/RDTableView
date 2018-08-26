//
//  RDTableView.h
//
//  Created by radar on 2018/8/16.
//  Copyright © 2018年 radar. All rights reserved.
//

#import "RDTableView.h"
#import "RDTLoadingDots.h"


typedef enum {
    loadingNone = 0,    //没在做任何事情
    loadingRefresh,     //正在读取刷新
    loadingMore         //正在读取更多
} LoadingType;



#pragma mark -
#pragma mark in use functions and params
@interface RDTableView () {
    
    BOOL _multiSelectEnabled;     //是否可多选
    LoadMoreStyle _loadMoreStyle; //加载更多样式
    
}

@property (nonatomic)  LoadingType loadingType;   //正在读取更多或者刷新中，default if loadingNone，同时只能做一件事情

@property (nonatomic, strong) NSMutableArray *insertArray;  //插入数据的NSIndexPath数组，用来做动画插入的
@property (nonatomic, strong) NSMutableArray *deleteArray;  //删除数据的NSIndexPath数组，用来做动画删除的

//寄生下拉刷新
@property (nonatomic, strong) UIView *parasiticView; //寄生到下拉refreshControl上的外部刷新类
@property (nonatomic) void (^refreshHeightHandler)(float height);
@property (nonatomic) void (^refreshBegainHandler)(void);
@property (nonatomic) void (^refreshCompleteHandler)(void);



- (NSString*)cellClassNameForIndexPath:(NSIndexPath *)indexPath;
- (id)cellDataForIndexPath:(NSIndexPath*)indexPath;

- (float)lastCellHeight;  //获取最后一个section的最后一个cell的高度

- (NSMutableDictionary*)emptyDictionaryForSectionStucture;       //创建空的字典供section使用
- (NSMutableDictionary*)dictionaryForSection:(NSInteger)section; //检查并创建然后获取section对应的字典, 返回的secDic必然存在

- (void)dragRefreshAction:(UIRefreshControl *)refreshControl; //下拉刷新触发事件

- (NSMutableArray*)rowsDatasForSection:(NSInteger)section; //找到section对应的组里边的所有行的数据数组

- (id)valueOfData:(id)data byPath:(NSString*)path;
- (NSArray*)findValuesForKey:(NSString*)key inData:(id)data;


- (void)doneLoading; //根据触发读取情况的类型，关闭等待状态

@end



@implementation RDTableView

@dynamic multiSelectEnabled;
@dynamic loadMoreStyle;


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
        
        //禁用Self-Sizing
        if (@available(iOS 11.0, *)) {
            
            UITableView.appearance.estimatedRowHeight = 0;
            UITableView.appearance.estimatedSectionFooterHeight = 0;
            UITableView.appearance.estimatedSectionHeaderHeight = 0;
        }
        
        //属性初始化
        _refreshStyle = RefreshStyleNone;
        _loadMoreStyle = LoadMoreStyleNone;

        self.loadingType = loadingNone;
        
        _editRowEnabled = NO;
        _moveRowEnabled = NO;
        
        //初始化dataArray
        self.dataArray = [[NSMutableArray alloc] init];
        self.insertArray = [[NSMutableArray alloc] init];
        self.deleteArray = [[NSMutableArray alloc] init];

		//add table view
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) style:UITableViewStylePlain];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		_tableView.delegate = self;
		_tableView.dataSource = self;
		[self addSubview:_tableView];
        
        
        //add _moreLoadingView
        self.moreLoadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, RDTableView_default_more_height)];
        _moreLoadingView.backgroundColor = [UIColor clearColor];
        
//        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((frame.size.width-20)/2, (CGRectGetHeight(_moreLoadingView.frame)-20)/2, 20, 20)];
//        spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
//        [spinner startAnimating];
//        spinner.tag = 1876001;
//        spinner.alpha = 1.0;
//        [_moreLoadingView addSubview:spinner];
        
        RDTLoadingDots *loadingDots = [[RDTLoadingDots alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_moreLoadingView.frame), CGRectGetHeight(_moreLoadingView.frame))];
        loadingDots.tag = 1876001;
        loadingDots.alpha = 1.0;
        //[loadingDots startFlashing];
        [_moreLoadingView addSubview:loadingDots];
        
        
        UILabel *nomoreL = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_moreLoadingView.frame), CGRectGetHeight(_moreLoadingView.frame))];
        nomoreL.userInteractionEnabled = NO;
        nomoreL.textAlignment = NSTextAlignmentCenter;
        nomoreL.backgroundColor = [UIColor clearColor];
        nomoreL.font = [UIFont systemFontOfSize:12.0];
        nomoreL.textColor = [UIColor colorWithRed:150.0/255.0 green:150.0/255.0 blue:150.0/255.0 alpha:1.0];
        nomoreL.text = @"没有更多了";
        nomoreL.tag = 1876002;
        nomoreL.alpha = 0.0;
        [_moreLoadingView addSubview:nomoreL];
        
        
        //add _refreshCover
        self.refreshCover = [[RDTRefreshCover alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _refreshCover.delegate = self;
        
        //add _refreshControll
        self.refreshControll = [[UIRefreshControl alloc] init];
        [_refreshControll addTarget:self action:@selector(dragRefreshAction:) forControlEvents:UIControlEventValueChanged];
        
        //这俩可以通过外面调用refreshControll来修改，这里只是用来作备忘的
        //_refreshControll.attributedTitle = [[NSAttributedString alloc] initWithString:@"123"];
        //_refreshControll.tintColor = [UIColor greenColor];
        
        
        //这两个在调用的地方修改，这里只是用来做备忘的
        //_tableView.backgroundColor = [UIColor whiteColor];
        //_tableView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    
    }
    return self;
}

- (void)dealloc 
{
    [self removeKVOfromRefresh];
}



#pragma mark - 内部类方法
- (id)valueOfData:(id)data byPath:(NSString*)path
{
    if(!data) return nil;
    if(!path || [path compare:@""] == NSOrderedSame) return nil;
    
    //获取每个节点的标识，都是string，如果是数组，再临时转化
    NSArray *stones = [path componentsSeparatedByString:@"."];
    
    //开始解析每一层
    id subdata = data;
    for(NSString *stone in stones)
    {
        if(!subdata)
        {
            break;
        }
        
        if([subdata isKindOfClass:[NSDictionary class]])
        {
            id subd = [subdata objectForKey:stone];
            if([subd isKindOfClass:[NSNull class]])
            {
                subd = nil;
            }
            subdata = subd;
            continue;
        }
        else if([subdata isKindOfClass:[NSArray class]])
        {
            NSInteger index = [stone integerValue];
            if(index >= [subdata count]) 
            {
                subdata = nil;
                break;
            }
            
            subdata = [subdata objectAtIndex:index];
            continue;
        }
        else 
        {
            return nil;
        }
    }
    
    return subdata;
}

- (NSArray*)findValuesForKey:(NSString*)key inData:(id)data
{
    //在data数据源里，找到所有的key对应的数据value，并组成数组返回
    if(!data) return nil;
    if(!key || [key compare:@""] == NSOrderedSame) return nil;
    if(![data isKindOfClass:[NSDictionary class]] && ![data isKindOfClass:[NSArray class]]) return nil;
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    //开始解析
    if([data isKindOfClass:[NSDictionary class]])
    {
        NSArray *keys = [data allKeys];
        for(NSString *akey in keys)
        {
            if([akey compare:key] == NSOrderedSame)
            {
                id value = [data objectForKey:key];
                if(value) 
                {
                    [values addObject:value];
                }
            }
            else
            {
                id adata = [data objectForKey:akey];
                NSArray *avals = [self findValuesForKey:key inData:adata];
                if(avals && [avals count] != 0)
                {
                    [values addObjectsFromArray:avals];
                }
            }
        }
    }
    else if([data isKindOfClass:[NSArray class]])
    {
        for(id adata in data)
        {
            NSArray *avals = [self findValuesForKey:key inData:adata];
            if(avals && [avals count] != 0)
            {
                [values addObjectsFromArray:avals];
            }
        }
    }
    
    return values;
}



#pragma mark -
#pragma mark setter & getter functions
- (void)setMultiSelectEnabled:(BOOL)multiSelectEnabled
{
    _multiSelectEnabled = multiSelectEnabled;
    _tableView.allowsMultipleSelection = _multiSelectEnabled;
}
- (BOOL)multiSelectEnabled
{
    return _multiSelectEnabled;
}

- (void)setLoadMoreStyle:(LoadMoreStyle)loadMoreStyle
{
    _loadMoreStyle = loadMoreStyle;
    
    //修改状态显示
    RDTLoadingDots *loadingDots = [_moreLoadingView viewWithTag:1876001];
    UILabel *nomoreL = [_moreLoadingView viewWithTag:1876002];

    switch (_loadMoreStyle) {
        case LoadMoreStyleNone:
        {
            self.tableView.tableFooterView = nil;
        }
            break;
        case LoadMoreStyleLoading:
        {
            if(loadingDots) 
            {
                loadingDots.alpha = 1.0;
                [loadingDots startFlashing];
            }
            
            if(nomoreL) 
            {
                nomoreL.alpha = 0.0;
            }
            
            self.tableView.tableFooterView = self.moreLoadingView;
        }
            break;
        case LoadMoreStyleNomore:
        {
            if(loadingDots) 
            {
                [loadingDots stopFlashing];
                loadingDots.alpha = 0.0;
            }
            
            if(nomoreL) 
            {
                nomoreL.alpha = 1.0;
            }
            
            self.tableView.tableFooterView = self.moreLoadingView;
        }
            break;
        default:
            break;
    }
}
- (LoadMoreStyle)loadMoreStyle
{
    return _loadMoreStyle;
}




#pragma mark -
#pragma mark in use functions and params
- (NSString*)cellClassNameForIndexPath:(NSIndexPath*)indexPath
{
    if(!indexPath) return nil;
    if(!_dataArray || [_dataArray count] == 0) return nil;
    
    NSString *cellClassName = nil;
    
    NSString *path = [NSString stringWithFormat:@"%d.rows.%d.cell", (int)indexPath.section, (int)indexPath.row];
    cellClassName = (NSString*)[self valueOfData:_dataArray byPath:path];
    
    return cellClassName;
}
- (id)cellDataForIndexPath:(NSIndexPath*)indexPath
{
    if(!indexPath) return nil;
    if(!_dataArray || [_dataArray count] == 0) return nil;
    
    id data = nil;
    
    NSString *path = [NSString stringWithFormat:@"%d.rows.%d.data", (int)indexPath.section, (int)indexPath.row];
    data = [self valueOfData:_dataArray byPath:path];
    
    return data;
}

- (float)lastCellHeight
{
    //获取最后一个section的最后一个cell的高度
    float cellHeight = RDTableView_default_row_height;
    
    if(!_dataArray || [_dataArray count] == 0 || [self checkIfDatasClear]) return cellHeight;
    
    //找到最后一个section
    NSInteger section = [_dataArray count]-1;
    
    //找到最后一个row
    NSMutableDictionary *secDic = [_dataArray objectAtIndex:section];
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || [rows count] == 0)
    {
        return cellHeight;
    }
    
    NSInteger row = [rows count]-1;
    
    //组合indexpath
    NSUInteger ints[2] = {section, row};
	NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
    
    //获取该cell的高度
    cellHeight = [self tableView:_tableView heightForRowAtIndexPath:indexPath];
    
    return cellHeight;
}

- (NSMutableDictionary*)emptyDictionaryForSectionStucture 
{
    //创建空的字典供section使用
    NSMutableDictionary *emptyDic = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] init];
    NSMutableArray      *rowsArray = [[NSMutableArray alloc] init];
    
    [emptyDic setObject:paramsDic forKey:@"section_params"];
    [emptyDic setObject:rowsArray forKey:@"rows"];
    
    return emptyDic;
}

- (NSMutableDictionary*)dictionaryForSection:(NSInteger)section
{
    //检查并创建然后获取section对应的字典, 返回的secDic必然存在
    if(!_dataArray)
    {
        self.dataArray = [[NSMutableArray alloc] init];
    }
    
    NSString *spath = [NSString stringWithFormat:@"%d", (int)section];
    id secDic = [self valueOfData:_dataArray byPath:spath];
    
    //有现成的secDic，就直接返回使用
    if(secDic) return secDic;
    
    
    //没有现成的secDic，那么创建新的补齐从现有个数直到section指定的个数
    NSInteger count = [_dataArray count];
    for(NSInteger i=count; i<=section; i++)
    {
        //创建空字典添加到数组里边去,补齐需要的个数
        NSMutableDictionary *emptyDic = [self emptyDictionaryForSectionStucture];
        [_dataArray addObject:emptyDic];
    }
    
    //再重新取一次secDic
    NSString *npath = [NSString stringWithFormat:@"%d", (int)section];
    id useDic = [self valueOfData:_dataArray byPath:npath];
    
    return useDic;
}

- (void)dragRefreshAction:(UIRefreshControl *)refreshControl
{
    //下拉刷新触发事件
    //只有当前读取状态是None的时候才触发刷新, 否则这次就算白下拉了
    if(_loadingType == loadingNone)
    {
        [self tableTrigger:triggerRefresh];
    }
    else
    {
        if(_refreshControll)
        {
            [_refreshControll endRefreshing];
            
            //通知寄生下拉层，如果存在的话
            if(self.refreshCompleteHandler)
            {
                self.refreshCompleteHandler();
            }
        }
    }
}


- (void)checkAndTriggerLoadMore
{
    if(_loadingType != loadingNone) return;
    if(_loadMoreStyle != LoadMoreStyleLoading) return;
    if(!_moreLoadingView) return;
    
    
    //检查是否需要加载更多
    CGPoint cntOffset = _tableView.contentOffset;
    CGSize  cntSize   = _tableView.contentSize;
    CGRect  rect = _tableView.frame;
    
    if(cntSize.height >= rect.size.height)
    {
        if(cntOffset.y >= cntSize.height-rect.size.height-RDTableView_default_loadmore_delta)
        {
            //加载更多触发                
            [self tableTrigger:triggerLoadMore];
        }
    }
}

- (NSMutableArray*)rowsDatasForSection:(NSInteger)section
{
    //找到section对应的组里边的所有行的数据数组
    if(!_dataArray || [_dataArray count] == 0) return nil;
    
    NSString *secPath = [NSString stringWithFormat:@"%d", (int)section];
    NSMutableDictionary *secDic = [self valueOfData:_dataArray byPath:secPath];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return nil;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]]) return nil;
    
    return rows;
}




#pragma mark -
#pragma mark Table View DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	
    NSInteger count = 1;
    
    if(_dataArray && [_dataArray count] != 0)
    {
        count = [_dataArray count];
    }
    
	return count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	if(!_dataArray || [_dataArray count] == 0) return 0;
    
    NSInteger count = 0;
        
    NSString *path = [NSString stringWithFormat:@"%d.rows", (int)section];
    NSArray *rows = [self valueOfData:_dataArray byPath:path];
    if(rows && [rows count] != 0)
    {
        count = [rows count];
    }
    
	return count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //获取cellID 
    //PS: 这里的kCellID其实就是要用到的类的类名，用类名直接做cell的重用ID了
    NSString *cellClassName = [self cellClassNameForIndexPath:indexPath];
    
	
    //开始创建cell
    UITableViewCell *cell = nil;
    
    if(cellClassName && [cellClassName compare:@""] != NSOrderedSame)
    {
        //获得cell的类型
        Class CellClass = NSClassFromString(cellClassName);
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellClassName];
        if(cell == nil)
        {
            cell = [[CellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellClassName];
            
            //这两个在调用的地方修改，这里只是用来做备忘的
            //cell.accessoryType = UITableViewCellAccessoryNone;
            //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        
        //获取cell所用的数据
        id data = [self cellDataForIndexPath:indexPath];
        
        
        //设定cell的data
        if(cell && [[cell class] isSubclassOfClass:[UITableViewCell class]])
        {
            if([cell respondsToSelector:@selector(setCellData:atIndexPath:)])
            {
                NSNumber *hnum = [cell performSelector:@selector(setCellData:atIndexPath:) withObject:data withObject:indexPath];
                
                if(!hnum)
                {
                    hnum = [NSNumber numberWithFloat:RDTableView_default_row_height];
                }
                
                if([cell respondsToSelector:@selector(confirmCellHeight:)])
                {
                    [cell performSelector:@selector(confirmCellHeight:) withObject:hnum];
                }
            }
        }
    }
    
    
    //如果cell没创建成功，返回一个空白页面，防止crash
    if(!cell)
    {
        cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"a blank cell"];
        if(!cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"a blank cell"];
            cell.backgroundColor = [UIColor clearColor];
        }
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    //获取该cell所用的数据
    id data = [self cellDataForIndexPath:indexPath];
    	
	if(self.delegate &&[(NSObject*)self.delegate respondsToSelector:@selector(RDTableViewDidSelectIndexPath:withData:ontable:)])
	{
		[self.delegate RDTableViewDidSelectIndexPath:indexPath withData:data ontable:self];
	}
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    //获取该cell所用的数据
    id data = [self cellDataForIndexPath:indexPath];
    
	if(self.delegate &&[(NSObject*)self.delegate respondsToSelector:@selector(RDTableViewDidDeselectIndexPath:withData:ontable:)])
	{
		[self.delegate RDTableViewDidDeselectIndexPath:indexPath withData:data ontable:self];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //创造一个testcell
    NSString *cellClassName = [self cellClassNameForIndexPath:indexPath];
    if(!cellClassName || [cellClassName compare:@""] == NSOrderedSame) return RDTableView_default_row_height;
    
    Class CellClass = NSClassFromString(cellClassName);
    UITableViewCell *testcell = [[CellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"testCell"];
    
    float height = RDTableView_default_row_height;
    
	if([[testcell class] isSubclassOfClass:[UITableViewCell class]])
    {
        if([testcell respondsToSelector:@selector(setCellData:atIndexPath:)])
        {
            id data = [self cellDataForIndexPath:indexPath];
            NSNumber *hnum = [testcell performSelector:@selector(setCellData:atIndexPath:) withObject:data withObject:indexPath];
            if(hnum)
            {
                height = [hnum floatValue];
            }
        }
    }
    
	return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    float height = 0.0;
    
    NSString *hhpath = [NSString stringWithFormat:@"%d.section_params.header_height", (int)section];
    NSString *hvpath = [NSString stringWithFormat:@"%d.section_params.header_view", (int)section];
    
    NSString *headerH = (NSString*)[self valueOfData:_dataArray byPath:hhpath];
    UIView   *headerV = (UIView*)[self valueOfData:_dataArray byPath:hvpath];
    
    if(headerH || headerV)
    {
        //优先使用headerView的高度设定
        if(headerV)
        {
            height = headerV.frame.size.height;
        }
        else
        {
            height = [headerH floatValue];
        }
    }
        
    return height;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    float height = 0.0;
    
    NSString *fhpath = [NSString stringWithFormat:@"%d.section_params.footer_height", (int)section];
    NSString *fvpath = [NSString stringWithFormat:@"%d.section_params.footer_view", (int)section];
    
    NSString *footerH = (NSString*)[self valueOfData:_dataArray byPath:fhpath];
    UIView   *footerV = (UIView*)[self valueOfData:_dataArray byPath:fvpath];
    
    if(footerH || footerV)
    {
        //优先使用footerView的高度设定
        if(footerV)
        {
            height = footerV.frame.size.height;
        }
        else
        {
            height = [footerH floatValue];
        }
    }

    return height;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *hView = nil;
    
    NSString *hvpath = [NSString stringWithFormat:@"%d.section_params.header_view", (int)section];
    UIView   *headerV = (UIView*)[self valueOfData:_dataArray byPath:hvpath];
    if(headerV)
    {
        hView = headerV;
    }
    
    return hView;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *fView = nil;
    
    NSString *fvpath = [NSString stringWithFormat:@"%d.section_params.footer_view", (int)section];
    UIView   *footerV = (UIView*)[self valueOfData:_dataArray byPath:fvpath];
    if(footerV)
    {
        fView = footerV;
    }
        
    return fView;
}



//编辑行相关方法
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath  
{  
    return UITableViewCellEditingStyleDelete;  
}  
-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath  
{  
    return @"删除";  
}  
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete) 
    {  
        //点击了删除
        [self deleteDataAtIndexPath:indexPath];
        [self refreshTableWithAnimation:UITableViewRowAnimationFade completion:^{
        }];
        
        //返回给代理
        if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(RDTableViewDidDeleteRowAtIndexPath:ontable:)])
        {
            [self.delegate RDTableViewDidDeleteRowAtIndexPath:indexPath ontable:self];
        }
    }  
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _editRowEnabled;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _moveRowEnabled;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if(!_dataArray || [_dataArray count] == 0) return;
    
    //拿到source对应的数据数组    
    NSMutableArray *sourceRows = [self rowsDatasForSection:sourceIndexPath.section];
    if(!sourceRows || [sourceRows count] == 0) return;
    if(sourceIndexPath.row >= [sourceRows count]) return;
    
    //找到destination对应的数据数组
    NSMutableArray *destRows = [self rowsDatasForSection:destinationIndexPath.section];
    if(!destRows) return;
    
    
    //移动source对应的数据到destination位置
    id sourceData = [sourceRows objectAtIndex:sourceIndexPath.row];
    
    //插入到destRows的数组里边
    [destRows insertObject:sourceData atIndex:destinationIndexPath.row];
    
    //移除这一行数据
    [sourceRows removeObjectAtIndex:sourceIndexPath.row];
    
    
    //返回代理
    if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(RDTableViewDidMoveRowFrom:to:ontable:)])
	{
		[self.delegate RDTableViewDidMoveRowFrom:sourceIndexPath to:destinationIndexPath ontable:self];
	}

}




#pragma mark -
#pragma mark UIScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(RDTableViewDidScroll:)])
	{
		[self.delegate RDTableViewDidScroll:self];
	}
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(RDTableViewDidEndDecelerating:)])
	{
		[self.delegate RDTableViewDidEndDecelerating:self];
	}
    
    //处理列表停止滚动事件
    [self handleScrollStop:scrollView];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    //注：当decelerate为YES时，会进入scrollViewDidEndDecelerating：方法
    if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(RDTableViewDidEndDragging:willDecelerate:)])
	{
		[self.delegate RDTableViewDidEndDragging:self willDecelerate:decelerate];
	}
    
    //如果没有加速度，说明是用手托动列表然后停止的,否则说明是甩动滚动停止的，要到scrollViewDidEndDecelerating：方法里边去处理
    if(!decelerate)
    {
        //处理列表停止滚动事件
        [self handleScrollStop:scrollView];
    }
}

- (void)handleScrollStop:(UIScrollView *)scrollView
{
    //当scroll停止的时候，处理某些事件，此方法包含用手托动+甩动滚动
    //检查是否需要触发读取,只有自动触发才判断，手动的不理
    if(_loadMoreStyle == LoadMoreStyleLoading)
    {
        [self checkAndTriggerLoadMore];
    }
}



#pragma mark -
#pragma mark other delegate functions
//RDTRefreshCoverDelegate
- (void)refreshCoverDidTapTrigger
{
    //刷新触发                
    [self tableTrigger:triggerRefresh];
    
}




#pragma mark -
#pragma mark 配套使用方法，供外部使用对内部的列表进行一些其他操作，更多方法随版本升级逐渐扩展...
- (void)selectIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition
{
    if(!indexPath) return;
    [_tableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
}

- (void)deselectIndexPath:(NSIndexPath*)indexPath animated:(BOOL)animated
{
    if(!indexPath) return;
    [_tableView deselectRowAtIndexPath:indexPath animated:animated];
}

- (void)deselectAllInSection:(NSInteger)section animated:(BOOL)animated
{
    //找到section对应的rows
    NSString *secPath = [NSString stringWithFormat:@"%d", (int)section];
    NSMutableDictionary *secDic = [self valueOfData:_dataArray byPath:secPath];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]] || [rows count] == 0) return;
    
    for(int i=0; i<[rows count]; i++)
    {
        NSUInteger ints[2] = {section, i};
        NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
        [_tableView deselectRowAtIndexPath:indexPath animated:animated];
    }
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [_tableView setEditing:editing animated:animated];
}




#pragma mark - 寄生下拉刷新及KVO相关
//[重要] 寄生一个下拉刷新view，用于外部添加自定义下拉刷新效果，该view会寄生在refreshControl上面，获取它的高度及触发状态，寄生view可根据返回的状态改变自己的状态
- (void)parasiticRefreshView:(UIView*)refreshView
                   kvoHeight:(void(^)(float height))refreshHeight 
                      begain:(void(^)(void))refreshBegain
                    complete:(void(^)(void))refreshComplete
{
    if(!refreshView) return;
    if(_refreshStyle == RefreshStyleNone) return;
    if(!_refreshControll) return;
    
    //接一下这几个block
    self.parasiticView = refreshView;
    self.refreshHeightHandler = refreshHeight;
    self.refreshBegainHandler = refreshBegain;
    self.refreshCompleteHandler = refreshComplete;
    
    //此种情况下，把背景色改成透明，才可以获取真实高度
    _refreshControll.backgroundColor = [UIColor clearColor];
    [_refreshControll addSubview:_parasiticView];
    
    //对refreshControl添加kvo
    [self addKVOtoRefresh];
}

//KVO操作
- (void)addKVOtoRefresh
{
    if(!_refreshControll) return;
    [_refreshControll addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
}
- (void)removeKVOfromRefresh
{
    if(!_refreshControll) return;
    
    [_refreshControll removeObserver:self forKeyPath:@"frame"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(_refreshControll && object == _refreshControll && [keyPath isEqualToString:@"frame"]) 
    {
        float width  = _refreshControll.frame.size.width;
        float height = _refreshControll.frame.size.height;
        
        //修改寄生层高度，在这里强制修改，是为了保证效果上能强制覆盖原下拉层，外部没有必要在做高度修改了
        if(_parasiticView)
        {
            CGRect pframe = _parasiticView.frame;
            pframe.size.width = width;
            pframe.size.height = height;
            _parasiticView.frame = pframe;
        }
        
        //返回寄生层
        if(self.refreshHeightHandler)
        {
            self.refreshHeightHandler(height);
        }
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}





#pragma mark - 外部配套使用方法，数据相关方法，供外部对内部的数据进行某些操作，更多方法随版本升级逐渐扩展...
- (BOOL)checkIfDatasClear
{
    //检查是否数据已经被清空或者完全无数据，不考虑section的属性
    BOOL cleared = YES;
    
    NSArray *rowsArrs = [self findValuesForKey:@"rows" inData:_dataArray];
    if(rowsArrs && [rowsArrs count] != 0)
    {
        for(id rowsArr in rowsArrs)
        {
            if([rowsArr isKindOfClass:[NSArray class]])
            {
                if([(NSArray*)rowsArr count] != 0)
                {
                    cleared = NO;
                    break;
                }
            }
        }
        
    }
    
    return cleared;
}
- (id)cellDataOfRow:(NSInteger)row inSection:(NSInteger)section
{
    if(!_dataArray || [_dataArray count] == 0) return nil;
    
    NSString *path = [NSString stringWithFormat:@"%d.rows.%d.data", (int)section, (int)row];
    id data = [self valueOfData:_dataArray byPath:path];
    
    return data;
}
- (NSString*)cellNameOfRow:(NSInteger)row inSection:(NSInteger)section
{
    if(!_dataArray || [_dataArray count] == 0) return nil;
    
    NSString *path = [NSString stringWithFormat:@"%d.rows.%d.cell", (int)section, (int)row];
    NSString *name = [self valueOfData:_dataArray byPath:path];
    
    return name;
}
- (NSIndexPath*)indexPathForData:(id)data inSection:(NSInteger)section
{
    //找到section对应的rows
    NSString *secPath = [NSString stringWithFormat:@"%d", (int)section];
    NSMutableDictionary *secDic = [self valueOfData:_dataArray byPath:secPath];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return nil;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]] || [rows count] == 0) return nil;
    
    
    NSIndexPath *findIndexPath = nil;
    for(int i=0; i<[rows count]; i++)
    {
        NSDictionary *rowdic = [rows objectAtIndex:i];
        id rowdata = [rowdic objectForKey:@"data"];
        if(rowdata && [rowdata isEqual:data])
        {
            //找到了和当前这个数据相同的位置
            findIndexPath = RDIndexPath(section, i);
            break;
        }
    }
    
    return findIndexPath;
}


- (void)tableTrigger:(TriggerType)triggerType
{
    //如果正在读取中，就不触发了，等待done的返回重置
    if(_loadingType != loadingNone) return;
    
    //改动触发点的状态
    if(triggerType == triggerLoadMore)
    {
        if(_loadMoreStyle == LoadMoreStyleNone) return;
        
        //设定读取状态
        self.loadingType = loadingMore;
    }
    else if(triggerType == triggerRefresh)
    {
        if(_refreshStyle == RefreshStyleNone) return;
        
        //设定读取状态
        self.loadingType = loadingRefresh;
        
        //设定等待
        //如果有点击刷新被覆盖了，那么就启动点击刷新的等待效果
        if(_refreshCover && [_refreshCover superview])
        {
            [_refreshCover startWaiting];
        }
        
        //开启下拉刷新的等待效果
        if(_refreshControll && [_refreshControll superview])
        {
            //通知寄生下拉层，如果存在的话
            if(self.refreshBegainHandler)
            {
                self.refreshBegainHandler();
            }
            
            if(!_refreshControll.refreshing) //如果refreshing为YES的时候，说明是手动自己在下拉，如果为NO，说明此时需要强制展开下拉效果
            {
                //从外面强制开启刷新效果
                [_refreshControll beginRefreshing];
                
                //把tableview移动到最顶部，看到刷新滚动效果
                CGPoint cntOffset = _tableView.contentOffset;
                cntOffset.y = -_refreshControll.frame.size.height;
                [_tableView setContentOffset:cntOffset animated:YES];
            }
        }
        
    }
    
    //返回给代理
    if(self.delegate && [(NSObject*)self.delegate respondsToSelector:@selector(RDTableViewDidTrigger:ontable:)])
    {
        [self.delegate RDTableViewDidTrigger:triggerType ontable:self];
    }
    
}


- (void)showTapRefreshCover
{
    //如果数据读取出现了异常，那么可以使用这个方法来附加一层点击刷新的覆盖层，返回事件和下拉刷新一样，同样会触发下拉刷新一次
    //因为是异常才会使用这个，并且覆盖以后只有点击刷新才能获取新数据，所以这里直接做一次数据清空工作
    [self clearDatas];
    [self refreshTable:^{
    }];
    
    //添加覆盖层
    if(_refreshCover && ![_refreshCover superview])
    {
        [self addSubview:_refreshCover];
    }
}


- (void)doneLoading
{
    //根据触发读取情况的类型，关闭等待状态
    if(_loadingType == loadingMore)
    {
    }
    else if(_loadingType == loadingRefresh)
    {
        //关闭并移除点击刷新
        if(_refreshCover && [_refreshCover superview])
        {
            [_refreshCover stopWaiting];
            [_refreshCover removeFromSuperview];
        }
        
        //处理下拉刷新的恢复状态
        if(_refreshStyle == RefreshStyleDropdown)
        {
            if(_refreshControll && [_refreshControll superview])
            {
                if(_refreshControll.refreshing)
                {
                    //关闭刷新效果
                    [_refreshControll endRefreshing];
                    
                    //通知寄生下拉层，如果存在的话
                    if(self.refreshCompleteHandler)
                    {
                        self.refreshCompleteHandler();
                    }
                    
                    //刷新动作完成以后，把列表变回最顶层，不然效果不对劲
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        [NSThread sleepForTimeInterval:0.5];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            CGPoint cntOffset = self.tableView.contentOffset;
                            cntOffset.y = 0;
                            [self.tableView setContentOffset:cntOffset animated:YES];
                        });
                    });
                    
                }
            }
            
        }
    }
    
    self.loadingType = loadingNone;
}





#pragma mark -
#pragma mark 新数据封装方法，推荐使用此方法
//追加组装数据源
- (void)appendData:(id)data useCell:(NSString*)cellClassName toSection:(NSInteger)section
{
    if(!cellClassName || [cellClassName compare:@""] == NSOrderedSame) return;
    if(!data) return;
    
    NSMutableDictionary *secDic = [self dictionaryForSection:section];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]]) return;
    
    
    //创建这一行的rowData并添加
    NSMutableDictionary *rowdic = [[NSMutableDictionary alloc] init];
    
    [rowdic setObject:cellClassName forKey:@"cell"];
    [rowdic setObject:data forKey:@"data"];
    
    //把rowdic添加到rows的数组里边
    [rows addObject:rowdic];
    
}

- (void)appendDataArray:(NSArray*)dataArr useCell:(NSString*)cellClassName toSection:(NSInteger)section
{
    //极为简单的方法，仅能用于设定一个相同cell的普通列表，可以一次性追加组装一个数组
    if(!dataArr || [dataArr count] == 0) return;
    if(!cellClassName || [cellClassName compare:@""] == NSOrderedSame) return;
    
    for(id rowData in dataArr)
    {
        [self appendData:rowData useCell:cellClassName toSection:section];
    }
}


//插入数据源
- (void)insertData:(id)data useCell:(NSString*)cellClassName toIndexPath:(NSIndexPath*)indexPath
{
    if(!indexPath) return;
    if(!cellClassName || [cellClassName compare:@""] == NSOrderedSame) return;
    if(!data) return;
    
    
    NSMutableDictionary *secDic = [self dictionaryForSection:indexPath.section];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]]) return;
    
    
    //创建这一行的rowData并插入
    NSMutableDictionary *rowdic = [[NSMutableDictionary alloc] init];
    
    [rowdic setObject:cellClassName forKey:@"cell"];
    [rowdic setObject:data forKey:@"data"];
    
    //把rowdic插入到rows的数组里边
    [rows insertObject:rowdic atIndex:indexPath.row];
    
    
    //记录插入的数据源位置
    [_insertArray addObject:indexPath];
}

- (void)insertDataArray:(NSArray*)dataArr useCell:(NSString*)cellClassName belowIndexPath:(NSIndexPath*)indexPath
{
    //极为简单的方法，仅能用于插入相同cell的列表，可以一次性插入一个数组，
    //PS: 必须从indexPath所指定的行下面开始插入，因为一大堆数据插入的话，肯定是要放下面的，所以其他情况不必处理
    if(!dataArr || [dataArr count] == 0) return;
    if(!cellClassName || [cellClassName compare:@""] == NSOrderedSame) return;
    if(!indexPath) return;
    
    NSMutableDictionary *secDic = [self dictionaryForSection:indexPath.section];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]]) return;
    
    
    //插入数据
    NSInteger location = indexPath.row+1;
    if([rows count] == 0) //如果当前的section里边没有数据，就从0开始
    {
        location = 0;
    }
    
    //组装插入数据源字典
    //创建这一行的rowData并插入
    NSMutableArray *insertArray = [[NSMutableArray alloc] init];
    for(id rowData in dataArr)
    {
        NSMutableDictionary *rowdic = [[NSMutableDictionary alloc] init];
        [rowdic setObject:cellClassName forKey:@"cell"];
        [rowdic setObject:rowData forKey:@"data"];
        [insertArray addObject:rowdic];
    }
    
    NSInteger count = [insertArray count];
    [rows insertObjects:insertArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(location, count)]];
    
    //记录插入的数据源位置
    for(int i=0; i<count; i++)
    {
        NSUInteger ints[2] = {indexPath.section, location+i};
        NSIndexPath* newIP = [NSIndexPath indexPathWithIndexes:ints length:2];
        [_insertArray addObject:newIP];
    }
}



//删除数据源
- (void)deleteDataAtIndexPath:(NSIndexPath*)indexPath
{
    if(!indexPath) return;
    if(!_dataArray || [_dataArray count] == 0) return;

    NSString *secPath = [NSString stringWithFormat:@"%d", (int)indexPath.section];
    NSMutableDictionary *secDic = [self valueOfData:_dataArray byPath:secPath];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]]) return;
    if([rows count] == 0) return;
    if(indexPath.row >= [rows count]) return;
    
    
    //移除这一行数据
    [rows removeObjectAtIndex:indexPath.row];
    
    //记录插入的数据源位置
    [_deleteArray addObject:indexPath];
}

- (void)deleteDataArrayByIndexPaths:(NSArray*)indexPathArray
{
    //请注意 indexPathArray 不一定是连续的
    if(!indexPathArray || [indexPathArray count] == 0) return;
    if(!_dataArray || [_dataArray count] == 0) return;
    

    //移除数据源
    //区分section去处理，每个section批量移除数据
    for(int sec=0; sec<[_dataArray count]; sec++)
    {
        NSMutableDictionary *secDic = [_dataArray objectAtIndex:sec];
        NSMutableArray *rows = [secDic objectForKey:@"rows"];
        if(!rows || ![rows isKindOfClass:[NSMutableArray class]] || [rows count] == 0)
        {
            continue;
        }
        
        //有rows数据，找到这个section里边的indexpath对应的数据源，组成一个数组，用于移除
        NSMutableArray *rmvArr = [[NSMutableArray alloc] init];
        
        for(NSIndexPath *ip in indexPathArray)
        {
            if(ip.section == sec)
            {
                NSString *rowPath = [NSString stringWithFormat:@"%d", (int)ip.row];
                NSMutableDictionary *rowDic = [self valueOfData:rows byPath:rowPath];
                if(rowDic)
                {
                    //找到了需要移除的一个数据
                    [rmvArr addObject:rowDic];
                    
                    //位置信息添加到要移除的队列里边
                    [_deleteArray addObject:ip];
                }
            }
        }
        
        //移除数据
        [rows removeObjectsInArray:rmvArr];
    }

}

- (void)deleteDataArray:(NSArray*)dataArr inSection:(NSInteger)section
{
    if(!dataArr || [dataArr count] == 0) return;
    if(!_dataArray || [_dataArray count] == 0) return;
    
    //找到section对应的rows
    NSString *secPath = [NSString stringWithFormat:@"%d", (int)section];
    NSMutableDictionary *secDic = [self valueOfData:_dataArray byPath:secPath];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]] || [rows count] == 0) return;
    
    
    //找到要删除的数据对应的位置队列
    NSMutableArray *indexArray = [[NSMutableArray alloc] init];
    for(id data in dataArr)
    {        
        for(int i=0; i<[rows count]; i++)
        {
            NSDictionary *rowdic = [rows objectAtIndex:i];
            id rowdata = [rowdic objectForKey:@"data"];
            if(rowdata && [rowdata isEqual:data])
            {
                //找到了和当前这个数据相同的位置
                NSIndexPath *addIP = RDIndexPath(section, i);
                
                //排除重复的
                BOOL canAdd = YES;
                for(NSIndexPath *ip in indexArray)
                {
                    if([ip isEqual:addIP])
                    {
                        //已经在队列里了
                        canAdd = NO;
                        break;
                    }
                }
                
                if(canAdd)
                {
                    [indexArray addObject:RDIndexPath(section, i)];
                }
            }
        }

    }
    
    //删除所有的数据
    [self deleteDataArrayByIndexPaths:indexArray];
}






- (void)setSection:(NSInteger)section headerHeight:(float)hHeight footerHeight:(float)fHeight
{
    NSMutableDictionary *secDic = [self dictionaryForSection:section];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableDictionary *secParams = [secDic objectForKey:@"section_params"];
    if(!secParams || ![secParams isKindOfClass:[NSMutableDictionary class]]) return;
    
    
    //设定
    NSString *hHstring = [NSString stringWithFormat:@"%.f", hHeight];
    NSString *fHstring = [NSString stringWithFormat:@"%.f", fHeight];
    
    //有就覆盖，没有就新建存进去
    [secParams setObject:hHstring forKey:@"header_height"];
    [secParams setObject:fHstring forKey:@"footer_height"];
    
}
- (void)setSection:(NSInteger)section headerView:(UIView*)hView footerView:(UIView*)fView
{
    NSMutableDictionary *secDic = [self dictionaryForSection:section];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableDictionary *secParams = [secDic objectForKey:@"section_params"];
    if(!secParams || ![secParams isKindOfClass:[NSMutableDictionary class]]) return;
    
    
    //设定    
    //有就覆盖，没有就移除
    if(hView)
    {
        [secParams setObject:hView forKey:@"header_view"];
    }
    else
    {
        [secParams removeObjectForKey:@"header_view"];
    }
    
    if(fView)
    {
        [secParams setObject:fView forKey:@"footer_view"];
    }
    else
    {
        [secParams removeObjectForKey:@"footer_view"];
    }
        
}



- (void)clearParamsOfSection:(NSInteger)section
{
    //清空某个section的属性设置，但是里边的row数据不变
    if(!_dataArray || [_dataArray count] == 0) return;
    if(section >= [_dataArray count]) return;
    
    NSMutableDictionary *secDic = [self dictionaryForSection:section];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableDictionary *secParams = [secDic objectForKey:@"section_params"];
    if(!secParams || ![secParams isKindOfClass:[NSMutableDictionary class]]) return;
    
    //清空
    [secParams removeAllObjects];

}
- (void)clearDatasOfSection:(NSInteger)section
{
    //清空某个section里边所有的row数据，但是section的属性不变
    if(!_dataArray || [_dataArray count] == 0) return;
    if(section >= [_dataArray count]) return;
    
    NSMutableDictionary *secDic = [self dictionaryForSection:section];
    if(!secDic || ![secDic isKindOfClass:[NSMutableDictionary class]]) return;
    
    NSMutableArray *rows = [secDic objectForKey:@"rows"];
    if(!rows || ![rows isKindOfClass:[NSMutableArray class]]) return;
    
    //清空
    [rows removeAllObjects];
}

- (void)clearTableDatasAndParams
{
    //清空所有的数据
    if(!_dataArray || [_dataArray count] == 0) return;
    
    [_dataArray removeAllObjects];
}

- (void)clearDatas
{
    //清空所有section的Row的数据，但是section所设定的属性不变
    if(!_dataArray || [_dataArray count] == 0) return;
    
    //清空所有插入和删除队列
    [_insertArray removeAllObjects];
    [_deleteArray removeAllObjects];
    
    for(int i=0; i<[_dataArray count]; i++)
    {
        [self clearDatasOfSection:i];
    }
}




- (void)refreshTable:(void(^)(void))completion
{
    //使用前面封装好的数据源刷新页面，必须做的工作
    //if(!_dataArray || [_dataArray count] == 0) return;
    
    //刷新列表
	[_tableView reloadData];

    //关闭loading等待状态及标志
    [self doneLoading];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{  
        //刷新完成，执行后续代码 
        
        //强制更新列表高度
        [self.tableView layoutIfNeeded];
        
        
        //判断并添加加载更多和刷新部分的view
        if(self.loadMoreStyle == LoadMoreStyleNone)
        {
            self.tableView.tableFooterView = nil;
        }
        else if(self.loadMoreStyle == LoadMoreStyleLoading || self.loadMoreStyle == LoadMoreStyleNomore)
        {
            CGSize  cntSize = self.tableView.contentSize;
            CGRect  frect   = self.tableView.frame;
            
            //NSLog(@"高度：%f", cntSize.height);
            
            if(cntSize.height < frect.size.height)
            {
                //还不够table一屏显示的，就不显示加载更多了
                self.tableView.tableFooterView = nil;
            }
            else
            {
                //超过了一屏，再显示
                self.tableView.tableFooterView = self.moreLoadingView;
            }
        }
        
        
        //添加刷新部分view
        if(self.refreshStyle == RefreshStyleNone)
        {
            if(self.refreshControll && [self.refreshControll superview])
            {
                [self removeKVOfromRefresh];
                [self.refreshControll removeFromSuperview];
            }
        }
        else if(self.refreshStyle == RefreshStyleDropdown)
        {
            if(self.refreshControll)
            {
                if(![self.refreshControll superview])
                {                
                    [self.tableView addSubview:self.refreshControll];
                }
            }
        }
        
        
        //返回刷新完成状态
        if(completion)
        {
            completion();
        }
    }); 
    
}

- (void)refreshTableWithAnimation:(UITableViewRowAnimation)animation completion:(void(^)(void))completion
{
    [self doneLoading];
    
    if([_insertArray count] != 0)
    {
        [_tableView beginUpdates];
        [_tableView insertRowsAtIndexPaths:_insertArray withRowAnimation:animation];
        [_tableView endUpdates];
        
        [_insertArray removeAllObjects];
    }
    else if([_deleteArray count] != 0)
    {
        [_tableView beginUpdates];
        [_tableView deleteRowsAtIndexPaths:_deleteArray withRowAnimation:animation];
        [_tableView endUpdates];
        
        [_deleteArray removeAllObjects];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{  
        //刷新完成，执行后续代码 
        
        //强制更新列表高度
        [self.tableView layoutIfNeeded];

        //返回刷新完成状态
        if(completion)
        {
            completion();
        }
    }); 
    
}





#pragma mark -
#pragma mark 一些类方法
+ (NSIndexPath*)indexPathWithSection:(NSInteger)section row:(NSInteger)row
{
    NSUInteger ints[2] = {section, row};
	NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
    return indexPath;
}



@end
