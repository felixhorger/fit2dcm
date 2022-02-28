
import Statistics
import YAML
import JLD2
import DICOM
import DICOMTools
import MRIRelax


function main()
	directory = ""
	local full_dcmdict
	for specfile in ARGS
		# Get specs and DICOMs
		specs = YAML.load_file(specfile)

		# Load DICOMs
		multiseries = let
			if length(directory) == 0 || directory != tmp
				directory = expanduser(specs["directory"])
				full_dcmdict = DICOMTools.load_dcms(directory, DICOMTools.read_uid)
			end

			# Filter DICOMs by uid and fully load matches
			dcmdict = DICOMTools.filter(
				dcms -> dcms[1][DICOM.tag"SeriesInstanceUID"] in specs["uids"],
				full_dcmdict
			)
			DICOMTools.load_dcms!(dcmdict)

			# Extract DICOMs from dictionary
			[series.dcms for series in values(dcmdict)]
		end

		# Get tag and fitfunc
		if specs["type"] == "Inversion Recovery"
			tagname = DICOM.tag"InversionTime"
			tags = DICOMTools.get_tag(multiseries, tagname; outtype=Float64)
			# Note: Get tags here because some applications might use other (non-numeric, multiple) tags
			fitfunc = (Tinv, signal, Δsignal) -> begin
				let	T1_0::Float64 = specs["T1_0"],
					Minv_0::Float64 = specs["Minv_0"],
					M0_0::Float64 = specs["M0_0"]
					MRIRelax.fit_inversion_recovery(Tinv, signal, Δsignal, T1_0, Minv_0, M0_0)
				end
			end
			num_params = 6
			names = ["T1", "ΔT1", "Minv", "ΔMinv", "M0", "ΔM0"]
		elseif specs["type"] == "Transverse Relaxation"
			tagname = DICOM.tag"EchoTime"
			tags = DICOMTools.get_tag(multiseries, tagname; outtype=Float64)
			fitfunc = MRIRelax.fit_transverse_relax
			num_params = 4
			names = ["T2", "ΔM0", "ΔM0"]
		end

		# Get signals and tags from DICOMs
		signal = DICOMTools.merge_multiseries(multiseries; data_type=Float64)

		# Get background
		background = ntuple(
			i -> specs["background_lower"][i]:specs["background_upper"][i],
			3
		)

		# Perform the fitting
		maps, Δsignal = fit2dcm(fitfunc, num_params, signal, tags, background)

		# Write the results
		JLD2.jldsave(
			splitext(specfile)[1] * ".jld2";
			maps,
			names,
			coordinates=tags,
			coordinatename=tagname,
			signal,
			Δsignal
		)
	end
end


function fit2dcm(
	fitfunc::Function,
	num_params::Integer,
	signal::AbstractArray{<: Real, 4},
	tags::AbstractVector,
	background::NTuple{3, UnitRange{Int64}}
)
	
	# Get noise estimation for each signal(coordinate or tag)
	Δsignal = Statistics.std(view(signal, :, background...); dims=2:4)
	Δsignal = dropdims(Δsignal; dims=(2, 3, 4))

	# Construct array for fitting results
	maps = [
		Array{Float64, 3}(undef, size(signal)[2:4]...)
		for _ in 1:num_params
	]

	# Iterate over voxels
	Threads.@threads for I in CartesianIndices(size(signal)[2:4])
		tid = Threads.threadid()
		returned = fitfunc(tags, signal[:, I], Δsignal)
		for (tag_idx, value) in enumerate(returned)
			maps[tag_idx][I] = value
		end
	end

	return maps, Δsignal
end


main()

