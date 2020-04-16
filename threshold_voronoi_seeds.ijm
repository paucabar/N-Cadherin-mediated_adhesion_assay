id=getImageID();
run("Duplicate...", "title=Mask");
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

setThreshold(30, 255);
run("Make Binary");

if (n>1) {
	getDimensions(width, height, channels, slices, frames);
	newImage("Seeds", "8-bit white", width, height, 1);
	for (i=0; i<n; i++) {
		setPixel(x[i], y[i], 0);
	}
	run("Voronoi");
	setThreshold(0, 0);
	run("Make Binary");
	imageCalculator("AND create", "Mask","Seeds");
}

run("Analyze Particles...", "size=4-Infinity pixel exclude add");

selectImage(id);
roiManager("show all with labels");
