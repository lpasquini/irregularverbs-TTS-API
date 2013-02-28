//
//  ALOVDocument.h
//  aListOfVerbsManager
//
//  Created by Oswaldo Rubio on 06/01/13.
//  Copyright (c) 2013 Oswaldo Rubio. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>


@interface ALOVDocument : NSDocument<AVAudioPlayerDelegate>
{
 
    NSMutableArray *verbsItems;
    IBOutlet NSTableView *itemTableView;
    NSArray *keysOfVerbs;
 
}
@property (strong, nonatomic)  NSMutableDictionary *verbsSounds;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
- (IBAction)playSelected:(id)sender;
@property (weak) IBOutlet NSButton *getSpeechButton;
 
- (IBAction)getSpeech:(id)sender;
-(IBAction)createNewItem:(id)sender;
@end
