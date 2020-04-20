# Cell Adhesion Assay

## Description

In order to evaluate the possible role of diverse secreted factors in the regulation of adhesion molecules (e.g. cadherins) it is possible to rely on functional, _ex vivo_, cellular assays (i.e., cell adhesion assays). To this aim, a cell line (e.g., fibroblasts) overexpressing the binding partner of the adhesion molecule of interest are grown until confluence in multiwell plates. Then, cells that have been pre-treated with the specific factor/s of interest, are labelled with a fluorescent tracker and seeded onto the monolayer. After a certain time, non-adhered cells are washed out by means of several washing steps. Finally, samples are fixed and stained with a nuclear dye.

Our assay has been deplyed to be imaged using the high content microscope IN Cell Analyzer 2000 (GE Healthcare), so the script takes as imput datasets acquired using this and other IN Cell Analyzer versions. It consists of an ImageJ macroinstruction which can be easily added and kept to date using the Fiji distribution of ImageJ, as explained above. The assay should include two channels per field-of-view. On one hand, the counterstain of the nuclei, to measure the monolayer. On the other hand, the fluorescent-tracker-labeled cells, to count the adhered cells. Due to the nature of the assay and the expected output, high resolution images are not required (rather the opposite). As a rule of thumb, it woulb be advisable to acquire a dataset with an object size (smallest length) of 5-10 pixels. Note that that the objects will be detected on the fluorescent tracker channel (adhered cells).

In order to assess the output of the assay it is advisable to use a different software suited to explore high content microscopy data, such as [shinyHTM](https://github.com/embl-cba/shinyHTM/blob/master/README.md#shinyhtm).

Know more about [Object Size & Pixel Size](https://c4science.ch/w/bioimaging_and_optics_platform_biop/teaching/object_size/).

## Requirements

* [Fiji](https://fiji.sc/)
* Image dataset following an IN Cell Analyzer file naming convention (note that the NeuroMol update site includes a [macroinstruction](https://github.com/paucabar/other_macros) to turn data acquired with diferent high content microscopes into an IN Cell Analyzer file naming convention dataset)

## Installation

1. Start [FIJI](https://fiji.sc/)
2. Start the **ImageJ Updater** (<code>Help > Update...</code>)
3. Click on <code>Manage update sites</code>
4. Click on <code>Add update site</code>
5. A new blank row is to be created at the bottom of the update sites list
6. Type **NeuroMol Lab** in the **Name** column
7. Type **http://sites.imagej.net/Paucabar/** in the **URL** column
8. <code>Close</code> the update sites window
9. <code>Apply changes</code>
10. Restart FIJI
11. Check if <code>NeuroMol Lab</code> appears now in the <code>Plugins</code> dropdown menu (note that it will be placed at the bottom of the dropdown menu)

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
9. Check the output (_see Figure 1_)
10. **Pre-analysis mode** will ask to test a new image, and will continue until the user asks to stop

![image](https://user-images.githubusercontent.com/39589980/79636550-c8043900-8178-11ea-9485-97235f933ec0.png)

**Figure 1.** _Pre-analysis mode_ output. The macro generates a stack composed of two images. On one hand, the merge of the counterstain (blue) and the cell tracker (red) (**left**). On the other hand, the merge of the counterstain (gray), the additionally segmented monolayer (green) and the remaining background (blue) (**right**). Finally, when detected, ROI Manager will store the ROI set of tracker-labeled cells, shown as a yellow, numbered outline (**left**)

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

Cell Adhesion in licensed under [MIT](https://imagej.net/MIT)
