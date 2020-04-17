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
#@ String (label="<html>Load pre-established<br>parameter dataset:</html>", choices={"No", "Yes"}, persist=true, style="radioButtonHorizontal") importPD
#@ String (label="<html>Save ROIs:</html>", choices={"No", "Yes"}, value="Yes", persist=true, style="radioButtonHorizontal") saveROIs
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Lab</b><br>ERI BIOTECMED, Universitat de València (Valencia, Spain)</font></html>", visibility=MESSAGE, persist=false) message

	//open pre-established parameter dataset
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

	//File management
	if (mode=="Analysis" || mode=="Pre-Analysis (parameter tweaking)") {
		//Identification of the TIF files
		//create an array containing the names of the files in the directory path
		list = getFileList(dir);
		Array.sort(list);
		tiffFiles=0;
	
		//count the number of TIF files
		for (i=0; i<list.length; i++) {
			if (endsWith(list[i], "tif")) {
				tiffFiles++;
			}
		}

		//check that the directory contains TIF files
		if (tiffFiles==0) {
			beep();
			exit("No tif files")
		}

		//create a an array containing only the names of the TIF files in the directory path
		tiffArray=newArray(tiffFiles);
		count=0;
		for (i=0; i<list.length; i++) {
			if (endsWith(list[i], "tif")) {
				tiffArray[count]=list[i];
				count++;
			}
		}

		//Extraction of the ‘well’ and ‘field’ information from the images’ filenames
		//calculate: number of wells, images per well, images per field and fields per well
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

		//Extraction of the ‘channel’ information from the images’ filenames
		//create an array containing the names of the channels
		channels=newArray(imagesxfield);		
		for (i=0; i<channels.length; i++) {
			index1=indexOf(tiffArray[i], "wv ");
			index2=lastIndexOf(tiffArray[i], " - ");
			channels[i]=substring(tiffArray[i], index1+3, index2);
		}


		//set some parameter menu arrays
		threshold=getList("threshold.methods");

		//Extract values from a parameter dataset file
		if(importPD=="Yes") {
			projectName=parameters[0];
			counterstainingChannel=parameters[1];
			trackerChannel=parameters[2];
			enhanceCounterstaining=parameters[3];
			meanCounterstaining=parameters[4];
			medianCounterstaining=parameters[5];
			thresholdMethod=parameters[6];
			dilateIter=parameters[7];
			rollingTracker=parameters[8];
			enhanceTracker=parameters[9];
			meanTracker=parameters[10];
			medianTracker=parameters[11];
			noiseToleranceTracker=parameters[12];
		} else {
			//default parameters
			projectName="Project";
			counterstainingChannel=channels[0];
			trackerChannel=channels[0];
			enhanceCounterstaining=0.1;
			meanCounterstaining=2;
			medianCounterstaining=10;
			thresholdMethod="Triangle";
			dilateIter=50;
			rollingTracker=100;
			enhanceTracker=0.1;
			meanTracker=0;
			medianTracker=15;
			noiseToleranceTracker=75;
		}
	
		//'Select Parameters' dialog box
		//edit parameters
		title = "Select Parameters";
		Dialog.create(title);
		Dialog.addString("Project", projectName, 40);
		Dialog.setInsets(0, 170, 0);
		Dialog.addMessage("CHANNEL SELECTION:");
		Dialog.addChoice("Counterstaining", channels, counterstainingChannel);
		Dialog.addChoice("Tracker", channels, trackerChannel);
		Dialog.setInsets(0, 170, 0);
		Dialog.addMessage("MONOLAYER PARAMETERS:");
		Dialog.addNumber("Saturated pixels (normalize)", enhanceCounterstaining, 1, 3, "%");
		Dialog.addNumber("Mean (sigma)", meanCounterstaining, 0, 2, "pixels");
		Dialog.addNumber("Median (sigma)", medianCounterstaining, 0, 2, "pixels");
		Dialog.addChoice("Threshold method", threshold, thresholdMethod);
		Dialog.addNumber("Dilate", dilateIter, 0, 3, "iterations");
		Dialog.setInsets(0, 170, 0);
		Dialog.addMessage("TRACKER PARAMETERS:");
		Dialog.addNumber("Subtract Background (rolling)", rollingTracker);
		Dialog.addNumber("Saturated pixels (normalize)", enhanceTracker, 1, 3, "%");
		Dialog.addNumber("Mean (sigma)", meanTracker, 0, 2, "pixels");
		Dialog.addNumber("Median (sigma)", medianTracker, 0, 2, "pixels");
		Dialog.addSlider("Noise Tolerance", 0, 255, noiseToleranceTracker);
		Dialog.setInsets(0, 170, 0);
		Dialog.show()
		projectName=Dialog.getString();
		counterstainingChannel=Dialog.getChoice();
		trackerChannel=Dialog.getChoice();
		enhanceCounterstaining=Dialog.getNumber();
		meanCounterstaining=Dialog.getNumber();
		medianCounterstaining=Dialog.getNumber();
		thresholdMethod=Dialog.getChoice();
		dilateIter=Dialog.getNumber();
		rollingTracker=Dialog.getNumber();
		enhanceTracker=Dialog.getNumber();
		meanTracker=Dialog.getNumber();
		medianTracker=Dialog.getNumber();
		noiseToleranceTracker=Dialog.getNumber();
	
		//check the parameter selection
		if(counterstainingChannel==trackerChannel) {
			beep();
			exit("Counterstaining ["+counterstainingChannel+"] and Tracker ["+trackerChannel+"] channels can not be the same")
		}
		
		//Create a parameter dataset file
		title1 = "Parameter dataset";
		title2 = "["+title1+"]";
		f = title2;
		run("Table...", "name="+title2+" width=500 height=500");
		print(f, "Project\t" + projectName);
		print(f, "Counterstaining channel\t" + counterstainingChannel);
		print(f, "Tracker channel\t" + trackerChannel);
		print(f, "Enhance (counterstaining)\t" + enhanceCounterstaining);
		print(f, "Mean (counterstaining)\t" + meanCounterstaining);
		print(f, "Median (counterstaining)\t" + medianCounterstaining);
		print(f, "Threshold method\t" + thresholdMethod);
		print(f, "Dilate (iterations)\t" + dilateIter);
		print(f, "Rolling (tracker)\t" + rollingTracker);
		print(f, "Enhance (tracker)\t" + enhanceTracker);
		print(f, "Mean (tracker)\t" + meanTracker);
		print(f, "Median (tracker)\t" + medianTracker);
		print(f, "Noise tolerance (tracker)\t" + noiseToleranceTracker);

		//save as txt
		saveAs("txt", dir+"\\"+projectName);
		selectWindow(title1);
		run("Close");
		
		//create an array containing the well codes
		for (i=0; i<nWells; i++) {
			wellName[i]=well[i*imagesxwell];
		}

		//create an array containing the field codes
		fieldName=newArray(fieldsxwell);
		for (i=0; i<fieldsxwell; i++) {
			fieldName[i]=i+1;
			fieldName[i]=d2s(fieldName[i], 0);
			while (lengthOf(fieldName[i])<3) {
				fieldName[i]="0"+fieldName[i];
			}
		}
	}
	setOption("BlackBackground", false);

	//Pre-Analysis workflow
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
			//Merge
			open(dir+File.separator+counterstain);
			run("Duplicate...", "title=Nuclei");
			run("Duplicate...", "title=Nuclei_8-bit");
			run("8-bit");
			open(dir+File.separator+tracker);
			run("Duplicate...", "title=Find_Maxima");
			run("Duplicate...", "title=Maxima_Filter");
			selectImage(counterstain);
			run("Enhance Contrast...", "saturated=0.1 normalize");
			selectImage(tracker);
			run("Enhance Contrast...", "saturated=0.1 normalize");
			run("Merge Channels...", "c1=["+tracker+"] c3=["+counterstain+"] keep");
			rename("1 - Merge");
			//Monolayer
			selectImage("Nuclei");
			run("Enhance Contrast...", "saturated="+enhanceCounterstaining+" normalize");
			run("Mean...", "radius="+meanCounterstaining);
			run("Median...", "radius="+medianCounterstaining);
			setAutoThreshold(thresholdMethod+" dark");
			run("Convert to Mask");
			resetThreshold();
			run("Duplicate...", "title=Monolayer");
			run("Options...", "iterations="+dilateIter+" count=1 do=Dilate");
			run("Duplicate...", "title=Background");
			run("Invert");
			imageCalculator("XOR create", "Nuclei","Monolayer");
			rename("Monolayer_no-nuclei");
			run("Merge Channels...", "c3=Background c2=Monolayer_no-nuclei c4=[Nuclei_8-bit] keep");
			rename("2 - M/B");
			//Tracker-labeled cells
			selectWindow("Maxima_Filter");
			run("8-bit");
			run("Subtract Background...", "rolling=50");
			run("Enhance Contrast...", "saturated=0.1 normalize");
			run("Find Maxima...", "prominence=75 output=Count");
			maxFilterTracker=getResult("Count", 0);
			run("Select None");
			run("Clear Results");
			selectWindow("Find_Maxima");
			run("Point Tool...", "type=Dot color=Magenta size=Large label counter=0");
			setOption("ScaleConversions", true);
			run("8-bit");
			run("Subtract Background...", "rolling="+rollingTracker);
			run("Enhance Contrast...", "saturated="+enhanceTracker+" normalize");
			run("Mean...", "radius="+meanTracker);
			run("Median...", "radius="+medianTracker);
			run("Find Maxima...", "prominence="+noiseToleranceTracker+" output=List");
			selectWindow(tracker);
			run("Duplicate...", "title=tracker_final");
			//close
			close("Nuclei");
			close("Nuclei_8-bit");
			close("Monolayer");
			close("Background");
			close("Monolayer_no-nuclei");
			close("Find_Maxima");
			close("Maxima_Filter");
			close(counterstain);
			close(tracker);
			//Stack
			run("Images to Stack", "name=Stack title=[] use");
			setBatchMode(false);
			x=newArray(nResults);
			y=newArray(nResults);
			run("Select None");
			if (maxFilterTracker<1000) {
				for (i=0; i<x.length; i++) {
					x[i]=getResult("X", i);
					y[i]=getResult("Y", i);
					makePoint(x[i], y[i], "large cyan dot");
					roiManager("Add");
				}
				roiManager("Show All");
			}
			selectWindow("Results");
			run("Close");
			waitForUser("Click OK to exit");
			run("Close All");
			if (isOpen("ROI Manager")) {
				selectWindow("ROI Manager");
				run("Close");
			}
			radioButtonItems=newArray("Yes", "No");
			Dialog.create("Test Mode");
			Dialog.addRadioButtonGroup("Test other field-of-view:", radioButtonItems, 1, 2, radioButtonItems[0]);
			Dialog.show();
			keepTestMode=Dialog.getRadioButton();
			if (keepTestMode=="No") {
				testMode=false;
			}
		}
	}

	//Analysis workflow
	if(mode=="Analysis") {
		//'Well Selection' dialog box
		selectionOptions=newArray("Select All", "Include", "Exclude");
		fileCheckbox=newArray(nWells);
		selection=newArray(nWells);
		title = "Select Wells";
		Dialog.create(title);
		Dialog.addRadioButtonGroup("", selectionOptions, 3, 1, selectionOptions[0]);
		Dialog.addCheckboxGroup(sqrt(nWells) + 1, sqrt(nWells) + 1, wellName, selection);
		//Dialog.addCheckboxGroup(8, 12, wellName, selection);
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
	
		//check that at least one well have been selected
		checkSelection = 0;
		for (i=0; i<nWells; i++) {
			checkSelection += fileCheckbox[i];
		}
	
		if (checkSelection == 0) {
			exit("There is no well selected");
		}

		//start
		resultsLength=checkSelection*fieldsxwell;
		row=newArray(resultsLength);
		column=newArray(resultsLength);
		field=newArray(resultsLength);
		mean_std_ratio=newArray(resultsLength);
		satPix=newArray(resultsLength);
		maxCount=newArray(resultsLength);
		noContClass=newArray(resultsLength);
		totalArea=newArray(resultsLength);
		areaFraction=newArray(resultsLength);
		monolayerArea=newArray(resultsLength);
		trackerCount=newArray(resultsLength);
		trackerRatio=newArray(resultsLength);
		count=0;
		setBatchMode(true);
		roiManager("reset");
		print("\\Clear");
		print("Running analysis");
		for (i=0; i<nWells; i++) {
			if (fileCheckbox[i]) {
				for (j=0; j<fieldName.length; j++) {
					print(wellName[i]+" (fld " +fieldName[j] + ") " + count+1+"/"+resultsLength);
					counterstain=wellName[i]+"(fld "+fieldName[j]+" wv "+counterstainingChannel+ " - "+counterstainingChannel+").tif";
					tracker=wellName[i]+"(fld "+fieldName[j]+" wv "+trackerChannel+ " - "+trackerChannel+").tif";
					row[count]=substring(wellName[i], 0, 1);
					column[count]=substring(wellName[i], 4, 6);
					field[count]=fieldName[j];
					open(dir+File.separator+counterstain);
					open(dir+File.separator+tracker);
					
					//quality control: blurring
					getStatistics(areaImage, meanImage, minImage, maxImage, stdImage, histogramImage);
					mean_std_ratio[count]=meanImage/stdImage;
					
					//quality control: % sat pixels
					selectImage(counterstain);
					run("Duplicate...", "title=QC_sat");
					run("8-bit");
					run("Set Measurements...", "area_fraction display redirect=None decimal=2");
					setThreshold(255, 255);
					run("Measure");
					satPix[count]=getResult("%Area", 0);
					run("Clear Results");
					
					//quality control: no content
					selectImage(counterstain);
					run("Duplicate...", "title=QC_nc1");
					run("8-bit");
					run("Gaussian Blur...", "sigma=1");
					run("Duplicate...", "title=QC_nc2");
					//run("Subtract Background...", "rolling=50");
					selectImage("QC_nc1");
					run("Find Maxima...", "prominence=30 output=Count");
					maxCount1=getResult("Count", 0);
					selectImage("QC_nc2");
					run("Enhance Contrast...", "saturated=0.4 normalize");
					run("Find Maxima...", "prominence=30 output=Count");
					maxCount2=getResult("Count", 1);
					maxCount[count]=maxCount1/maxCount2;
					run("Clear Results");
					
					//quality control & measurements: monolayer
					selectImage(counterstain);
					setOption("ScaleConversions", true);
					run("8-bit");
					totalArea[count]=areaImage;
					run("Clear Results");
					//run("Enhance Contrast...", "saturated="+enhanceCounterstaining+" normalize");
					//run("Mean...", "radius="+meanCounterstaining);
					//run("Median...", "radius="+medianCounterstaining);
					run("Maximum...", "radius=2");
					thresholdFraction(0.10);
					//run("Options...", "iterations="+dilateIter+" count=1 do=Dilate");
					run("Set Measurements...", "area_fraction display redirect=None decimal=2");
					setThreshold(255, 255);
					run("Measure");
					areaFraction[count]=getResult("%Area", 0);
					monolayerArea[count]=totalArea[count]*areaFraction[count];
					run("Clear Results");

					//tracker count
					selectImage(tracker);
					setOption("ScaleConversions", true);
					imageBitDepth=bitDepth();
					if (imageBitDepth != 8) run("8-bit");
					run("Find Maxima...", "prominence=30 output=List");
					nMaxima=nResults;
					x=newArray(nMaxima);
					y=newArray(nMaxima);
					for (k=0; k<nMaxima; k++) {
						x[k]=getResult("X", k);
						y[k]=getResult("Y", k);
					}
					
					thresholdFraction (0.1);
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
					
					run("Analyze Particles...", "size=5-Infinity pixel exclude add");
					trackerCount[count]=nResults;
					trackerRatio[count]=trackerCount[count]/(monolayerArea[count]*0.000001);
					tracker_roi_count=roiManager("count");
					if (saveROIs == "Yes" && tracker_roi_count != 0) {
						roiManager("deselect");
						roiManager("save", dir+File.separator+tracker+"_ROI.zip");
						roiManager("reset");
					}

					//close
					run("Close All");
					selectWindow("Results");
					run("Close");
					count++;
				}
			}
		}
		setBatchMode(false);
		
		//results table
		title1 = "Results table";
		title2 = "["+title1+"]";
		f = title2;
		run("Table...", "name="+title2+" width=500 height=500");
		print(f, "\\Headings:n\tRow\tColumn\tField\tMean/s.d.\t%SatPix\tMaxCountRatio\tMonoAreaFraction\tCells\tMonolayerArea(mm2)\tCells/mm2");
		for (i=0; i<resultsLength; i++) {
			print(f, i+1 + "\t" + row[i]+ "\t" + column[i] + "\t" + field[i] + "\t" + mean_std_ratio[i] + "\t" + satPix[i] + "\t" + maxCount[i] + "\t" + areaFraction[i] + "\t" + trackerCount[i] + "\t" + monolayerArea[i] + "\t" + trackerRatio[i]);
		}
		//save as TXT
		saveAs("Text", dir+File.separator+"ResultsTable_"+projectName+".csv");
		selectWindow("Results table");
		//run("Close");
		print("End of process");
	}
}

function thresholdFraction (fraction) {
	bitDepthImage=bitDepth();
	upper=pow(2, bitDepthImage);
	setThreshold(fraction*upper, upper);
	run("Make Binary");
}
