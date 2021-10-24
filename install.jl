
import Pkg

Pkg.activate(".")
Pkg.add("YAML")
Pkg.add("MATLAB")
Pkg.add("DICOM")
Pkg.add(url="https://github.com/felixhorger/DICOMTools.jl")
Pkg.add(url="https://github.com/felixhorger/MRIQuant.jl")

