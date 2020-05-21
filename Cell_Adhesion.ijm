/*
 * Cell_Adhesion_Assay
 * Authors: Pau Carrillo-Barberà
 * Department of Cellular & Functional Biology
 * University of Valencia (Valencia, Spain)
 */

macro "Cell_Adhesion" {

//choose a macro mode and a directory
#@ String (label=" ", value="<html><font size=6><b>High Throughput Analysis</font><br><font color=teal>Cell Adhesion Assay</font></b></html>", visibility=MESSAGE, persist=false) heading
#@ String(label="Select mode:", choices={"Analysis", "Pre-Analysis (parameter tweaking)"}, persist=true, style="radioButtonVertical") mode
#@ File(label="Select directory:", persist=true, style="directory") dir
#@ String (label="<html>Load project</html>", choices={"No", "Yes"}, persist=true, style="radioButtonHorizontal") importPD
#@ String (label="<html>Save ROIs:</html>", choices={"No", "Yes"}, value="Yes", persist=true, style="radioButtonHorizontal") saveROIs
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Lab</b><br>ERI BIOTECMED, Universitat de València (Valencia, Spain)</font></html>", visibility=MESSAGE, persist=false) message

// open pre-established parameter dataset
if (importPD=="Yes") {
	pdPath=File.openDialog("Select a parameter dataset file");
	parametersString=File.openAsString(pdPath);
	parameterRows=split(parametersString, "\n");
	parameters=newArray(parameterRows.length);
	for(i=0; i<parameters.length; i++) {
		parameterColumns=split(parameterRows[i],"\t"); 
		parameters[i]=parameterColumns[1];
	}
}

// identification of the TIF files
// create an array containing the names of the files in the directory path
list = getFileList(dir);
Array.sort(list);
tiffFiles=0;

// count the number of TIF files
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "tif")) {
		tiffFiles++;
	}
}

// check that the directory contains TIF files
if (tiffFiles==0) {
	beep();
	exit("No tif files")
}

// create a an array containing only the names of the TIF files in the directory path
tiffArray=newArray(tiffFiles);
count=0;
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "tif")) {
		tiffArray[count]=list[i];
		count++;
	}
}

// extraction of the ‘well’ and ‘field’ information from the images’ filenames
// calculate: number of wells, images per well, images per field and fields per well
nWells=1;
nFields=1;
well=newArray(tiffFiles);
field=newArray(tiffFiles);
well0=substring(tiffArray[0],0,6);
field0=substring(tiffArray[0],11,14);

for (i=0; i<tiffArray.length; i++) {
	well[i]=substring(tiffArray[i],0,6);
	field[i]=substring(tiffArray[i],11,14);
	well1=substring(tiffArray[i],0,6);
	field1=substring(tiffArray[i],11,14);
	if (field0!=field1 || well1!=well0) {
		nFields++;
		field0=substring(tiffArray[i],11,14);
	}
	if (well1!=well0) {
		nWells++;
		well0=substring(tiffArray[i],0,6);
	}
}

wellName=newArray(nWells);
imagesxwell = (tiffFiles / nWells);
imagesxfield = (tiffFiles / nFields);
fieldsxwell = nFields / nWells;

// extraction of the ‘channel’ information from the images’ filenames
// create an array containing the names of the channels
channels=newArray(imagesxfield);		
for (i=0; i<channels.length; i++) {
	index1=indexOf(tiffArray[i], "wv ");
	index2=lastIndexOf(tiffArray[i], " - ");
	channels[i]=substring(tiffArray[i], index1+3, index2);
}

// extract values from a parameter dataset file
if(importPD=="Yes") {
	projectName=parameters[0];
	counterstainingChannel=parameters[1];
	trackerChannel=parameters[2];
	maximumRadius=parameters[3];
	thresholdCounterstain=parameters[4];
	prominence=parameters[5];
	thresholdTracker=parameters[6];
	minSize=parameters[7];
} else {
	// default parameters
	projectName="Project";
	counterstainingChannel=channels[0];
	trackerChannel=channels[0];
	maximumRadius=2;
	thresholdCounterstain=0.1;
	prominence=30;
	thresholdTracker=0.1;
	minSize=5;
}

