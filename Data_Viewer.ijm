
columns=newArray("01", "02", "03", "04");
rows=newArray("A", "B");
newImage("data viewer", "8-bit white", 600, 400, 1);

for (i=1; i<=rows.length; i++) {
	for (j=1; j<=columns.length; j++) {
		setForegroundColor((j*1)*(i*60), 0, 0);
		makeRectangle(100*j, 100*i, 100, 100);
		fill();
	}
}



