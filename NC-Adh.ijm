/*
 * Cell_proliferationHCS
 * Authors: Pau Carrillo-Barberà, José M. Morante-Redolat, José F. Pertusa
 * Department of Cellular & Functional Biology
 * University of Valencia (Valencia, Spain)
 * 
 * November 2018
 * Last update: July 07, 2019
 */

macro "NC-Adh" {

//choose a macro mode and a directory
#@ String (label=" ", value="<html><font size=6><b>High Content</font><br><font color=teal>N-Cadherin-mediated Adhesion</font></b></html>", visibility=MESSAGE, persist=false) heading
#@ String(label="Select mode:", choices={"Analysis", "Pre-Analysis (parameter tweaking)"}, style="radioButtonVertical") mode
#@ File(label="Select a directory:", style="directory") dir
#@ String (label=" ", value="<html><img src=\"http://oi64.tinypic.com/ekrmvs.jpg\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Lab</b><br>ERI BIOTECMED, Universitat de València (Valencia, Spain)</font></html>", visibility=MESSAGE, persist=false) message

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

		//‘Pre-Analysis (parameter tweaking)’ and ‘Analysis’ parameterization
		//browse a parameter dataset file (optional) & define output folder and dataset file names
		dirName="Output - " + File.getName(dir);
		resultsName="ResultsTable - " + File.getName(dir);
		radioButtonItems=newArray("Yes", "No");
		//‘Input & Output’ dialog box
		Dialog.create("Input & Output");
		Dialog.addRadioButtonGroup("Browse a pre-established parameter dataset:", radioButtonItems, 1, 2, "No");
		Dialog.addMessage("Output folder:");
		Dialog.addString("", dirName, 40);
		Dialog.addMessage("Output parameter dataset file (txt):");
		Dialog.addString("", "parameter_dataset", 40);
		if(mode=="Analysis") {
			Dialog.addMessage("Results table:");
			Dialog.addString("", resultsName, 40);
		}
		html = "<html>"
			+"Having generated a <b><font color=black>parameter dataset</font></b> txt file using the<br>"
			+"<b><font color=red>Pre-Analysis (parameter tweaking)</font></b> mode it is possible to<br>"
			+"browse the file to apply the pre-established parameters";
		Dialog.addHelp(html);
		Dialog.show()
		browseDataset=Dialog.getRadioButton();
		outputFolder=Dialog.getString();
		datasetFile=Dialog.getString();
		if(mode=="Analysis") {
			resultsTableName=Dialog.getString();
		}

		//set some parameter menu arrays
		enhanceContrastOptions=newArray("0", "0.1", "0.2", "0.3", "0.4", "None");
		threshold=getList("threshold.methods");

		//Extract values from a parameter dataset file
		if(browseDataset=="Yes") {
			parametersDatasetPath=File.openDialog("Choose the parameter dataset file to Open:");
			//parameter selection (pre-established)
			parametersString=File.openAsString(parametersDatasetPath);
			parameterRows=split(parametersString, "\n");
			parameters=newArray(parameterRows.length);
			for(i=0; i<parameters.length; i++) {
				parameterColumns=split(parameterRows[i],"\t"); 
				parameters[i]=parameterColumns[1];
			}
			channels[0]=parameters[0];
			channels[1]=parameters[1];
			rollingCounterstaining=parameters[2];
			enhanceCounterstaining=parameters[3];
			maximumFilter=parameters[4];
			gaussianCounterstaining=parameters[5];
			thresholdMin=parameters[6];
			thresholdMax=parameters[7];
			rollingTracker=parameters[8];
			enhanceTracker=parameters[9];
			medianTracker=parameters[10];
			meanTracker=parameters[11];
			noiseToleranceTracker=parameters[12];
		} else {
			//default parameters
			rollingCounterstaining=50;
			enhanceCounterstaining=enhanceContrastOptions[1];
			maximumFilter=20;
			gaussianCounterstaining=20;
			thresholdMin=25;
			thresholdMax=255;
			rollingTracker=50;
			enhanceTracker=enhanceContrastOptions[1];
			medianTracker=0;
			meanTracker=10;
			noiseToleranceTracker=75;
		}
	
		//'Select Parameters' dialog box
		//edit parameters
		title = "Select Parameters";
		Dialog.create(title);
		Dialog.setInsets(0, 170, 0);
		Dialog.addMessage("CHANNEL SELECTION:");
		Dialog.addChoice("Counterstaining", channels, channels[0]);
		Dialog.addChoice("Tracker", channels, channels[0]);
		Dialog.setInsets(0, 170, 0);
		Dialog.addMessage("MONOLAYER WORKFLOW:");
		Dialog.addNumber("Subtract Background (rolling)", rollingCounterstaining);
		Dialog.addChoice("Enhance Contrast", enhanceContrastOptions, enhanceContrastOptions[4]);
		Dialog.addNumber("Maximum Filter (sigma)", maximumFilter);
		Dialog.addNumber("Gaussian Blur (sigma)", gaussianCounterstaining);
		Dialog.addSlider("setThreshold (min)", 0, 255, thresholdMin);
		Dialog.addSlider("setThreshold (max)", 0, 255, thresholdMax);
		Dialog.setInsets(0, 170, 0);
		Dialog.addMessage("TRACKER WORKFLOW:");
		Dialog.addNumber("Subtract Background (rolling)", rollingTracker);
		Dialog.addChoice("Enhance Contrast", enhanceContrastOptions, enhanceContrastOptions[5]);
		Dialog.addNumber("Median (sigma)", medianTracker);
		Dialog.addNumber("Mean (sigma)", meanTracker);
		Dialog.addSlider("Noise Tolerance", 0, 255, noiseToleranceTracker);
		Dialog.show()
		channels[0]=Dialog.getChoice();
		channels[1]=Dialog.getChoice();
		rollingCounterstaining=Dialog.getNumber();
		enhanceCounterstaining=Dialog.getChoice();
		maximumFilter=Dialog.getNumber();
		gaussianCounterstaining=Dialog.getNumber();
		thresholdMin=Dialog.getNumber();
		thresholdMax=Dialog.getNumber();
		rollingTracker=Dialog.getNumber();
		enhanceTracker=Dialog.getChoice();
		medianTracker=Dialog.getNumber();
		meanTracker=Dialog.getNumber();
		noiseToleranceTracker=Dialog.getNumber();
	
		//check the parameter selection
		if(channels[0]==channels[1]) {
			beep();
			exit("Counterstaining ["+channels[0]+"] and Tracker ["+channels[1]+"] channels can not be the same")
		} else if (thresholdMin>thresholdMax) {
			beep();
			exit("setThreshold(min) ["+thresholdMin+"] must be greater than ["+thresholdMax+"]")
		}

		//Create an output folder
		outputFolderPath=dir+"\\"+outputFolder;
		File.makeDirectory(outputFolderPath);
		
		//Create a parameter dataset file
		title1 = "Parameter dataset";
		title2 = "["+title1+"]";
		f = title2;
		run("Table...", "name="+title2+" width=500 height=500");
		print(f, "Nuclei\t" + channels[0]);
		print(f, "Nucleoside analogue\t" + channels[1]);
		print(f, "Rolling (counterstaining)\t" + rollingCounterstaining);
		print(f, "Enhance (counterstaining)\t" + enhanceCounterstaining);
		print(f, "Maximum (counterstaining)\t" + maximumFilter);
		print(f, "Gaussian (counterstaining)\t" + gaussianCounterstaining);
		print(f, "setThreshold_min (counterstaining)\t" + thresholdMin);
		print(f, "setThreshold_max (counterstaining)\t" + thresholdMax);
		print(f, "Rolling (tracker)\t" + rollingTracker);
		print(f, "Enhance (tracker)\t" + enhanceTracker);
		print(f, "Median (tracker)\t" + medianTracker);
		print(f, "Mean (tracker)\t" + meanTracker);
		print(f, "Noise tolerance (tracker)\t" + noiseToleranceTracker);

		//save as TXT
		saveAs("txt", outputFolderPath+"\\"+datasetFile);
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
			counterstain=well+"(fld "+field+" wv "+channels[0]+ " - "+channels[0]+").tif";
			tracker=well+"(fld "+field+" wv "+channels[1]+ " - "+channels[1]+").tif";
			//Merge
			open(dir+File.separator+counterstain);
			run("Duplicate...", "title=Nuclei");
			run("Duplicate...", "title=Nuclei_8-bit");
			run("8-bit");
			open(dir+File.separator+tracker);
			run("Duplicate...", "title=Find_Maxima");
			selectImage(counterstain);
			run("Enhance Contrast...", "saturated=0.1 normalize");
			selectImage(tracker);
			run("Enhance Contrast...", "saturated=0.1 normalize");
			run("Merge Channels...", "c1=["+tracker+"] c3=["+counterstain+"] keep");
			rename("1 - Merge");
			//Monolayer
			selectImage("Nuclei");
			run("Enhance Contrast...", "saturated=0.1 normalize");
			run("Mean...", "radius=2");
			run("Median...", "radius=10");
			setAutoThreshold("Triangle dark");
			run("Convert to Mask");
			resetThreshold();
			run("Duplicate...", "title=Monolayer");
			run("Options...", "iterations=50 count=1 do=Dilate");
			run("Duplicate...", "title=Background");
			run("Invert");
			imageCalculator("XOR create", "Nuclei","Monolayer");
			rename("Monolayer_no-nuclei");
			run("Merge Channels...", "c3=Background c2=Monolayer_no-nuclei c4=[Nuclei_8-bit] keep");
			rename("2 - M/B");
			//Tracker-labeled cells
			selectWindow("Find_Maxima");
			run("Point Tool...", "type=Dot color=Magenta size=Large label counter=0");
			setOption("ScaleConversions", true);
			run("8-bit");
			run("Subtract Background...", "rolling=100");
			run("Enhance Contrast...", "saturated=0.1 normalize");
			run("Mean...", "radius=5");
			run("Find Maxima...", "prominence=100 output=[Point Selection]");
			run("Flatten");
			rename("3 - Tracker_Count");
			//close
			close("Nuclei");
			close("Nuclei_8-bit");
			close("Monolayer");
			close("Background");
			close("Monolayer_no-nuclei");
			close("Find_Maxima");
			close(counterstain);
			close(tracker);
			//Make Montage
			run("Images to Stack", "name=Stack title=[] use");
			waitForUser("Click OK to exit");
			run("Close All");
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



		
		//results table
		resultsTable("Results table", channels[2], channels[3], dataname, nucleosideAnalogue, marker1, marker2);
		//save as TXT
		saveAs("txt", outputFolderPath+"\\"+resultsTableName);
		selectWindow("Results table");
		run("Close");
		print("End of process");
		print("Find the results table at:");
		print(outputFolderPath);
	}

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//User-defined functions
	
	function maximaFilter(image) { //MAXIMAFILTER function beginning
		selectImage(image);
		run("Duplicate...", "title="+image+"-MaximaFilter");
		run("Subtract Background...", "rolling=50");
		run("Enhance Contrast...", "saturated=0.4 normalize");
		run("Find Maxima...", "noise=100 output=[Count]");
		localMaxima=getResult("Count", 0);
		run("Clear Results");
		close(image+"-MaximaFilter");
		return localMaxima;
	} //MAXIMAFILTER function ending

	function resultsTable(title, m1, m2, nameArray, nucleosideArray, m1Array, m2Array) { //RESULTSTABLE function beginning
		title1 = title;
		title2 = "["+title1+"]";
		f = title2;
		run("Table...", "name="+title2+" width=500 height=500");
		print(f, "\\Headings:n\tImage\tS-phase\t"+m1+"\t"+m2);
		for (i=0; i<nucleosideArray.length; i++) {
			print(f, i+1 + "\t" + nameArray[i]+ "\t" + nucleosideArray[i] + "\t" + m1Array[i] + "\t" + m2Array[i]);
		}
	} //RESULTSTABLE function ending

	function cleanUp() { //CLEAN-UP function beginning
		if (isOpen("Results")) {
			selectWindow("Results");
			run("Close");
		}
		if (isOpen("Threshold")) {
			selectWindow("Threshold"); 
			run("Close");
		}
		while (nImages()>0) {
			selectImage(nImages());  
			run("Close");
		}
	} //CLEAN-UP function ending