// 'Select Parameters' dialog box
title = "Select Parameters";
Dialog.create(title);
Dialog.addString("Project", projectName, 40);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("CHANNEL SELECTION:");
Dialog.addChoice("Counterstaining", channels, counterstainingChannel);
Dialog.addChoice("Tracker", channels, trackerChannel);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("MONOLAYER PARAMETERS:");
Dialog.addNumber("Maximum (radius)", maximumRadius, 0, 2, "pixels");
Dialog.addSlider("Threshold", 0.01, 1.00, thresholdCounterstain);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("TRACKER PARAMETERS:");
Dialog.addNumber("Prominence >", prominence, 0, 2, "pixels");
Dialog.addSlider("Threshold", 0.01, 1.00, thresholdTracker);
Dialog.addNumber("Min object size", minSize, 0, 2, "pixels");
Dialog.setInsets(0, 170, 0);
Dialog.show()
projectName=Dialog.getString();
counterstainingChannel=Dialog.getChoice();
trackerChannel=Dialog.getChoice();
maximumRadius=Dialog.getNumber();
thresholdCounterstain=Dialog.getNumber();
prominence=Dialog.getNumber();
thresholdTracker=Dialog.getNumber();
minSize=Dialog.getNumber();

// check the parameter selection
if(counterstainingChannel==trackerChannel) {
	beep();
	exit("Counterstaining ["+counterstainingChannel+"] and Tracker ["+trackerChannel+"] channels can not be the same")
}

// create a parameter dataset file
title1 = "Parameter dataset";
title2 = "["+title1+"]";
f = title2;
run("Table...", "name="+title2+" width=500 height=500");
print(f, "Project\t" + projectName);
print(f, "Counterstaining channel\t" + counterstainingChannel);
print(f, "Tracker channel\t" + trackerChannel);
print(f, "Maximum (radius)\t" + maximumRadius);
print(f, "Threshold (counterstain)\t" + thresholdCounterstain);
print(f, "Prominence >\t" + prominence);
print(f, "Threshold (tracker)\t" + thresholdTracker);
print(f, "Min object size\t" +minSize);

// save as txt
saveAs("txt", dir+File.separator+projectName);
selectWindow(title1);
run("Close");

// create an array containing the well codes
for (i=0; i<nWells; i++) {
	wellName[i]=well[i*imagesxwell];
}

// create an array containing the field codes
fieldName=newArray(fieldsxwell);
for (i=0; i<fieldsxwell; i++) {
	fieldName[i]=i+1;
	fieldName[i]=d2s(fieldName[i], 0);
	while (lengthOf(fieldName[i])<3) {
		fieldName[i]="0"+fieldName[i];
	}
}

setOption("ScaleConversions", true);
setOption("BlackBackground", false);
roiManager("reset");
print("\\Clear");
roiManager("reset");
run("Close All");

