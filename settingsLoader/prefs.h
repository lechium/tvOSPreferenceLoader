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

@interface NSArray (reverse)
- (NSArray *)reverseArray;
@end
@interface UIView (RecursiveFind)
- (NSArray *)siblingsInclusive:(BOOL)include;// inclusive means we include ourselves as well
- (BOOL)darkMode;
- (UIView *)findFirstSubviewWithClass:(Class)theClass;
- (void)removeAllSubviews;
@end

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

@interface TSKSettingGroup (lazyItems)
- (void)addSettingItem:(TSKSettingItem *)item;
@end

@interface TSKSettingItem (preferenceLoader)
+ (BOOL)environmentPassesPreferenceLoaderFilter:(NSDictionary *)filter;
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

@interface PLCustomListViewController: TSKViewController

@property (nonatomic, strong) NSDictionary *rootPlist;
@property (nonatomic, strong) NSString *ourDomain;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) UIImage *ourIcon;

- (void)relaunchBackboardd;
- (void)showMissingActionAlert;
@end
