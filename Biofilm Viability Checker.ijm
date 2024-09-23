//This macro processes multiple images within a folder, analyzing the number of bacterial pixels in the green and blue channels. 
//The green channel corresponds to the metabolic activity stain (Calcein AM, CAM), while the blue channel represents the membrane stain (TMA-DPH). 
//The output provides the bacterial pixel count for each channel, enabling the calculation of biofilm viability based on metabolic activity and membrane integrity.
//It also saves overlay images showing detected bacteria.

//Originally created by Sophie Mountcastle (sem093@bham.ac.uk) and Nina Vyas (n.vyas@bham.ac.uk), University of Birmingham, Edgbaston, B15 2TT, UK
//Modified by Tinatini Tchatchiashvili (Tinatini.tchatchiashvili@med.uni-jena.de, Jena University Hospital, Am Klinikum 1, 07747 Jena, Germany) to include updated channel analysis and relevant staining protocol for CAM/TMA-DPH staining.
//For queries related to the original code, please contact Dr Sarah Kuehne (s.a.kuehne@bham.ac.uk)
//For queries related to the adapted code, please contact Tinatini Tchatchiashvili (Tinatini.tchatchiashvili@med.uni-jena.de)


Dialog.create("Biofilm Viability Checker");
	Dialog.addMessage(" This macro processes fluorescence images of biofilm stained with CAM and TMA-DPH to calculate the amount of metabolic active and metabolic inactive bacteria in each image. \n \n First put your image(s) to be processed in a separate input folder. "); 
	Dialog.addString("Add image file type suffix: ", ".tif", 5);
	Dialog.addCheckbox("Save overlay images", true);
	Dialog.addMessage("Tick this to save overlay images of the detected areas to your output folder. The detected metabolic active, live bacteria are outlined in \ngreen and the detected metabolic inactive bacteria are outlined in violet."); 
	Dialog.addMessage("Click OK to choose your input and output directories. \n After processing you will be able to save the log file containing the amount of metabolic active, live and metabolic inactive bacteria in each image.");
Dialog.show();
suffix = Dialog.getString();


// result report genereation----------------


print("\\Clear");
print("Image title" + "\t" + "CAM pixels" + "\t" + "TMA-DPH pixels");

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
selectWindow("Image (blue)");
rename("blue");
selectWindow("Image (green)");
rename("green");
selectWindow("Image (red)");
close();

//Image pre-processing:
//blue channel erosion
selectWindow("blue");
run("Morphological Filters", "operation=Erosion element=Square radius=strelvalue"); //Create the marker image, erosion of blue channel. Changing the radius of the element will affect the size of the noise removed in this step.
//blue channel opening by reconstruction 
run("Morphological Reconstruction", "marker=blue-Erosion mask=[blue] type=[By Dilation] connectivity=8");
//Blue channel opening-closing by reconstruction 
selectWindow("blue-Erosion-rec");
run("Morphological Filters", "operation=Dilation element=Square radius=strelvalue");
selectWindow("blue-Erosion-rec-Dilation");
run("Invert");
selectWindow("blue-Erosion-rec");
run("Invert");
run("Morphological Reconstruction", "marker=blue-Erosion-rec-Dilation mask=blue-Erosion-rec type=[By Dilation] connectivity=8");
selectWindow("blue-Erosion-rec-Dilation-rec");
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


//Additional gamma contrast enhancement for blue and green channel
selectWindow("blue-Erosion-rec-Dilation-rec");
run("Gamma...", "value=gammavalue");
selectWindow("green-Erosion-rec-Dilation-rec");
run("Gamma...", "value=gammavalue");


//Image Segmentation
//Concatenate images for global otsu thresholding and separate
run("Concatenate...", "  title=Stack keep open image1=green-Erosion-rec-Dilation-rec image2=blue-Erosion-rec-Dilation-rec image3=[-- None --]");
run("Auto Threshold", "method=Otsu white use_stack_histogram");
run("Stack to Images");
selectWindow("Stack-0001"); //green channel
selectWindow("Stack-0002"); //blue channel

//Measure the number of white pixels in green channel, corresponding to Calcein AM stained bacteria area and output in a log window
selectWindow("Stack-0001");
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

CAMpix=getResult("Count1",255);

//Measure the number of white pixels in blue channel, corresponding to TMA-DPH stained bacteria area and output in a log window
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

TMApix=getResult("Count1",255);


print(title + "\t" + CAMpix + "\t" + TMApix);

// Open the image for overlay creation
open(input + File.separator + file);

// Check if overlay saving is enabled
if (overlay) {
    // Ensure we are working on an RGB image
    selectWindow(title);
    run("RGB Color");
    rename("rgb");
    
    // Outline detected live cells (green channel: Stack-0001)
    selectWindow("Stack-0001");
    run("Outline");             // Create an outline of the detected live areas
    run("Create Selection");     // Turn the outline into a selection
    setForegroundColor(0, 255, 0);  // Set color to green for live cells
    
    selectWindow("rgb");
    run("Restore Selection");    // Apply the selection to the RGB image
    run("Fill", "slice");        // Fill the selection with green color
    run("Select None");          // Deselect the selection
    
    // Outline detected metabolic inactive cells (blue channel: Stack-0002)
    selectWindow("Stack-0002");
    run("Outline");              // Create an outline of the detected dead areas
    run("Create Selection");     // Turn the outline into a selection
    
    
    selectWindow("rgb");
    setForegroundColor(127, 0, 255);  // Set color to violet for metabolic inactive cells
    run("Restore Selection");    // Apply the selection to the RGB image
    run("Fill", "slice");        // Fill the selection with violet color
    
    // Save the image with overlays
    saveAs("Tiff", output + "overlay_" + file);
}


}
//  macro "Close All Windows" { 
      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
}
selectWindow("Log");
saveAs("Text");



