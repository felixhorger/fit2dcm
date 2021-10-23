
import Statistics
import YAML
import MATLAB
import DICOM
import DICOMTools
import MRIQuant


function main()
	directory = ""
	local dcmdict 
	for specfile in ARGS
		# Get specs and DICOMs
		specs = YAML.load_file(specfile)
		if specs["directory"] != directory # Do not reload unnecessarily
			directory = specs["directory"]
			dcmdict = DICOMTools.load_dcms(directory)
		end

		# Get tag and fitfunc
		if specs["type"] == "Inversion Recovery"
			tagname = DICOM.tag"InversionTime"
			T1_0::Float64 = specs["T1_0"] # Type annotations for capturing
			Minv_0::Float64 = specs["Minv_0"]
			M0_0::Float64 = specs["M0_0"]
			fitfunc = (Tinv, signal, Δsignal) -> begin
				MRIQuant.fit_inversion_recovery(Tinv, signal, Δsignal, T1_0, Minv_0, M0_0)
			end
			returntypes = (Float64, Float64, Float64, Float64, Float64, Float64)
		elseif specs["type"] == "Spin Echo"
			tagname = DICOM.tag"EchoTime"
			fitfunc = MRIQuant.fit_transverse_relax
			returntypes = (Float64, Float64, Float64, Float64)
		end

		# Get background
		background = [
			l:u
			for (l, u) in zip(specs["background_lower"], specs["background_upper"])
		]

		# Get arrays and tags from DICOMs
		arrays, tags = DICOMTools.merge_multiseries(
			dcmdict,
			specs["uids"],
			tagname;
			data_type=Float64,
			tag_type=Float64
		)
		
		# Perform the fitting
		maps, Δsignal = fit2dcm(fitfunc, returntypes, arrays, tags, background)

		# Write the results
		MATLAB.write_matfile(splitext(specfile)[1] * ".mat", maps=maps, parameters=tags, deltasignal=Δsignal)
	end
end


function fit2dcm(
	fitfunc::Function,
	returntypes::NTuple{N, Type} where N,
	arrays::AbstractArray{<: Real, 4},
	tags::AbstractVector,
	background::AbstractVector{<: UnitRange{Int64}}
)
	
	# Get noise estimation for each signal(parameter or tag)
	Δsignal = Statistics.std(view(arrays, :, background...); dims=2:4)
	Δsignal = dropdims(Δsignal; dims=(2, 3, 4))

	# Construct array for fitting results
	maps = [
		Array{T, 3}(undef, size(arrays)[2:4]...)
		for T in returntypes
	]

	# Iterate over voxels
	Threads.@threads for I in CartesianIndices(size(arrays)[2:4])
		tid = Threads.threadid()
		returned = fitfunc(tags, arrays[:, I], Δsignal)
		for (tag_idx, value) in enumerate(returned)
			maps[tag_idx][I] = value
		end
	end

	return maps, Δsignal
end


main()

