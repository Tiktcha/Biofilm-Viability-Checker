//This macro processes multiple images within a folder, analyzing the number of bacterial pixels in the green and red channels. 
//The green channel corresponds to SYTO9, while the red channel represents PI. 
//The output provides the bacterial pixel count for each channel, enabling the calculation biofilm viability stained with green and red viability stains.
//It also saves overlay images showing detected bacteria.

//Originally created by Sophie Mountcastle (sem093@bham.ac.uk) and Nina Vyas (n.vyas@bham.ac.uk), University of Birmingham, Edgbaston, B15 2TT, UK.
//Modified by Tinatini Tchatchiashvili (Tinatini.tchatchiashvili@med.uni-jena.de, Jena University Hospital, Am Klinikum 1, 07747 Jena, Germany) to output the number of stained pixels instead of percentage values.
//For queries related to the original code, please contact Dr Sarah Kuehne (s.a.kuehne@bham.ac.uk)
//For queries related to the modified code, please contact Tinatini Tchatchiashvili (Tinatini.tchatchiashvili@med.uni-jena.de)



Dialog.create("Biofilm Viability Checker");
	Dialog.addMessage(" This macro processes fluorescence images of biofilm stained with SYTO9 and propidium iodide to calculate the percentage of \n live and dead bacteria in each image. \n \n First put your image(s) to be processed in a separate input folder. "); 
	Dialog.addString("Add image file type suffix: ", ".tif", 5);
	Dialog.addCheckbox("Save overlay images", true);
	Dialog.addMessage("Tick this to save overlay images of the detected areas to your output folder. The detected total bacteria are outlined in \ngreen and the detected dead bacteria are outlined in white."); 
	Dialog.addMessage("Click OK to choose your input and output directories. \n After processing you will be able to save the log file containing the percentage of live and dead bacteria in each image.");
Dialog.show();
suffix = Dialog.getString();


// result report genereation----------------


print("\\Clear");
print("Image title" + "\t" + "(SYTO9 - PI) pixels"  + "\t" + "(PI) pixels");

overlay=Dialog.getCheckbox();
gammavalue=1;
strelvalue=1;

input = getDirectory("Input directory");
output = getDirectory("Output directory");

processFolder(input);

function processFolder(input) {
	list = getFileList(input);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + list[i]))
			processFolder("" + input + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}

