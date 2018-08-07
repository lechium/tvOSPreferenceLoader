//
//  TVSettingsTweakViewController.h
//  nitoTV4
//
//  Created by Kevin Bradley on 7/28/18.
//  Copyright © 2018 nito. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "TSKSettingItem.h"
#import "TSKSettingGroup.h"
#import "TSKVibrantImageView.h"
#import "TSKPreviewViewController.h"
#import "TSKBundleLoader.h"
#import "TSKTableViewController.h"
#import "TSKViewController.h"
#import <objc/runtime.h>
#import "TVSettingsPreferenceFacade.h"
#import "TVSettingsItemFactory.h"

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
