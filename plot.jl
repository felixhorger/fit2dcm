
using JLD2
using Statistics
using MAT
import MRIRelax
import PyPlot as plt

get type from yml, cmdline only takes name without extension
ask to define roi
get new code from 20220211_scanning

plt.ioff()
rcParams = plt.PyDict(plt.matplotlib."rcParams")
rcParams["image.interpolation"] = "none"
rcParams["errorbar.capsize"] = 3
rcParams["lines.linewidth"] = 2
rcParams["lines.markeredgewidth"] = 2
rcParams["text.usetex"] = true
rcParams["backend"] = "ps"

# Get T1 map
run(`fit2dcm inversion_recovery.yml`)

let data = load("inversion_recovery.jld2")
	@assert data["names"] == ["T1", "ΔT1", "Minv", "ΔMinv", "M0", "ΔM0"]
	global T1 = data["maps"][1]
	global ΔT1 = data["maps"][2]
	global Minv = data["maps"][3]
	global ΔMinv = data["maps"][4]
	global M0 = data["maps"][5]
	global ΔM0 = data["maps"][6]
	global TI = data["coordinates"]
	global signal = data["signal"]
	global Δsignal = data["Δsignal"]
end

# Get final estimate
roi = (36:41, 71:78, 1)
let
	T1_roi = T1[roi...]
	global T1_roi_mean = mean(T1_roi)
	global ΔT1_roi_stat = std(T1_roi; mean=T1_roi_mean)
	global ΔT1_roi = mean(ΔT1[roi...])
	Minv_roi = Minv[roi...]
	global Minv_roi_mean = mean(Minv_roi)
	global ΔMinv_roi_stat = std(Minv_roi; mean=Minv_roi_mean)
	global ΔMinv_roi = mean(ΔMinv[roi...])
	M0_roi = M0[roi...]
	global M0_roi_mean = mean(M0_roi)
	global ΔM0_roi_stat = std(M0_roi; mean=M0_roi_mean)
	global ΔM0_roi = mean(ΔM0[roi...])
	open("inversion_recovery.txt", "w") do f
		write(f,
			"T1 = $(T1_roi_mean) ± $(ΔT1_roi) (stat: $(ΔT1_roi_stat))\n" *
			"Minv = $(Minv_roi_mean) ± $(ΔMinv_roi) (stat: $(ΔMinv_roi_stat))\n" *
			"M0 = $(M0_roi_mean) ± $(ΔM0_roi) (stat: $(ΔM0_roi_stat))\n"
		)
	end
end



# Plot maps
cut = (25:50, 55:90)
let
	#TODO vranges
	fig, axs = plt.subplots(2, 3, figsize=(12, 6))
	#
	axs[1, 1].set_title("T1")
	image = axs[1, 1].imshow(T1[cut...])
	cax = add_colourbar(fig, axs[1, 1], image, "horizontal")
	cax.set_xlabel("[ms]")
	axs[1, 1].tick_params(which="both", bottom=false, left=false, labelleft=false, labelbottom=false)
	#
	axs[2, 1].set_title("DeltaT1")
	image = axs[2, 1].imshow(ΔT1[cut...], vmin=10, vmax=30)
	cax = add_colourbar(fig, axs[2, 1], image, "horizontal")
	cax.set_xlabel("[ms]")
	axs[2, 1].tick_params(which="both", bottom=false, left=false, labelleft=false, labelbottom=false)
	#
	axs[1, 2].set_title("Minv")
	image = axs[1, 2].imshow(Minv[cut...], vmin=-1.5, vmax=-0.5)
	add_colourbar(fig, axs[1, 2], image, "horizontal")
	axs[1, 2].tick_params(which="both", bottom=false, left=false, labelleft=false, labelbottom=false)
	#
	axs[2, 2].set_title("DeltaMinv")
	image = axs[2, 2].imshow(ΔMinv[cut...], vmin=0.01, vmax=0.02)
	add_colourbar(fig, axs[2, 2], image, "horizontal")
	axs[2, 2].tick_params(which="both", bottom=false, left=false, labelleft=false, labelbottom=false)
	#
	axs[1, 3].set_title("M0")
	image = axs[1, 3].imshow(M0[cut...])
	add_colourbar(fig, axs[1, 3], image, "horizontal")
	axs[1, 3].tick_params(which="both", bottom=false, left=false, labelleft=false, labelbottom=false)
	#
	axs[2, 3].set_title("DeltaM0")
	axs[2, 3].tick_params(which="both", bottom=false, left=false, labelleft=false, labelbottom=false)
	image = axs[2, 3].imshow(ΔM0[cut...], vmin=5, vmax=20)
	add_colourbar(fig, axs[2, 3], image, "horizontal")
	for i in eachindex(axs)
		axs[i].add_patch(
			plt.matplotlib[:patches][:Rectangle](
				(roi[2].start - cut[2].start - 1, roi[1].start - cut[1].start - 1),
				roi[2].stop - roi[2].start+1,
				roi[1].stop - roi[1].start+1,
				linewidth=1,
				edgecolor="r",
				facecolor="none",
				transform=axs[i].transData
			)
		)
	end
	plt.subplots_adjust(hspace=0.5)
	plt.savefig("IR.eps", bbox_inches="tight")
	plt.close(fig)
	#plt.show()
end
