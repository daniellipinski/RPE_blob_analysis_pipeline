REP_blob_analysis_pipeline
Please cite this paper if this code is used in your study: 


NOTES:
• The code was tested in MatLab 2017b utilizes MatConvNet-1.0-Beta23 developed by the MatConvNet Team (see http://www.vlfeat.org/matconvnet/).
• The code utilizes createCircleMask.m developed by Brett Shoelson (see https://www.mathworks.com/matlabcentral/fileexchange/47905-createcirclesmask-m) for the purposes of image masking in Section 1; a copy of this function is included under the name "CircleMask.m"
• The code requires the "Computer Vision Toolbox" of MatLab for the use of the MatLab-native cell counting algorithm, "vision.BlobAnalysis". Our installed package list is appendixed under "MatLab Packages" for reference.
• Example code is included under "Example data", as well as a simulation of the image processing under "DrusenCountingSimulation.m"
• Questions may be directed to Dr. Daniel Lipinski (dlipinski@mcw.edu, Principal Investigator) or Alex Tate (ajtate@mcw.edu, code developer).


SETUP: 
Before running, both "CircleMask.m" and "DrusenCounter.m" should be saved within the same folder; "DrusenCounter.m" is the main script.

Before running, images should be named systematically (i.e. ImageName1.tif, ImageName2.tif,... ImagenameN.tif) within the same folder. Batches may be ran, but only sequentially starting at the image number of your choosing for N loops.
• The code has most extensively been tested with .tif images, however .bmp and .jpg images are viable as well; image compression may result in less reliable detection of small or low contrast drusen.
• Large batches of high resolution images may be exceed memory cap; in this case, the code needs ran with smaller batches of images.


SECTION1: Image Uploading/Masking
Run&Advance Section 1.

Input the stem for image names (i.e. ImageName1.tif --> ImageName)

Input the number of images that will be processed in this batch

Input the number of the first image that will be processed in this batch

For each loop, the code will display the uploaded raw image; draw a rectangular ROI with the corners touching where you want the circle mask to be generated (i.e. the interior of the well wall)
• If no image cropping is desired, silence line19-line42 and change line45 to "Store_Raw{n} = raw"; Section 1 will instead only upload images for downstream processing.

Output: uploaded images will be converted into numerical matrices, masked, and saved as the cell array "Store_Raw" which will be stored under "Workplace1.mat" in the image folder


SECTION2: Image Processing
Run&Advance Section 2.

If moving straight from Section 1, no inputs are needed. If resuming previous work, load "Workplace1.mat"

IMPORTANT: Local neighborhood by default is defined as 11x11 pixels (radius of minimum drusen size that will be measured), but drusen size, pixel size, and resolution may affect the optimal local neighborhood...
...we recommend calculating your image pixel size and setting local neighborhood such that width = minimum drusen radius
• If changing local neighborhood, use the nearest odd integer and replace 11 to new# in line60 and line61 and replace 121 to new#^2 in line61

Note: The code detects drusen via contrast in local pixel intensity variance; as such the code functions primarily by detecting drusen edges. As a byproduct large and/or homogenous drusen may exhibit a "donuting" / "hollowing" artifact, which is corrected in Section 3 by backcalculating area via ellipse area approximation using bounding box data. 

Output: background variance adjusted and binarized images ready will be saved under the cell array "Store_Processed" which will be stored under "Workplace2.mat", and binary images will be saved individually


SECTION3: Blob Analysis
IMPORTANT: Minimum drusen (blob) area is set to 400 sq. pixels, corresponding to 15um diameter drusen. This is intentionally smaller than the end minimum to correct for underreported areas of drusen exhibiting "donuting". 
...we recommend calculating your image pixel size and setting MinimumBlobArea to 50% of the minimum diameter in line93 and to 100% downstream at line123 for the EAT (Ellipse Area Threshold)
• Example: our pixel size corresponds to 0.665um, so 400sq.pixels =176.89um2, which corresponds to a radius of 7.50um or diameter of 15.01um. Our desired final drusen diameter is 30um, an area of 706.86 um or 1598.42 sq.pixel

vision.BlobAnalysis parameters for area, bounding box, centroid, eccentricity, equivalent diameter squared, labels, and border exclusion are turned on. 
• The only strictly necessary outputs are area, bounding box, and labels. 
• Centroid, eccentricity, and equivalent diameter squared may be turned off if not of interest

After ellipse area correction, manual exclusions will be prompted. If manual exlusions will never be used, change line134 to "edit = 0"
• To make a manual exclusion, use the selection tool in the graph to select the blob to be excluded and enter the blob's index in the workspace below
• Once no more manual exclusions are needed, enter 0 into the workspace

Output: a data summary including drusen count, area mean, and area std will be generated under "Summary". If distribution information or parameters other than drusen count and area are of interest, mroe detailed individual drusen information will be stored in cell arrays 
        Store_Blobs = drusen locations
        Store_Label = drusen labels
        Store_Area = drusen areas, before ellipse area correction
        Store_Ellipse = drusen areas, after ellipse area correction (used for area mean and std)
        Store_BBox = drusen bounding boxes (smallest box containing the drusen, used for ellipse area correction)
        Store_Centroid = drusen center coordinates
        Store_Eccentricity = drusen eccentricity (deviation from sphericity)