// PRE-ANALYSIS WORKFLOW
if(mode=="Pre-Analysis (parameter tweaking)") {
	title = "Select field-of-view";
	testMode=true;
	while (testMode) {
		Dialog.create(title);
		Dialog.addChoice("Well", wellName);
		Dialog.addChoice("Field-of-view", fieldName);
		Dialog.show();
		well=Dialog.getChoice();
		field=Dialog.getChoice();
		counterstain=well+"(fld "+field+" wv "+counterstainingChannel+ " - "+counterstainingChannel+").tif";
		tracker=well+"(fld "+field+" wv "+trackerChannel+ " - "+trackerChannel+").tif";

		setBatchMode(true);
		
		// merge
		open(dir+File.separator+counterstain);
		imageBitDepth=bitDepth();
		if (imageBitDepth != 8) run("8-bit");
		run("Duplicate...", "title=["+counterstain+"_grayscale]");
		run("Duplicate...", "title=["+counterstain+"_mask]");
		open(dir+File.separator+tracker);
		imageBitDepth=bitDepth();
		if (imageBitDepth != 8) run("8-bit");
		run("Duplicate...", "title=["+tracker+"_mask]");
		selectImage(counterstain);
		run("Enhance Contrast...", "saturated=0.1 normalize");
		selectImage(tracker);
		run("Enhance Contrast...", "saturated=0.1 normalize");
		run("Merge Channels...", "c1=["+tracker+"] c3=["+counterstain+"] keep");
		rename("1 - Merge");
		
		// monolayer
		selectImage(counterstain+"_mask");
		run("Duplicate...", "title=Maximum_filter");
		run("Maximum...", "radius="+maximumRadius);
		thresholdFraction(thresholdCounterstain);
		rename("Monolayer");
		run("Duplicate...", "title=Background");
		run("Invert");
		selectImage(counterstain+"_mask");
		setAutoThreshold("Huang dark");
		run("Make Binary");
		imageCalculator("XOR create", counterstain+"_mask","Monolayer");
		rename("Monolayer_no-nuclei-1");
		imageCalculator("AND create", "Monolayer_no-nuclei-1","Monolayer");
		rename("Monolayer_no-nuclei-2");
		run("Merge Channels...", "c3=Background c2=Monolayer_no-nuclei-2 c4=["+counterstain+"_grayscale]");
		rename("2 - M/B");
		
		// tracker-labeled cells
		selectWindow(tracker+"_mask");
		run("Find Maxima...", "prominence="+prominence+" output=List");
		nMaxima=nResults;
		x=newArray(nMaxima);
		y=newArray(nMaxima);
		for (k=0; k<nMaxima; k++) {
			x[k]=getResult("X", k);
			y[k]=getResult("Y", k);
		}					
		thresholdFraction (thresholdTracker);
		run("Make Binary");				
		if (nMaxima>1) {
			getDimensions(widthTracker, heightTracker, channelsTracker, slicesTracker, framesTracker);
			newImage("Seeds", "8-bit white", widthTracker, heightTracker, 1);
			for (k=0; k<nMaxima; k++) {
				setPixel(x[k], y[k], 0);
			}
			run("Voronoi");
			setThreshold(0, 0);
			run("Make Binary");
			imageCalculator("AND create", tracker+"_mask", "Seeds");
			rename("tracker_mask");
		}
		run("Set Measurements...", "  redirect=None decimal=2");
		run("Analyze Particles...", "size="+minSize+"-Infinity pixel exclude add");
		selectImage("1 - Merge");
		roiManager("deselect");
		roiManager("Set Line Width", 0);
		setForegroundColor(255, 255, 0);
		roiManager("draw");
		roiManager("reset");
		
		// close
		selectWindow("Results");
		run("Close");
		close(counterstain);
		close(tracker);
		close(counterstain+"_mask");
		close(tracker+"_mask");
		close("tracker_mask");
		close("Seeds");
		close("Monolayer");
		close("Monolayer_no-nuclei-1");
		
		// show
		run("Images to Stack", "name=Stack title=[] use");
		setBatchMode(false);
		zoom=getZoom();
		while(zoom < 4) {
			run("In [+]");
			zoom=getZoom();
		}
		roiManager("show all with labels");
		waitForUser("Finish", "Click to clean up");
		run("Close All");
		radioButtonItems=newArray("Yes", "No");
		Dialog.create("Test Mode");
		Dialog.addRadioButtonGroup("Test other field-of-view:", radioButtonItems, 1, 2, radioButtonItems[0]);
		Dialog.show();
		keepTestMode=Dialog.getRadioButton();
		if (keepTestMode=="No") {
			testMode=false;
			selectWindow("ROI Manager");
			run("Close");
		}
	}
}

