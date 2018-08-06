//
//  TVSettingsTweakViewController.m
//  nitoTV4
//
//  Created by Kevin Bradley on 7/28/18.
//  Copyright © 2018 nito. All rights reserved.
//

/*

This is where a lot of the 'magic' happens specifiersFromEntry:sourcePreferenceLoaderBundlePath:title is pulled straight 
from the iOS version of preferenceloader with some things trimmed out or commented out that cant or wont be reused.

preferenceBundleGroups is called by loadSettingGroups which is the initial entry point for everything.

*/


#import "TVSettingsTweakViewController.h"
#import "TSKTextInputViewController.h"
/**

Add an itemIcon for TSKSettingItem, this is a lazy convenience to make it easier to set icons per item
There is a likely a more elegant and proper way to do this, but it works for now and wont hurt anything.

*/

@implementation TSKViewController (science)

- (NSArray *)menuItemsFromItems:(NSArray *)items {
    /* these plists are kind of dumb imo, you need to loop through the items but the way you dilineate groups is they start and stop when the next group is found.
    
    ie Group 1 | Item 1 | Item 2 | Group 2 | Item 3 | Item 4 | Group 3 ... so item 1&2 would be in group 1, 3 & 4 in Group 2 etc..
*/
    
    __block NSMutableArray *groups = [NSMutableArray new];
    __block NSString *currentGroupName = nil;
    __block NSMutableArray *currentGroupItems = [NSMutableArray new];
	__block BOOL haveGroups = FALSE;
    [items enumerateObjectsUsingBlock:^(NSDictionary  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
	    NSString *cell = obj[@"cell"];
        NSString *label = obj[@"label"];
		
        if ([cell isEqualToString:@"PSGroupCell"]){
            
			if (currentGroupItems.count < 1){ //we might not have any group items yet!
				currentGroupName = label;
				NSLog(@"no groups yet, starting with group name: %@", label);
				haveGroups = TRUE;

			} else {
				
				NSLog(@"we already have a group: %@ adding items %@", currentGroupName, currentGroupItems);
				TSKSettingGroup *groupItem = [TSKSettingGroup groupWithTitle:currentGroupName settingItems:currentGroupItems];
            	[groups addObject:groupItem];
				currentGroupName = label;
				NSLog(@"starting a new group: %@", currentGroupName);
				[currentGroupItems removeAllObjects];
			}
         
            
            
        } else if ([cell isEqualToString:@"PSSwitchCell"]){
            
	 		NSString *key = obj[@"key"];
            NSString *label = obj[@"label"];
			NSString *description = obj[@"description"];
            BOOL isDefault = [obj[@"default"] boolValue];
			id facade = nil;
            if (isDefault) {
                
                NSString *domain = obj[@"defaults"];
                NSString *postNotification = obj[@"PostNotification"];
				facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:domain notifyChanges:TRUE];
 			

            }
            
			TSKSettingItem *settingsItem = [TSKSettingItem toggleItemWithTitle:label description:description representedObject:facade keyPath:key onTitle:nil offTitle:nil];
			//NSLog(@"created settings item: %@", settingsItem);

			[currentGroupItems addObject:settingsItem];
            //NSLog(@"currentGroupItems: %@", currentGroupItems);
        
        } else if ([cell isEqualToString:@"PSEditTextCell"]) {
        
			NSString *key = obj[@"key"];
            NSString *label = obj[@"label"];
			NSString *description = obj[@"description"];
			NSString *domain = obj[@"defaults"];
            BOOL isDefault = [obj[@"default"] boolValue];
        	id facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:domain notifyChanges:TRUE];
 		    TSKSettingItem *textEntryItem = [TSKSettingItem actionItemWithTitle:label description:description representedObject:facade keyPath:key target:self action:@selector(showTextFieldControllerForItem:)];
   		    [textEntryItem setKeyboardDetails:obj];
            [currentGroupItems addObject:textEntryItem];
            
        } else if ([cell isEqualToString:@"PSMultiItemCell"]) {

			NSString *key = obj[@"key"];
            NSString *label = obj[@"label"];
			NSString *description = obj[@"description"];
			NSString *domain = obj[@"defaults"];
            BOOL isDefault = [obj[@"default"] boolValue];
			NSArray *availableValues = obj[@"availableValues"];
			id facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:domain notifyChanges:TRUE];
			TSKSettingItem *multiItem = [TSKSettingItem multiValueItemWithTitle:label description:description representedObject:facade keyPath:key availableValues:availableValues];

 		    [currentGroupItems addObject:multiItem];

		}
    }];
    if (haveGroups == TRUE && groups.count == 0) {

			TSKSettingGroup *groupItem = [TSKSettingGroup groupWithTitle:currentGroupName settingItems:currentGroupItems];
            [groups addObject:groupItem];
				

	}

    return groups;
}



