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
#import "PLCustomListViewController.h"

@interface UINavigationController (convenience)
- (TSKTableViewController *)previousViewController;
@end

@interface NSBundle (additions)
+(NSBundle *)bundleWithName:(NSString *)path;
@end

@interface UIViewController (clean_warning)
- (id)defaultPreviewViewController; //doesnt exist in UIViewController but it will always exist for us i believe
+ (id)defaultPreviewViewController;
@end

@interface TSKTableViewController (preferenceLoader)
- (NSArray *)tableViewCells;
- (UITableViewCell *)cellFromSettingsItem:(TSKSettingItem *)settingsItem;
@end

@interface TSKSettingGroup (libprefs)
+ (BOOL)environmentPassesPreferenceLoaderFilter:(NSDictionary *)filter;
@end

@interface TSKSettingGroup (lazyItems)
- (void)addSettingItem:(TSKSettingItem *)item;
@end

@interface TSKSettingItem (preferenceLoader)
@property (nonatomic, strong) TSKPreviewViewController *previewViewController;
@property (nonatomic, strong) id controller;
@property (nonatomic, strong) NSDictionary *specifier;
@end

@interface TSKSettingItem (lazyIcons)
@property (nonatomic, strong) NSDictionary *keyboardDetails;
@property (nonatomic, strong) UIImage *itemIcon;
@end

@interface TSKViewController (science)
- (NSArray *)menuItemsFromItems:(NSArray *)items;
@end


@interface TVSettingsTweakViewController : TSKViewController

@property (nonatomic, strong) UIImage *defaultImage;

@end