// ANALYSIS WORKFLOW
if(mode=="Analysis") {
	// 'Well Selection' dialog box
	selectionOptions=newArray("Select All", "Include", "Exclude");
	fileCheckbox=newArray(nWells);
	selection=newArray(nWells);
	title = "Select Wells";
	Dialog.create(title);
	Dialog.addRadioButtonGroup("", selectionOptions, 3, 1, selectionOptions[0]);
	Dialog.addCheckboxGroup(sqrt(nWells) + 1, sqrt(nWells) + 1, wellName, selection);
	Dialog.show();
	selectionMode=Dialog.getRadioButton();

	for (i=0; i<wellName.length; i++) {
		fileCheckbox[i]=Dialog.getCheckbox();
		if (selectionMode=="Select All") {
			fileCheckbox[i]=true;
		} else if (selectionMode=="Exclude") {
			if (fileCheckbox[i]==true) {
				fileCheckbox[i]=false;
			} else {
				fileCheckbox[i]=true;
			}
		}
	}

	// check that at least one well have been selected
	checkSelection = 0;
	for (i=0; i<nWells; i++) {
		checkSelection += fileCheckbox[i];
	}

	if (checkSelection == 0) {
		exit("There is no well selected");
	}

	// start
	resultsLength=checkSelection*fieldsxwell;
	row=newArray(resultsLength);
	column=newArray(resultsLength);
	field=newArray(resultsLength);
	mean_std_ratio=newArray(resultsLength);
	satPix=newArray(resultsLength);
	maxCount=newArray(resultsLength);
	totalArea=newArray(resultsLength);
	areaFraction=newArray(resultsLength);
	monolayerArea=newArray(resultsLength);
	trackerCount=newArray(resultsLength);
	trackerRatio=newArray(resultsLength);
	count=0;

	setBatchMode(true);
	print("Running analysis");
	start=getTime();
	count_print=0;
	for (i=0; i<nWells; i++) {
		if (fileCheckbox[i]) {
			for (j=0; j<fieldName.length; j++) {
				print("\\Update1:"+wellName[i]+" (fld " +fieldName[j] + ") " + count+1+"/"+resultsLength);
				elapsed=round((getTime()-start)/1000);
				expected=elapsed/(count_print+1)*resultsLength;
				print("\\Update2:Elapsed time "+hours_minutes_seconds(elapsed));
				print("\\Update3:Estimated time "+hours_minutes_seconds(expected));
				count_print++;
				counterstain=wellName[i]+"(fld "+fieldName[j]+" wv "+counterstainingChannel+ " - "+counterstainingChannel+").tif";
				tracker=wellName[i]+"(fld "+fieldName[j]+" wv "+trackerChannel+ " - "+trackerChannel+").tif";
				row[count]=substring(wellName[i], 0, 1);
				column[count]=substring(wellName[i], 4, 6);
				field[count]=fieldName[j];
				open(dir+File.separator+counterstain);
				open(dir+File.separator+tracker);
				imageBitDepth=bitDepth();
				if (imageBitDepth != 8) run("8-bit");
				
				// quality control: blurring
				selectImage(counterstain);
				run("Duplicate...", "title=QC_blur");
				imageBitDepth=bitDepth();
				if (imageBitDepth != 8) run("8-bit");
				
				getStatistics(areaImage, meanImage, minImage, maxImage, stdImage, histogramImage);
				mean_std_ratio[count]=meanImage/stdImage;
				
				// quality control: % sat pixels
				rename("QC_sat");
				run("Set Measurements...", "area_fraction display redirect=None decimal=2");
				setThreshold(255, 255);
				run("Measure");
				satPix[count]=getResult("%Area", 0);
				run("Clear Results");
				
				// quality control: count
				selectImage(counterstain);
				run("Duplicate...", "title=QC_count");
				run("Smooth");
				run("Find Maxima...", "prominence=50 output=Count");
				maxCount[count]=getResult("Count", 0);
				run("Clear Results");
				
				// quality control & measurements: monolayer
				selectImage(counterstain);
				imageBitDepth=bitDepth();
				if (imageBitDepth != 8) run("8-bit");
				totalArea[count]=areaImage;
				run("Clear Results");
				run("Maximum...", "radius="+maximumRadius);
				thresholdFraction(thresholdCounterstain);
				run("Set Measurements...", "area_fraction display redirect=None decimal=2");
				setThreshold(255, 255);
				run("Measure");
				areaFraction[count]=getResult("%Area", 0)/100;
				monolayerArea[count]=totalArea[count]*areaFraction[count]*pow(10, -6);
				run("Clear Results");

				// tracker count
				selectImage(tracker);
				run("Find Maxima...", "prominence="+prominence+" output=List");
				nMaxima=nResults;
				x=newArray(nMaxima);
				y=newArray(nMaxima);
				for (k=0; k<nMaxima; k++) {
					x[k]=getResult("X", k);
					y[k]=getResult("Y", k);
				}					
				thresholdFraction (thresholdTracker);
				run("Make Binary");				
				if (nMaxima>1) {
					getDimensions(widthTracker, heightTracker, channelsTracker, slicesTracker, framesTracker);
					newImage("Seeds", "8-bit white", widthTracker, heightTracker, 1);
					for (k=0; k<nMaxima; k++) {
						setPixel(x[k], y[k], 0);
					}
					run("Voronoi");
					setThreshold(0, 0);
					run("Make Binary");
					imageCalculator("AND create", tracker, "Seeds");
				}
				run("Analyze Particles...", "size="+minSize+"-Infinity pixel exclude add");
				trackerCount[count]=nResults;
				trackerRatio[count]=trackerCount[count]/(monolayerArea[count]);
				tracker_roi_count=roiManager("count");
				if (saveROIs == "Yes" && tracker_roi_count != 0) {
					roiManager("deselect");
					roiManager("save", dir+File.separator+tracker+"_ROI.zip");
					roiManager("reset");
				}

				// close
				run("Close All");
				selectWindow("Results");
				run("Close");
				roiManager("reset");
				count++;
			}
		}
	}
	setBatchMode(false);
	elapsed=round((getTime()-start)/1000);
	print("\\Update0:End of process");
	print("\\Update1:Elapsed time "+hours_minutes_seconds(elapsed));
	print("\\Update2:Saving results");
	print("\\Update3:");

	//normalize max count
	maxCount=normalizeData(maxCount);
	
	// results table
	title1 = "Results table";
	title2 = "["+title1+"]";
	f = title2;
	run("Table...", "name="+title2+" width=500 height=500");
	print(f, "\\Headings:n\tRow\tColumn\tField\tMean/s.d.\t%SatPix\tMaxCount\tMonoAreaFraction\tCells\tMonolayerArea(mm2)\tCells/mm2");
	for (i=0; i<resultsLength; i++) {
		print(f, i+1 + "\t" + row[i]+ "\t" + column[i] + "\t" + field[i] + "\t" + mean_std_ratio[i] + "\t" + satPix[i] + "\t" + maxCount[i] + "\t" + areaFraction[i] + "\t" + trackerCount[i] + "\t" + monolayerArea[i] + "\t" + trackerRatio[i]);
	}
	// save as TXT
	saveAs("Text", dir+File.separator+"ResultsTable_"+projectName+".csv");
	selectWindow("Results table");
	run("Close");
	print("\\Update2:Analysis successfully completed");
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function thresholdFraction (fraction) {
	run("32-bit");
	run("Enhance Contrast...", "saturated=0.1 normalize");
	setThreshold(fraction, 1);
	run("Make Binary");
}

function hours_minutes_seconds(seconds) {
	hours=seconds/3600;
	hours_floor=floor(hours);
	remaining_seconds=seconds-(hours_floor*3600);
	remaining_minutes=remaining_seconds/60;
	minutes_floor=floor(remaining_minutes);
	remaining_seconds=remaining_seconds-(minutes_floor*60);
	hours_floor=d2s(hours_floor, 0);
	minutes_floor=d2s(minutes_floor, 0);
	remaining_seconds=d2s(remaining_seconds, 0);
	if (lengthOf(hours_floor) < 2) hours_floor="0"+hours_floor;
	if (lengthOf(minutes_floor) < 2) minutes_floor="0"+minutes_floor;
	if (lengthOf(remaining_seconds) < 2) remaining_seconds="0"+remaining_seconds;
	return hours_floor+":"+minutes_floor+":"+remaining_seconds;
}

function normalizeData (array) {
	Array.getStatistics(array, min, max, mean, stdDev);
	for (a=0; a<array.length; a++) {
		array[a]=(array[a]-min)/(max-min);
	}
	return array;
}
}