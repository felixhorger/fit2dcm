
import Pkg

Pkg.activate(".")
Pkg.add("Statistics")
Pkg.add("YAML")
Pkg.add("JLD2")
Pkg.add(url="https://github.com/felixhorger/DICOM.jl")
Pkg.add(url="https://github.com/felixhorger/DICOMTools.jl")
Pkg.add(url="https://github.com/felixhorger/MRIRelax.jl")

