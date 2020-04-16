id=getImageID();
setOption("ScaleConversions", true);
roiManager("reset");
imageBitDepth=bitDepth();
if (imageBitDepth != 8) run("8-bit");
run("Find Maxima...", "prominence=30 output=List");
n=nResults;
x=newArray(n);
y=newArray(n);
for (i=0; i<n; i++) {
	x[i]=getResult("X", i);
	y[i]=getResult("Y", i);
}

for (i=0; i<n; i++) {
	selectImage(id);
	doWand(x[i], y[i], 50, "8-connected");
	run("Create Mask");
	run("Set Measurements...", "area area_fraction display redirect=None decimal=2");
	rename("Masks-"+i);
	run("Analyze Particles...", "display summarize");
}

selectWindow("Results");
run("Close");
IJ.renameResults("Summary", "Results");
countClose=0;
for (i=0; i<n; i++) {
	if (getResult("%Area", i) > 4) {
		close("Masks-"+i);
		countClose++;
	}
}

maskImages=n-countClose;
if (maskImages > 1) {
	run("Images to Stack", "name=Stack title=Masks use");
	run("Z Project...", "projection=[Max Intensity]");
	getDimensions(width, height, channels, slices, frames);
	newImage("Seeds", "8-bit white", width, height, 1);
	for (i=0; i<n; i++) {
		selectImage("MAX_Stack");
		value=getPixel(x[i], y[i]);
		if (value == 255) {
			selectImage("Seeds");
			setPixel(x[i], y[i], 0);
		}
	}
	selectImage("Seeds");
	run("Voronoi");
	setThreshold(0, 0);
	run("Make Binary");
	imageCalculator("AND create", "MAX_Stack","Seeds");
	run("Analyze Particles...", "size=4-Infinity pixel  exclude add");
} else if (maskImages == 1) {
	remainingImages=getList("image.titles");
	i=0;
	do {
		found=startsWith(remainingImages[i], "Masks-");
		i++;
	} while (!found);
	run("Analyze Particles...", "size=4-Infinity pixel add");
} else {
	print("no remaining masks");
}
