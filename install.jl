
import Pkg

Pkg.activate(".")
Pkg.add("YAML")
Pkg.add("MAT")
Pkg.add(url="https://github.com/felixhorger/DICOM.jl")
Pkg.add(url="https://github.com/felixhorger/DICOMTools.jl")
Pkg.add(url="https://github.com/felixhorger/MRIRelax.jl")