@end

@implementation TSKSettingItem (lazyIcons) 

- (NSDictionary *)keyboardDetails {

	   return objc_getAssociatedObject(self, @selector(keyboardDetails));
}

- (void)setKeyboardDetails:(NSDictionary *)keyboardDetails {
    objc_setAssociatedObject(self, @selector(keyboardDetails), keyboardDetails, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (UIImage *)itemIcon
{
    return objc_getAssociatedObject(self, @selector(itemIcon));
}

- (void)setItemIcon:(UIImage *)itemIcon {
    objc_setAssociatedObject(self, @selector(itemIcon), itemIcon, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface PLCustomListViewController: TSKViewController

@property (nonatomic, strong) NSDictionary *rootPlist;
@property (nonatomic, strong) NSString *ourDomain;
@property (nonatomic, strong) NSArray *menuItems;
@property (nonatomic, strong) UIImage *ourIcon;

- (void)showTextFieldControllerForItem:(TSKSettingItem *)item;

@end

@implementation PLCustomListViewController

- (TVSPreferences *)ourPreferences {
    
    return [TVSPreferences preferencesWithDomain:self.ourDomain];
}

- (id)loadSettingGroups
{
    NSMutableArray *_backingArray = [NSMutableArray new];
	NSArray *items = [self menuItemsFromItems:self.menuItems];
    [_backingArray addObjectsFromArray:items];
	[self setValue:_backingArray forKey:@"_settingGroups"];
    
    return _backingArray;
    
}

- (id)loadSettingGroups2 {

	NSLog(@"PLCustomListViewController:loadSettingGroups: %@", self.menuItems);
	id items = [super loadSettingGroups];
	[self setValue:self.menuItems forKey:@"_settingGroups"];
	return self.menuItems;

}

- (void)showTextFieldControllerForItem:(TSKSettingItem *)item {
    
    //NSLog(@"PrefLoader: showTextFieldControllerForItem: %@", item );
    
	NSDictionary *obj = [item keyboardDetails];
	//NSLog(@"obj: %@", obj);
	NSString *label = obj[@"label"];
	NSString *defaults = obj[@"defaults"];
	[self setOurDomain:defaults];
    /*
	NSString *keyboard = obj[@"keyboard"];
    NSString *autoCaps = obj[@"autoCaps"];
	NSString *placeholder = obj[@"placeholder"];
    NSString *suffix = obj[@"suffix"];
    NSString *bestGuess = obj[@"bestGuess"];
    BOOL noAutoCorrect = [obj[@"noAutoCorrect"] boolValue];
    BOOL isIP = [obj[@"isIP"] boolValue];
    BOOL isURL = [obj[@"isURL"] boolValue];
	BOOL isNumeric = [obj[@"isNumeric"] boolValue];
    BOOL isDecimalPad = [obj[@"isDecimalPad"] boolValue];
    BOOL isEmail = [obj[@"isEmail"] boolValue];
	NSString *okTitle = obj[@"okTitle"];
    NSString *cancelTitle = obj[@"cancelTitle"];
*/
	TSKTextInputViewController *textInputViewController = [[TSKTextInputViewController alloc] init];
    textInputViewController.headerText = label;
    textInputViewController.initialText = [[self ourPreferences] stringForKey:item.keyPath];
    if ([textInputViewController respondsToSelector:@selector(setEditingDelegate:)]){
        
        [textInputViewController setEditingDelegate:self];
    }
    [textInputViewController setEditingItem:item];
    [self.navigationController pushViewController:textInputViewController animated:TRUE];
}

- (void)editingController:(id)arg1 didCancelForSettingItem:(TSKSettingItem *)arg2 {
    
    //NSLog(@"PrefLoader: editingController %@ didCancelForSettingItem:%@", arg1, arg2);
    [super editingController:arg1 didCancelForSettingItem:arg2];
}
- (void)editingController:(id)arg1 didProvideValue:(id)arg2 forSettingItem:(TSKSettingItem *)arg3 {
    
    //NSLog(@"PrefLoader: editingController %@ didProvideValue: %@ forSettingItem: %@", arg1, arg2, arg3);
 
    [super editingController:arg1 didProvideValue:arg2 forSettingItem:arg3];
 
	if (self.ourDomain != nil){
    	//NSLog(@"PrefLoader: prefs: %@", prefs);
    	//[arg3 setLocalizedValue:arg2];
    	[[self ourPreferences] setObject:arg2 forKey:arg3.keyPath];
    	[[self ourPreferences] synchronize];
	}
}

-(id)previewForItemAtIndexPath:(NSIndexPath *)indexPath {


	TSKPreviewViewController *previewItem = [super previewForItemAtIndexPath:indexPath];
/*
	TSKSettingGroup *currentGroup = self.settingGroups[indexPath.section];
	TSKSettingItem *currentItem = currentGroup.settingItems[indexPath.row];
	UIImage *icon = [currentItem itemIcon];
	*/
	UIImage *icon = [self ourIcon];
	if (icon != nil) {
		TSKVibrantImageView *imageView = [[TSKVibrantImageView alloc] initWithImage:icon];
		[previewItem setContentView:imageView];
	}
	//NSLog(@"previewForItemAtIndexPath: %@", previewItem);
	return previewItem;

}


@end



@interface TVSettingsTweakViewController() {

	NSMutableArray *_iconArray; //currently unused, likey to be pruned out

}

@end



@implementation TVSettingsTweakViewController

//initial entry point for any type of TSKViewController (which we inherit from)

- (id)loadSettingGroups {
    
	if (_iconArray) {
		[_iconArray removeAllObjects];
		_iconArray	= nil;
	}

	_iconArray = [NSMutableArray new];

    NSMutableArray *_backingArray = [NSMutableArray new];
    NSArray *prefBundleGroups = [self preferenceBundleGroups];
    //NSLog(@"prefBundleGroups: %@", prefBundleGroups);
    if (prefBundleGroups.count > 0) {
        TSKSettingGroup *group = [TSKSettingGroup groupWithTitle:nil settingItems:prefBundleGroups];
        [_backingArray addObject:group];
		//property is read only, so maybe we really should be overriding settingsGroup property instead... more thought needed.
        [self setValue:_backingArray forKey:@"_settingGroups"];
    }
    
    
    return _backingArray;
    
}

//search through /Library/PreferenceLoader/Preferences for entries to add, currently is only supporting adding to Tweaks menu item

- (NSArray *)preferenceBundleGroups {

    NSMutableArray *allTheSpecs = [NSMutableArray new];

	NSString *preferencesPath = @"/Library/PreferenceLoader/Preferences";

	NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:preferencesPath error:NULL];
		for(NSString *item in subpaths) {
			if(![[item pathExtension] isEqualToString:@"plist"]) continue;
			NSLog(@"processing %@", item);
			NSString *fullPath = [NSString stringWithFormat:@"/Library/PreferenceLoader/Preferences/%@", item];
			NSDictionary *plPlist = [NSDictionary dictionaryWithContentsOfFile:fullPath];
			//if(![PSSpecifier environmentPassesPreferenceLoaderFilter:[plPlist objectForKey:@"filter"] ?: [plPlist objectForKey:PLFilterKey]]) continue;

			NSDictionary *entry = [plPlist objectForKey:@"entry"];
			if(!entry) continue;
			NSLog(@"found an entry key for %@!", item);

            //TODO: Add support for specifier filtering.
			//if(![PSSpecifier environmentPassesPreferenceLoaderFilter:[entry objectForKey:PLFilterKey]]) continue;

			NSArray *specs = [self specifiersFromEntry:entry sourcePreferenceLoaderBundlePath:[fullPath stringByDeletingLastPathComponent] title:[[item lastPathComponent] stringByDeletingPathExtension]];
			if(specs.count > 0) {

				NSLog(@"appending to the array!");

            	[allTheSpecs addObjectsFromArray:specs];
			} else { //there isnt a bundle
				NSString *label = entry[@"label"];
				NSArray *items = plPlist[@"items"];
				NSString *iconPath = entry[@"icon"];
				NSString *description = entry[@"description"];
				NSLog(@"items: %@", items);

				NSLog(@"creating menu items!!");
				NSLog(@"icon: %@", iconPath);
				NSString *fullIconPath = [preferencesPath stringByAppendingPathComponent:iconPath];
				UIImage *image = [UIImage imageWithContentsOfFile:fullIconPath];
				NSLog(@"fullIconPath: %@", fullIconPath);
				NSLog(@"image: %@", image);
				//NSArray *specs = [self menuItemsFromItems:items];
				//NSLog(@"created menu items: %@", specs);
				
				TSKSettingItem *settingsItem = [TSKSettingItem childPaneItemWithTitle:label description:description representedObject:nil keyPath:nil childControllerBlock:^(id object) {
        
					NSLog(@"self: %@ object: %@", self, object);
					//NSLog(@"still have menu items?: %@", specs);
					PLCustomListViewController *controller = [PLCustomListViewController new];
					if (image){
						[controller setOurIcon:image];
					}
					//
					[controller setMenuItems:items];
					return controller;
   				}];
				[settingsItem setItemIcon:image];
				[allTheSpecs addObject:settingsItem];
				NSLog(@"made item: %@", settingsItem);
				//description:(id)arg2 representedObject:(id)arg3 keyPath:(id)arg4 childControllerBlock:((void(^childControllerBlock)(id object))completionBlock
			}
		}
    return allTheSpecs;
}


/*

 plucked straight from iOS version in prefs.xm, this will return the TSKSettingItem that will get added to our list

NOTE: currently only supports bundles loading custom code, its on the todo to get the easier plist style lists working too


*/

 - (NSArray *)specifiersFromEntry:(NSDictionary *)entry sourcePreferenceLoaderBundlePath:(NSString *)sourceBundlePath title:(NSString *)title {

	//NSDictionary *specifierPlist = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:entry, nil], @"items", nil];

	BOOL isBundle = [entry objectForKey:@"bundle"] != nil;
	//BOOL isLocalizedBundle = ![[sourceBundlePath lastPathComponent] isEqualToString:@"Preferences"];

	NSBundle *prefBundle;
	NSString *bundleName = entry[@"bundle"];
	NSString *bundlePath = entry[@"bundlePath"];
  
	if(isBundle) {
		// Second Try (bundlePath key failed)
		if(![[NSFileManager defaultManager] fileExistsAtPath:bundlePath])
			bundlePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle", bundleName];

		// Third Try (/Library failed)
		if(![[NSFileManager defaultManager] fileExistsAtPath:bundlePath])
			bundlePath = [NSString stringWithFormat:@"/System/Library/PreferenceBundles/%@.bundle", bundleName];

		// Really? (/System/Library failed...)
		if(![[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
			NSLog(@"Discarding specifier for missing isBundle bundle %@.", bundleName);
			return nil;
		}
		prefBundle = [NSBundle bundleWithPath:bundlePath];
		NSLog(@"is a bundle: %@!", prefBundle);
	} else {
		prefBundle = [NSBundle bundleWithPath:sourceBundlePath];
		NSLog(@"is NOT a bundle, so we're giving it %@!", prefBundle);
	}


    //entry.plist looks something like this

	/*

		<key>bundle</key>
		<string>DDBSettings</string>
		<key>cell</key>
		<string>PSLinkCell</string>
		<key>detail</key>
		<string>DDBSettingsController</string>
		<key>icon</key>
		<string>icon.png</string>
		<key>isController</key>
		<true/>
		<key>label</key>
		<string>Dales Dead Bug</string>
		<key>description</key>
		<string>Dales Dead Bug</string>

	*/

//ios version, the Preferences framework doesn't appear to even be loaded, even though its linked. its odd.
//tvOS doesn't really seem to use PSSpecifiers at all as far as i can tell, so it'll be hard to do EXACTLY 1:1

	//NSMutableArray *bundleControllers = [self valueForKey:@"_bundleControllers"];//MSHookIvar<NSMutableArray *>(self, "_bundleControllers");
	//NSArray *specs = SpecifiersFromPlist(specifierPlist, nil, _Firmware_lt_60 ? [self rootController] : self, title, prefBundle, NULL, NULL, (PSListController*)self, &bundleControllers);
	//NSLog(@"loaded specifiers!");

	//if([specs count] == 0) return nil;

    NSMutableArray *items = [NSMutableArray  new];

    //old comment nothing is confirmed yet, heh
	//NSLog(@"It's confirmed! There are Specifiers here, Captain!");

	if(isBundle) {
        
        NSLog(@"we got a bundle!");

		 // Only set lazy-bundle for isController specifiers.
		if([[entry objectForKey:@"isController"] boolValue]) {
			
            	NSLog(@"creating TSKSettingItems!");

  	            NSString *principalClassKey = entry[@"detail"];
	            NSString *iconKey = entry[@"icon"]; //currently unused, need to figure out how im going to make this work
                NSString *labelKey = entry[@"label"];
	            NSString *descriptionKey = entry[@"description"]; //note part of original spec, custom addition.
				//load the bundle so we can get access to the class
                [prefBundle load];

			    //all items are going to be child panel items for now which allow use to load another class that gives us our groups from said tweak
                TSKSettingItem *item = [TSKSettingItem childPaneItemWithTitle:labelKey description:descriptionKey representedObject:nil keyPath:nil childControllerClass:NSClassFromString(principalClassKey)];
                
				//this does the magic of loading the class from the bundle
				TSKBundleLoader *bundleLoader = [[TSKBundleLoader alloc] initWithBundle:prefBundle];
                [item setBundleLoader:bundleLoader];
				
				NSLog(@"iconKey: %@", iconKey);

				NSString *iconPath = [bundlePath stringByAppendingPathComponent:iconKey];
				//NSString *iconPath =[[NSBundle mainBundle] pathForResource:[iconKey stringByDeletingPathExtension] ofType:[iconKey pathExtension]];
                
				NSLog(@"iconPath: %@", iconPath);
				UIImage *image = [UIImage imageWithContentsOfFile:iconPath];
				NSLog(@"image: %@", image);
				[item setItemIcon:image];
				NSLog(@"item: %@", item);
                [items addObject:item];

			//old iOS code, tvOS doesn't appear to ever use specifiers, in for posterity but will be pruned out eventually
            /*
            for(PSSpecifier *specifier in specs) {
				[specifier setProperty:bundlePath forKey:PSLazilyLoadedBundleKey];
				[specifier setProperty:[NSBundle bundleWithPath:sourceBundlePath] forKey:PLBundleKey];
				if(!specifier.name) {
					specifier.name = title;
				}
			}
            */
		}
	} else {
	
        NSLog(@"not a bundle! this feature is currently unsupported entry: %@ path: %@", entry, prefBundle);

    /*
    	// There really should only be one specifier.
		PSSpecifier *specifier = [specs objectAtIndex:0];
		if (isLocalizedBundle) {
			[specifier setValue:[PLLocalizedListController class] forKey:@"detailControllerClass"];
		} else {
			[specifier setValue:[PLCustomListController class] forKey:@"detailControllerClass"];
		}
		//MSHookIvar<Class>(specifier, "detailControllerClass") = isLocalizedBundle ? [PLLocalizedListController class] : [PLCustomListController class];
		[specifier setProperty:prefBundle forKey:PLBundleKey];

		if(![[specifier propertyForKey:PSTitleKey] isEqualToString:title]) {
			[specifier setProperty:title forKey:PLAlternatePlistNameKey];
			if(!specifier.name) {
				specifier.name = title;
			}
		}
        */
	}

	return items;
}

/*
- (NSArray *)menuItemsFromItems:(NSArray *)items {
    
    __block NSMutableArray *groups = [NSMutableArray new];
    __block NSString *currentGroupName = nil;
    __block NSMutableArray *currentGroupItems = [NSMutableArray new];
    [items enumerateObjectsUsingBlock:^(NSDictionary  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
	   NSLog(@"processing objectL %@", obj);

        NSString *cell = obj[@"cell"];
        NSString *label = obj[@"label"];
		
        if ([cell isEqualToString:@"PSGroupCell"]){
            
			if (currentGroupItems.count < 1){ //we might not have any group items yet!
				currentGroupName = label;
				NSLog(@"no groups yet, starting with group name: %@", label);
				

			} else {
				
				NSLog(@"we already have a group: %@ adding items %@", currentGroupName, currentGroupItems);
				TSKSettingGroup *groupItem = [TSKSettingGroup groupWithTitle:currentGroupName settingItems:currentGroupItems];
            	[groups addObject:groupItem];
				currentGroupName = label;
				NSLog(@"starting a new group!", currentGroupName);
				[currentGroupItems removeAllObjects];
			}
         
            
            
        } else if ([cell isEqualToString:@"PSSwitchCell"]){
            
	 		NSString *key = obj[@"key"];
            NSString *label = obj[@"label"];
			NSString *description = obj[@"description"];
            BOOL isDefault = [obj[@"default"] boolValue];
			id facade = nil;
            if (isDefault) {
                
                NSString *domain = obj[@"defaults"];
                NSString *postNotification = obj[@"PostNotification"];
				facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:domain notifyChanges:TRUE];
 			

            }
            
			TSKSettingItem *settingsItem = [TSKSettingItem toggleItemWithTitle:label description:description representedObject:facade keyPath:key onTitle:nil offTitle:nil];
			NSLog(@"created settings item: %@", settingsItem);

			[currentGroupItems addObject:settingsItem];
            NSLog(@"currentGroupItems: %@", currentGroupItems);
        
        } else if ([cell isEqualToString:@"PSEditTextCell"]) {
        
			NSString *key = obj[@"key"];
            NSString *label = obj[@"label"];
			NSString *description = obj[@"description"];
			NSString *domain = obj[@"defaults"];
            BOOL isDefault = [obj[@"default"] boolValue];
            NSString *keyboard = obj[@"keyboard"];
            NSString *autoCaps = obj[@"autoCaps"];
            NSString *placeholder = obj[@"placeholder"];
            NSString *suffix = obj[@"suffix"];
            NSString *bestGuess = obj[@"bestGuess"];
            BOOL noAutoCorrect = [obj[@"noAutoCorrect"] boolValue];
            BOOL isIP = [obj[@"isIP"] boolValue];
            BOOL isURL = [obj[@"isURL"] boolValue];
            BOOL isNumeric = [obj[@"isNumeric"] boolValue];
            BOOL isDecimalPad = [obj[@"isDecimalPad"] boolValue];
            BOOL isEmail = [obj[@"isEmail"] boolValue];
            NSString *okTitle = obj[@"okTitle"];
            NSString *cancelTitle = obj[@"cancelTitle"];

		    NSLog(@"DDBSettings: main bundle: %@", [NSBundle bundleForClass:self.class]);
   
			id facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:domain notifyChanges:TRUE];
 		    TSKSettingItem *textEntryItem = [TSKSettingItem actionItemWithTitle:label description:description representedObject:facade keyPath:key target:self action:@selector(showViewController:)];
   		    [textEntryItem setLocalizedValue:@"TEST"]; 
           
            [currentGroupItems addObject:settingsItem];
            
        }
    }];
    

    return groups;
}
*/

-(id)previewForItemAtIndexPath:(NSIndexPath *)indexPath {

	TSKPreviewViewController *previewItem = [super previewForItemAtIndexPath:indexPath];
	TSKSettingGroup *currentGroup = self.settingGroups[indexPath.section];
	TSKSettingItem *currentItem = currentGroup.settingItems[indexPath.row];
	//NSBundle *currentBundle = currentItem.bundleLoader.bundle;
	//NSLog(@"currentBundle: %@", currentBundle);
	//added a category to make item icons easier to get and set per item.
	UIImage *icon = [currentItem itemIcon];
	if (icon != nil) {
		TSKVibrantImageView *imageView = [[TSKVibrantImageView alloc] initWithImage:icon];
		[previewItem setContentView:imageView];
	}
	//NSLog(@"previewForItemAtIndexPath: %@", previewItem);
	return previewItem;

}


@end
