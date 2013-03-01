//
//  ALOVDocument.m
//  aListOfVerbsManager
//
//  Created by Oswaldo Rubio on 06/01/13.
//  Copyright (c) 2013 Oswaldo Rubio. All rights reserved.
//

#import "ALOVDocument.h"
@interface ALOVDocument()
{
    IBOutlet NSTableView *itemTableView;
    NSArray *keysOfVerbs;
    
}

@property (strong, nonatomic)  NSMutableArray *verbsItems;
@property (strong, nonatomic)  NSMutableDictionary *verbsSounds;
@property(strong,nonatomic) NSMutableArray *playQueueList;

@property(strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (weak) IBOutlet NSButton *playButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *getSpeechButton;


- (IBAction)playSelected:(id)sender;
- (IBAction)getSpeech:(id)sender;
-(IBAction)createNewItem:(id)sender;



@end

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

#pragma mark - LazyLoaders
-(NSMutableDictionary *)verbsSounds{
    if(!_verbsSounds){
        _verbsSounds = [[NSMutableDictionary alloc] init];
    }
    return _verbsSounds;
}
-(NSMutableArray *)playQueueList{
    if(!_playQueueList)
        _playQueueList = [[NSMutableArray alloc]init];
    return _playQueueList;
}
-(NSMutableArray *)verbsItems
{
    if(!_verbsItems){
        _verbsItems = [[NSMutableArray alloc]init ];
    }    
    return _verbsItems;
}
-(AVAudioPlayer *)audioPlayer{
    if(!_audioPlayer){
        _audioPlayer = [[AVAudioPlayer alloc]init];
    }
    return _audioPlayer;
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

#pragma mark - NSDocument 
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
 
    NSData *data= [NSPropertyListSerialization dataWithPropertyList:self.verbsItems format:NSPropertyListXMLFormat_v1_0 options:0 error:outError];
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    self.verbsItems = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:NULL error:outError];
    return (self.verbsItems !=nil);
}

-(NSMutableSet *) getSingularTextFromVerbsSelected:(NSIndexSet *)set{
    
    NSMutableSet *returnSet = [[NSMutableSet alloc] init];
    for(int row=0;row< [self.verbsItems count];row++){
        for(int col =0;col <[keysOfVerbs count];col++){
            
            if([set containsIndex:row ]){
                NSString *valueString =  [[self.verbsItems objectAtIndex:row] objectForKey:keysOfVerbs[col]];
                [returnSet addObject:valueString];
            }
            
        }
    }
    return  returnSet;
}

#pragma mark - Actions

#define SPEECH_API_URL @"http://tts-api.com/tts.mp3?q=%@"



- (IBAction)playSelected:(id)sender {
 
    NSIndexSet* selectedRows = [itemTableView selectedRowIndexes];
    
    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSString *simpleString =   [[self.verbsItems objectAtIndex:idx] valueForKey:@"simple"];
        NSString *pastString =   [[self.verbsItems objectAtIndex:idx] valueForKey:@"past"];
        NSString *participleString =   [[self.verbsItems objectAtIndex:idx] valueForKey:@"participle"];
        
        [self.playQueueList addObjectsFromArray:@[simpleString,pastString,participleString]];
        
    }];
    [self playQueue];
   
}
-(void)playQueue{
 
    if([self.playQueueList count] >0){
        
        NSData *dataSound = [self.verbsSounds valueForKey:self.playQueueList[0]];
        [self.playQueueList removeObjectAtIndex:0];
        if(dataSound){
            
             NSError *error;
            self.audioPlayer = [[AVAudioPlayer alloc] initWithData:dataSound error:&error];
            if(!error){
                self.audioPlayer.delegate = self;
                [ self.audioPlayer prepareToPlay];
                
                [self.audioPlayer play];
            }
            else{
                NSLog(@"Error %@",[error localizedDescription]);
            }
            
            
        }

    }
   }
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if([self.playQueueList count] >0){
        [self playQueue];
    }
}
- (IBAction)getSpeech:(id)sender {
    
    if([self.verbsItems count] > 0 ){
        
        NSOpenPanel *open = [NSOpenPanel openPanel];
        
        //Disable file selection
        [open setCanChooseFiles: false];
        
        //Enable folder selection
        [open setCanChooseDirectories: true];
        
        //Enable alias resolving
        [open setResolvesAliases: true];
        
        //Disable multiple selection
        [open setAllowsMultipleSelection: false];
        
        //Display open panel
        [open runModal];
        
        //Get source folder name
        NSURL* destFolderPath = [[open URLs] objectAtIndex:0];
    
 
        
        NSIndexSet* selectedRows = [itemTableView selectedRowIndexes];
        
        
        [self.getSpeechButton setEnabled:NO];
        dispatch_queue_t downloadQueue = dispatch_queue_create("speech downloader", NULL);
        
        NSSet *verbsToDownload = [self getSingularTextFromVerbsSelected:selectedRows];
        
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
                    NSError *error2;
                    NSString *desfFilePath = [NSString stringWithFormat:@"%@/%@.mp3",[destFolderPath path],verb] ;
              
                    [speechData writeToFile:desfFilePath options:NSDataWritingAtomic error:&error2];
                    if(error2){
                        NSLog(@"Error %@", [error2 localizedDescription]);
                    }
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
}


//@TODO
-(IBAction)createNewItem:(id)sender{
    NSDictionary *dictVerb = [[NSDictionary alloc] init];
    [dictVerb setValue:@"undefined" forKey:@"simple"];
    [dictVerb setValue:@"undefined" forKey:@"past"];
    [dictVerb setValue:@"undefined" forKey:@"participle"];
    
    [self.verbsItems addObject:dictVerb];
    [itemTableView reloadData];
    [self updateChangeCount:NSChangeDone];
    
}

#pragma mark - Data Source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView{
    return [self.verbsItems count];
}



- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{

    NSUInteger index= [keysOfVerbs indexOfObject:[aTableColumn identifier]];
    if(index < [self.verbsItems count]){
        if([[self.verbsItems objectAtIndex:rowIndex] respondsToSelector:@selector(objectForKey:)])
            return [[self.verbsItems objectAtIndex:rowIndex] objectForKey:keysOfVerbs[index]];
        else return nil;
    }
    else
        return nil;
    
}

//@TODO  editable Table?
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    //[verbsItems replaceObjectAtIndex:rowIndex withObject:anObject];
    
    [self updateChangeCount:NSChangeDone];
}
@end
