//
//  TVSettingsTweakViewController.m
//  nitoTV4
//
//  Created by Kevin Bradley on 7/28/18.
//  Copyright © 2018 nito. All rights reserved.
//

/*

This is where a lot of the 'magic' happens specifiersFromEntry:sourcePreferenceLoaderBundlePath


*/


#import "TVSettingsTweakViewController.h"

@implementation TVSettingsTweakViewController

//static NSMutableArray *_loadedSpecifiers = nil;
//static NSInteger _extraPrefsGroupSectionID = 0;


 - (NSArray *)specifiersFromEntry:(NSDictionary *)entry sourcePreferenceLoaderBundlePath:(NSString *)sourceBundlePath title:(NSString *)title {

	NSDictionary *specifierPlist = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:entry, nil], @"items", nil];

	BOOL isBundle = [entry objectForKey:@"bundle"] != nil;
	BOOL isLocalizedBundle = ![[sourceBundlePath lastPathComponent] isEqualToString:@"Preferences"];

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

    //nothing is confirmed yet heh
	//NSLog(@"It's confirmed! There are Specifiers here, Captain!");

	if(isBundle) {
        
        NSLog(@"we got a bundle!");

		 // Only set lazy-bundle for isController specifiers.
		if([[entry objectForKey:@"isController"] boolValue]) {
			
            	NSLog(@"loading specifiers!");

  	            NSString *principalClassKey = entry[@"detail"];
	            NSString *iconKey = entry[@"icon"];
                NSString *labelKey = entry[@"label"];
	            NSString *descriptionKey = entry[@"description"];
                [prefBundle load];
                TSKSettingItem *item = [TSKSettingItem childPaneItemWithTitle:labelKey description:descriptionKey representedObject:nil keyPath:nil childControllerClass:NSClassFromString(principalClassKey)];
                TSKBundleLoader *bundleLoader = [[TSKBundleLoader alloc] initWithBundle:prefBundle];
                [item setBundleLoader:bundleLoader];

                NSLog(@"item: %@", item);
                [items addObject:item];


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
	
        NSLog(@"not a bundle! this feature is currently unsupported");

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

//search through /Library/PreferenceLoader/Preferences for entries to add, currently is only supporting adding to Tweaks menu item

- (NSArray *)preferenceBundleGroups {

    NSMutableArray *allTheSpecs = [NSMutableArray new];
	NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:@"/Library/PreferenceLoader/Preferences" error:NULL];
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
			if(!specs) continue;

			NSLog(@"appending to the array!");

            [allTheSpecs addObjectsFromArray:specs];
		}
    return allTheSpecs;
}


- (id)loadSettingGroups {
    
    NSMutableArray *_backingArray = [NSMutableArray new];
    NSArray *prefBundleGroups = [self preferenceBundleGroups];
    NSLog(@"prefBundleGroups: %@", prefBundleGroups);
    if (prefBundleGroups.count > 0) {
        TSKSettingGroup *group = [TSKSettingGroup groupWithTitle:nil settingItems:prefBundleGroups];
        [_backingArray addObject:group];
        [self setValue:_backingArray forKey:@"_settingGroups"];
    }
    
    
    return _backingArray;
    
}

@end