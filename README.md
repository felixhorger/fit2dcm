fit2dcm
========

Fit T1 and T2 relaxation curves to DICOM series

Installation
------------

1. Clone this repository to any directory DIR
2. On Unix-like systems, create a script and replace DIR with the respective *absolute* path:
  `echo 'julia --project=DIR DIR/fit2dcm.jl $@' > ~/.local/bin/fit2dcm`

Using the script
----------------
- Unix: `fit2dcm ARGS`
- Windows: `julia --project=DIR fit2dcm.jl ARGS` (or any other way you prefer)
- Arguments ARGS are a list of YAML files containing the information:
	- Information every YAML file must contain:
	```
			type: <experiment type, explained below>
			directory: <absolute path to containing folder, DICOMs are loaded recursively>
			uids:
			- <DICOM series instance uid as string>
			- ...
			background_lower:
			- <row, lower index of the box from which noise should be estimated, one based>
			- <column>
			- <slice>
			background_upper:
			- <row, upper index of the box from which noise should be estimated, one based>
			- <column>
			- <slice>
	```
	- Types
		- `Inversion Recovery`
		- `Spin Echo`