function processFile(input, output, file) {
open(input + File.separator + file);

//Split .tif image into red, green, and blue channels.
title = getTitle();
run("RGB Color");
rename("Image"); 
run("Split Channels");
selectWindow("Image (red)");
rename("red");
selectWindow("Image (green)");
rename("green");
selectWindow("Image (blue)");
close();

//Image pre-processing:
//Red channel erosion
selectWindow("red");
run("Morphological Filters", "operation=Erosion element=Square radius=strelvalue"); //Create the marker image, erosion of red channel. Changing the radius of the element will affect the size of the noise removed in this step.
//Red channel opening by reconstruction 
run("Morphological Reconstruction", "marker=red-Erosion mask=[red] type=[By Dilation] connectivity=8");
//Red channel opening-closing by reconstruction 
selectWindow("red-Erosion-rec");
run("Morphological Filters", "operation=Dilation element=Square radius=strelvalue");
selectWindow("red-Erosion-rec-Dilation");
run("Invert");
selectWindow("red-Erosion-rec");
run("Invert");
run("Morphological Reconstruction", "marker=red-Erosion-rec-Dilation mask=red-Erosion-rec type=[By Dilation] connectivity=8");
selectWindow("red-Erosion-rec-Dilation-rec");
run("Invert");

//Green channel erosion
selectWindow("green");
run("Morphological Filters", "operation=Erosion element=Square radius=strelvalue"); //Create the marker image, erosion of green channel. Changing the radius of the element will affect the size of the noise removed in this step.
//Green channel opening by reconstruction 
run("Morphological Reconstruction", "marker=green-Erosion mask=[green] type=[By Dilation] connectivity=8");
//Green channel opening-closing by reconstruction 
selectWindow("green-Erosion-rec");
run("Morphological Filters", "operation=Dilation element=Square radius=strelvalue");
selectWindow("green-Erosion-rec-Dilation");
run("Invert");
selectWindow("green-Erosion-rec");
run("Invert");
run("Morphological Reconstruction", "marker=green-Erosion-rec-Dilation mask=green-Erosion-rec type=[By Dilation] connectivity=8");
selectWindow("green-Erosion-rec-Dilation-rec");
run("Invert");

//Red channel subtract background, additional step to ensure background staining is not included in analysis of red channel.
selectWindow("red-Erosion-rec-Dilation-rec");
run("Subtract Background...", "rolling=100");

//Additional gamma contrast enhancement for red and green channel
selectWindow("red-Erosion-rec-Dilation-rec");
run("Gamma...", "value=gammavalue");
selectWindow("green-Erosion-rec-Dilation-rec");
run("Gamma...", "value=gammavalue");


//Image Segmentation
//Concatenate images for global otsu thresholding and separate
run("Concatenate...", "  title=Stack keep open image1=green-Erosion-rec-Dilation-rec image2=red-Erosion-rec-Dilation-rec image3=[-- None --]");
run("Auto Threshold", "method=Otsu white use_stack_histogram");
run("Stack to Images");
selectWindow("Stack-0001"); //green channel
selectWindow("Stack-0002"); //red channel

//Measure the number of white pixels in red channel, corresponding to dead bacteria area and output in a log window
selectWindow("Stack-0002");
 run("Clear Results");
  setOption("ShowRowNumbers", false);
  for (slice=1; slice<=nSlices; slice++) {
     setSlice(slice);
     getRawStatistics(n, mean, min, max, std, hist);
     for (i=0; i<hist.length; i++) {
        //setResult("Value", i, i);
        setResult("Count"+slice, i, hist[i]);
     }
  }
  path = getDirectory("home")+"histogram-counts.csv";
  saveAs("Results", path); 

deadpix=getResult("Count1",255);


//Combine channels to get total pixels
setOption("BlackBackground", true);
run("Convert to Mask");
selectWindow("Stack-0002");
run("Convert to Mask");
selectWindow("Stack-0001");
imageCalculator("OR create", "Stack-0001","Stack-0002");

//Measure the number of white pixels in combined channel, corresponding to total bacteria area and output in a log window
selectWindow("Result of Stack-0001");
 run("Clear Results");
  setOption("ShowRowNumbers", false);
  for (slice=1; slice<=nSlices; slice++) {
     setSlice(slice);
     getRawStatistics(n, mean, min, max, std, hist);
     for (i=0; i<hist.length; i++) {
        //setResult("Value", i, i);
        setResult("Count"+slice, i, hist[i]);
     }
  }
  path = getDirectory("home")+"histogram-counts.csv";
  saveAs("Results", path); 


totalpix=getResult("Count1",255);


print(title  + "\t" + (totalpix-deadpix) + "\t" + deadpix);


//------------------------------------

//To make an overlay on an rgb image, the outline of the detected dead cells is shown in white and the outline of the live detected cells is shown in green.
open(input + File.separator + file);
if (overlay) {
	imageCalculator("Subtract create", "Result of Stack-0001","Stack-0002");
	selectWindow("Result of Result of Stack-0001");
	
	selectWindow(title);
	//run("RGB Color");
	//run("Enhance Contrast...", "saturated=2");
	run("RGB Color");
	rename("rgb");
	
	selectWindow("Result of Result of Stack-0001");
	run("Outline");
	run("Create Selection");
	setForegroundColor(0, 255, 0);
	
	selectWindow("rgb");
	run("Restore Selection");
	run("Fill", "slice");
	run("Select None");
	
	selectWindow("Stack-0002");
	run("Outline");
	run("Create Selection");
	
	
	selectWindow("rgb");
	setForegroundColor(255, 0, 0);
	run("Restore Selection");
	run("Fill", "slice");
	
	selectWindow("rgb");
	save(output + "overlay " + file);
}
//  macro "Close All Windows" { 
      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
  } 
selectWindow("Log");
saveAs("Text")

