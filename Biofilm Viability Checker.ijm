//This macro processes multiple images in a folder, outputting the number of bacteria pixels in the green channel to calculate the viability of a biofilm stained with a green viability stain. 
//It also saves overlay images showing the bacteria which have been detected.

Dialog.create("Biofilm Viability Checker");
Dialog.addMessage(" This macro processes fluorescence images of biofilm stained with a green viability stain to calculate the number of live bacteria in each image. \n \n First, put your image(s) to be processed in a separate input folder. "); 
Dialog.addString("Add image file type suffix: ", ".tif", 5);
Dialog.addCheckbox("Save overlay images", true);
Dialog.addMessage("Tick this to save overlay images of the detected areas to your output folder. The detected bacteria will be outlined in green."); 
Dialog.addMessage("Click OK to choose your input and output directories. \n After processing, you will be able to save the log file containing the number of live bacteria in each image.");
Dialog.show();
suffix = Dialog.getString();

print("\\Clear");
print("Image title" + "\t" + "Number of live bacteria (viability)");

overlay = Dialog.getCheckbox();
gammavalue = 1.5;
strelvalue = 1;

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
    selectWindow("Image (green)");
    rename("green");
    close("Image (red)");
    close("Image (blue)");

    //Green channel erosion
    selectWindow("green");
    run("Morphological Filters", "operation=Erosion element=Square radius=strelvalue");
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

    //Additional gamma contrast enhancement for green channel
    selectWindow("green-Erosion-rec-Dilation-rec");
    run("Gamma...", "value=gammavalue");

    //Image Segmentation
    run("Auto Threshold", "method=Otsu white");
    run("Convert to Mask");

    //Measure the number of white pixels in green channel, corresponding to live bacteria area and output in a log window
    selectWindow("Result of green-Erosion-rec-Dilation-rec");
    run("Clear Results");
    setOption("ShowRowNumbers", false);
    for (slice = 1; slice <= nSlices; slice++) {
        setSlice(slice);
        getRawStatistics(n, mean, min, max, std, hist);
        for (i = 0; i < hist.length; i++) {
            setResult("Count" + slice, i, hist[i]);
        }
    }
    path = getDirectory("home") + "histogram-counts.csv";
    saveAs("Results", path);

    livepix = getResult("Count1", 255);

    print(title + "\t" + livepix);

    // ... (remaining code, same as before)
}
