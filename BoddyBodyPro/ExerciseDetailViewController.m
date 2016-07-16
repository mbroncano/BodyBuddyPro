//
//  ExerciseDetailViewController.m
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/16/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import "ExerciseDetailViewController.h"
#import "ModelController.h"

@interface ExerciseDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@end

@implementation ExerciseDetailViewController

// NOTE: we need *both* (i.e. height and estimate) delegates for the automatic dimension to work
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

// as we can't change the font easily for a HTML text, this function replaces
// every font in the string with the system font
- (void)setBaseFont:(UIFont *)baseFont inString:(NSMutableAttributedString *)str {
    [str enumerateAttribute:NSFontAttributeName
                    inRange:NSMakeRange(0, str.length)
                    options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                 usingBlock:^(id value, NSRange range, BOOL *stop) {

                     UIFont *font = (UIFont *)value;
                     UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
                     UIFontDescriptor *descriptor = [baseFont.fontDescriptor fontDescriptorWithSymbolicTraits:traits];
                     UIFont *newFont = [UIFont fontWithDescriptor:descriptor size:descriptor.pointSize];
                     
                     [str removeAttribute:NSFontAttributeName range:range];
                     [str addAttribute:NSFontAttributeName value:newFont range:range];
                 
                 }];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSManagedObjectContext *context = [[ModelController sharedInstance] mainObjectContext];
    // TODO: check for errors
    NSManagedObject *exercise = [ModelController exerciseWithId:self.exerciseId withContext:context];
    
//    self.nameLabel.text = [exercise valueForKey:@"name"];    
//    self.descLabel.text = [exercise valueForKey:@"desc"];

    NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc]
                                         initWithData:[[exercise valueForKey:@"name"] dataUsingEncoding:NSUnicodeStringEncoding]
                                         options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                         documentAttributes:nil error:nil];
    
    [self setBaseFont:[UIFont systemFontOfSize:[UIFont systemFontSize]] inString:nameString];
    
    self.nameLabel.attributedText = nameString;

    NSMutableAttributedString *descString = [[NSMutableAttributedString alloc]
                                             initWithData:[[exercise valueForKey:@"desc"] dataUsingEncoding:NSUnicodeStringEncoding]
                                             options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                             documentAttributes:nil error:nil];
    [self setBaseFont:[UIFont systemFontOfSize:[UIFont systemFontSize]] inString:descString];

    self.descLabel.attributedText = descString;
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
