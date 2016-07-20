//
//  ExerciseDetailViewController.m
//  BoddyBodyPro
//
//  Created by Manuel Broncano Rodriguez on 7/16/16.
//  Copyright © 2016 Manuel Broncano Rodriguez. All rights reserved.
//

#import "ExerciseDetailViewController.h"
#import "ModelController.h"
#import "NetworkController.h"
#import <SVGKit/SVGKImage.h>

@interface ExerciseDetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIImageView *frontMuscleImage;
@property (weak, nonatomic) IBOutlet UIImageView *backMuscleImage;

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

- (void)updateView {
    NSManagedObjectContext *context = [[ModelController sharedInstance] mainObjectContext];
    // TODO: check for errors
    NSManagedObject *exercise = [ModelController objectWithId:self.exerciseId forEntityName:@"Exercise" withinContext:context];
    
    NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc]
                                         initWithData:[[exercise valueForKey:@"name"] dataUsingEncoding:NSUnicodeStringEncoding]
                                         options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                         documentAttributes:nil error:nil];

    NSMutableAttributedString *descString = [[NSMutableAttributedString alloc]
                                             initWithData:[[exercise valueForKey:@"desc"] dataUsingEncoding:NSUnicodeStringEncoding]
                                             options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                             documentAttributes:nil error:nil];

    [self setBaseFont:[UIFont systemFontOfSize:[UIFont systemFontSize]] inString:nameString];
    [self setBaseFont:[UIFont systemFontOfSize:[UIFont systemFontSize]] inString:descString];

    self.nameLabel.attributedText = nameString;
    self.descLabel.attributedText = descString;
    
    NSArray *muscleImagesF = [ModelController objectWithValue:@"muscular_system_front.svg" forAttribute:@"name" forEntityName:@"Image" withinContext:context];
    NSData *muscleImageDataF = [muscleImagesF[0] valueForKey:@"data"];
    if (muscleImageDataF != nil) {
        UIImage *image = [[SVGKImage imageWithData:muscleImageDataF] UIImage];
        self.frontMuscleImage.image = image;
    }

    NSArray *muscleImagesBack = [ModelController objectWithValue:@"muscular_system_back.svg" forAttribute:@"name" forEntityName:@"Image" withinContext:context];
    NSData *muscleImageDataBack = [muscleImagesBack[0] valueForKey:@"data"];
    if (muscleImageDataBack != nil) {
        UIImage *image = [[SVGKImage imageWithData:muscleImageDataBack] UIImage];
        self.backMuscleImage.image = image;
    }

    [self.tableView reloadData];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self updateView];
    
    [[NetworkController sharedInstance] retrieveMuscleImagesWithCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateView];
        });
    }];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
