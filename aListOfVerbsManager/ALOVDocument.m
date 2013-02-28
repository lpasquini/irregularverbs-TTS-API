//
//  ALOVDocument.m
//  aListOfVerbsManager
//
//  Created by Oswaldo Rubio on 06/01/13.
//  Copyright (c) 2013 Oswaldo Rubio. All rights reserved.
//

#import "ALOVDocument.h"

 
@implementation ALOVDocument

#pragma mark Document overrides
- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        keysOfVerbs = @[@"simple",@"past",@"participle"];
         
    }
    return self;
}
-(NSMutableDictionary *)verbsSounds{
    if(!_verbsSounds){
        _verbsSounds = [[NSMutableDictionary alloc] init];
    }
    return _verbsSounds;
}
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ALOVDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if(!verbsItems){
        verbsItems = [NSMutableArray array];
        
    }
    NSData *data= [NSPropertyListSerialization dataWithPropertyList:verbsItems format:NSPropertyListXMLFormat_v1_0 options:0 error:outError];
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    
    
     verbsItems = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:NULL error:outError];
    return (verbsItems !=nil);
}

-(NSMutableSet *) getSingularTextFromVerbs{
    
    NSMutableSet *returnSet = [[NSMutableSet alloc] init];
    for(int row=0;row< [verbsItems count];row++){
        for(int col =0;col <[keysOfVerbs count];col++){
            NSString *valueString =  [[verbsItems objectAtIndex:row] objectForKey:keysOfVerbs[col]];
            [returnSet addObject:valueString];
            
        }
    }
    return  returnSet;
}

#pragma mark - Actions

#define SPEECH_API_URL @"http://tts-api.com/tts.mp3?q=%@"



- (IBAction)playSelected:(id)sender {
    if([itemTableView selectedRow] >= 0){
    NSString *simpleString =   [[verbsItems objectAtIndex:[itemTableView selectedRow]] valueForKey:@"simple"];;
    
    NSError *error;
        NSData *dataSound = [self.verbsSounds valueForKey:simpleString];
        NSLog(@"Sound Data %@",dataSound);
     self.audioPlayer = [[AVAudioPlayer alloc] initWithData:dataSound error:&error];
     if(!error){
         self.audioPlayer.delegate = self;
         [self.audioPlayer prepareToPlay];
         [self.audioPlayer play];
     }
     else{
         NSLog(@"Error %@",[error localizedDescription]);
     }
    }
}

- (IBAction)getSpeech:(id)sender {
    [self.getSpeechButton setEnabled:NO];
    dispatch_queue_t downloadQueue = dispatch_queue_create("speech downloader", NULL);
 
    NSSet *verbsToDownload = self.getSingularTextFromVerbs;
    
    [self.progressIndicator setMinValue:0];
    [self.progressIndicator setMaxValue:[verbsToDownload count]];
    
    [self.progressIndicator startAnimation:self];
    [self.progressIndicator  setHidden:NO];
    
    dispatch_async(downloadQueue, ^{
        
        
        for(id verb in verbsToDownload){
                NSString *formattedURL = [NSString stringWithFormat:SPEECH_API_URL,verb];
            NSLog(@"verb %@",formattedURL);
            NSURL *networkURL = [[NSURL alloc] initWithString:formattedURL];
            NSData *speechData = [NSData dataWithContentsOfURL:networkURL];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressIndicator incrementBy:1];
      
                [self.verbsSounds setValue:speechData forKey:verb];
           
              
            });
   
        }
 
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressIndicator stopAnimation:self];
             [self.progressIndicator  setHidden:YES];
              [self.getSpeechButton setEnabled:YES];
           });
        
        
    });
}



-(IBAction)createNewItem:(id)sender{
    if(!verbsItems){
        verbsItems = [NSMutableArray array];
    }
    [verbsItems addObject:@"New item"];
    [itemTableView reloadData];
    [self updateChangeCount:NSChangeDone];
    
    
    
}

#pragma mark - Data Source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return [verbsItems count];
}



- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{

    NSUInteger index= [keysOfVerbs indexOfObject:[aTableColumn identifier]];
 
    return [[verbsItems objectAtIndex:rowIndex] objectForKey:keysOfVerbs[index]];
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    //[todoItems replaceObjectAtIndex:rowIndex withObject:anObject];
    
    [self updateChangeCount:NSChangeDone];
}
@end
