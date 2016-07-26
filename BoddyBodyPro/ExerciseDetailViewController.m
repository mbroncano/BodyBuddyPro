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
    
    NSMutableArray *frontMuscleImageArray = [@[] mutableCopy];
    NSMutableArray *backMuscleImageArray = [@[] mutableCopy];
    
    // TODO: eventually abstract the image retrieval, update, etc.
    NSArray *muscleImagesFront = [ModelController objectWithValue:muscularSystemFront forAttribute:@"name" forEntityName:@"Image" withinContext:context];
    NSData *muscleImageDataFront = [muscleImagesFront[0] valueForKey:@"data"];
    if (muscleImageDataFront != nil) {
        UIImage *image = [[SVGKImage imageWithData:muscleImageDataFront] UIImage];
//        self.frontMuscleImage.image = image;
        [frontMuscleImageArray addObject:image];
    }

    NSArray *muscleImagesBack = [ModelController objectWithValue:muscularSystemBack forAttribute:@"name" forEntityName:@"Image" withinContext:context];
    NSData *muscleImageDataBack = [muscleImagesBack[0] valueForKey:@"data"];
    if (muscleImageDataBack != nil) {
        UIImage *image = [[SVGKImage imageWithData:muscleImageDataBack] UIImage];
//        self.backMuscleImage.image = image;
        [backMuscleImageArray addObject:image];
    }
    
    // Additional muscle images
    NSSet *musclePrimaryArray = [exercise valueForKey:@"muscles"];
    for (NSManagedObject *muscle in musclePrimaryArray) {
        NSString *musclePath = [NSString stringWithFormat:muscleMainURL, [muscle valueForKey:@"id"]];
        NSArray *muscleImages = [ModelController objectWithValue:musclePath forAttribute:@"name" forEntityName:@"Image" withinContext:context];
        NSData *muscleImageData = [muscleImages[0] valueForKey:@"data"];
        if (muscleImageData != nil) {
            UIImage *image = [[SVGKImage imageWithData:muscleImageData] UIImage];
            if ([[muscle valueForKey:@"is_front"] boolValue]) {
                [frontMuscleImageArray addObject:image];
            } else {
                [backMuscleImageArray addObject:image];
            }
        }
    }
    
    NSSet *muscleSecondayArray = [exercise valueForKey:@"muscles_secondary"];
    for (NSManagedObject *muscle in muscleSecondayArray) {
        NSString *musclePath = [NSString stringWithFormat:muscleSecondaryURL, [muscle valueForKey:@"id"]];
        NSArray *muscleImages = [ModelController objectWithValue:musclePath forAttribute:@"name" forEntityName:@"Image" withinContext:context];
        NSData *muscleImageData = [muscleImages[0] valueForKey:@"data"];
        if (muscleImageData != nil) {
            UIImage *image = [[SVGKImage imageWithData:muscleImageData] UIImage];
            if ([[muscle valueForKey:@"is_front"] boolValue]) {
                [frontMuscleImageArray addObject:image];
            } else {
                [backMuscleImageArray addObject:image];
            }
        }
    }

    if (frontMuscleImageArray.count != 0) {
        UIImage *img = frontMuscleImageArray[0];
        CGSize size = img.size;
        UIGraphicsBeginImageContext(size);
        for(UIImage *image in frontMuscleImageArray) {
            [image drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
        }
        self.frontMuscleImage.image = UIGraphicsGetImageFromCurrentImageContext();
    }

    if (backMuscleImageArray.count != 0) {
        UIImage *img = backMuscleImageArray[0];
        CGSize size = img.size;
        UIGraphicsBeginImageContext(size);
        for(UIImage *image in backMuscleImageArray) {
            [image drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
        }
        self.backMuscleImage.image = UIGraphicsGetImageFromCurrentImageContext();
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
