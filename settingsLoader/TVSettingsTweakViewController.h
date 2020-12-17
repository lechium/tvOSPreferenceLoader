//
//  TVSettingsTweakViewController.h
//  nitoTV4
//
//  Created by Kevin Bradley on 7/28/18.
//  Copyright © 2018 nito. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <TVSettingKit/TVSettingKit.h>
#import <objc/runtime.h>
#import "TVSettingsPreferenceFacade.h"
#import "TVSettingsItemFactory.h"
#import "UIView+RecursiveFind.h"
@interface TSKTableViewController (preferenceLoader)
- (NSArray *)tableViewCells;
- (UITableViewCell *)cellFromSettingsItem:(TSKSettingItem *)settingsItem;
@end


@interface TSKSettingGroup (lazyItems)

- (void)addSettingItem:(TSKSettingItem *)item;

@end

@interface TVSettingsTweakViewController : TSKViewController

@property (nonatomic, strong) UIImage *defaultImage;

@end

@interface TSKSettingItem (lazyIcons) 


@property (nonatomic, strong) NSDictionary *keyboardDetails; 
@property (nonatomic, strong) UIImage *itemIcon;

@end

@interface TSKViewController (science)

- (NSArray *)menuItemsFromItems:(NSArray *)items;

@end
