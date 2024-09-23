# Biofilm-Viability-Checker

//This macro processes multiple images in a folder, outputting the number of bacteria pixels in the red channel and the green channel respectively to calculate the 
//viability of a biofilm stained with red and green viability stains. 
//It also saves overlay images showing the bacteria which have been detected.
//See "Supplementary Information" file for details on how to run and implement the macro.

## Original Authors
//Sophie Mountcastle (sem093@bham.ac.uk) and Nina Vyas (n.vyas@bham.ac.uk)
//University of Birmingham, UK
//For queries related to the original code, please contact Dr. Sarah Kuehne (s.a.kuehne@bham.ac.uk).

## Modifications by Tinatini Tchatchiashvili
//In this fork, I have made the following modifications:
//Updated channel analysis and protocol to work with **Calcein AM (green) and TMA-DPH (blue)** stains for metabolic activity and membrane integrity.
//The original (SYTO9/PI) and modified (CAM/TMA-DPH) versions of the code now output the **number of stained pixels** instead of percentage values. 

//For questions about these modifications, feel free to contact me (Tinatini.tchatchiashvili@med.uni-jena.de)
//Jena University Hospital, Am Klinikum 1, 07747 Jena, Germany
