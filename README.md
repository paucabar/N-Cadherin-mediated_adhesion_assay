# Cell Adhesion Assay

## Description



## Installation

1. Start [FIJI](https://fiji.sc/)
2. Start the **ImageJ Updater** (<code>Help > Update...</code>)
3. Click on <code>Manage update sites</code>
4. Click on <code>Add update site</code> (_see Figure 1_)
5. A new blank row is to be created at the bottom of the update sites list
6. Type **NeuroMol Lab** in the **Name** column
7. Type **http://sites.imagej.net/Paucabar/** in the **URL** column
8. <code>Close</code> the update sites window
9. <code>Apply changes</code>
10. Restart FIJI
11. Check if <code>NeuroMol Lab</code> appears now in the <code>Plugins</code> dropdown menu (note that it will be placed at the bottom of the dropdown menu)

![Snag_29e5797f](https://user-images.githubusercontent.com/39589980/58595799-27f8a500-8272-11e9-8c32-1c72b591c702.png)

**Figure 1.** _Manage update sites_ window. An update site is a web space used by the _ImageJ Updater_ which enables users to share their macros, scripts and plugins. By adding an update site the macros, scripts and plugins maintained there will be installed and updated just like core ImageJ plugins.

## Test Dataset

You can [download](https://drive.google.com/drive/folders/1TwMUoJYkDqVXPFvARh_2Ig_VMTkTkx9a?usp=sharing) an image dataset.

## Usage

### Downsizing (optional)

1. Run the **Post-Acquisition Binning** macro (<code>Plugins > NeuroMol Lab > other macros > Post-Acquisition Binning</code>)
2. Select the directory containing the images (.tif files)
3. Select the _binning_ mode (2x2, 4x4)
4. Run
5. Downsized images will be saved in a new subfolder within the original directory

### Pre-analysis mode

1. Run the **Cell Adhesion** macro (<code>Plugins > NeuroMol Lab > Cell Adhesion > Cell Adhesion</code>)
2. Select the directory containing the images (.tif files)
3. Check **Load project** to use a pre-stablished parameter dataset
4. Ignore the **Save ROIs** option
5. Ok
6. Adjust the parameters. Know more about the parameters of the workflow on the **wiki page (not yet)**
7. Ok
8. Select an image (well and field-of-view) to test the parameters
9. Check the output (_see Figure 2_)
10. **Pre-analysis mode** will ask to test a new image, and will continue until the user asks to stop

![image](https://user-images.githubusercontent.com/39589980/79636550-c8043900-8178-11ea-9485-97235f933ec0.png)

**Figure 2.** _Pre-analysis mode_ output. The macro generates a stack composed of two images. On one hand, the merge of the counterstain (blue) and the cell tracker (red) (**left**). On the other hand, the merge of the counterstain (gray), the additionally segmented monolayer (green) and the remaining background (blue) (**right**). Finally, when detected, ROI Manager will store the set tracker-labbeled adhered cells, shown as a yellow, numbered outline (**left**)

### Analysis mode

1. Run the **Cell Adhesion** macro (<code>Plugins > NeuroMol Lab > Cell Adhesion</code>)
2. Select the directory containing the images (.tif files)
3. Check **Load project** to use a pre-stablished parameter dataset
4. Check **Save ROIs** to store the regions of interest of the counted cells
5. Ok
6. Adjust the parameters. Know more about the parameters of the workflow on the **wiki page (not yet)**
7. Run
8. A series of new files will be saved within the selected directory: a parameter (.txt) file, a results table (.csv) file and the ROI (.zip) files (if checked)

## Contributors

[Pau Carrillo-Barberà](https://github.com/paucabar)

## License

