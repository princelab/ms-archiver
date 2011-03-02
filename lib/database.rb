#!/usr/bin/ruby

require 'msruninfo'

require 'rubygems'
require 'dm-core'
require 'dm-sqlite-adapter'
require 'dm-types'
require 'yaml'
require 'digest/md5'

DataMapper.setup(:default, "sqlite://#{Db_mount.full_path('metrics/test.db')}")
puts "Db_mount.full_path.... (path to database): #{Db_mount.full_path('metrics/test.db')}"
class Msrun
	include DataMapper::Resource
	#property :id, Serial

	# Unique Identifier
	property :raw_id, 			String, :key => true
	property :raw_md5_sum, 	String, :length => 32, :default => lambda { |r, p| 
		if r.rawfile and File.exist?(r.rawfile) 
			filename = r.rawfile
			incr_digest = Digest::MD5.new()
			file = File.open(filename, 'rb') do |io|
				while chunk = io.read(50000)
					incr_digest << chunk
				end
			end
			incr_digest.hexdigest 
		end
	}
	#	Digest::MD5.hexdigest(File.read(r.rawfile)) if r.rawfile and File.exist?(r.rawfile)}

	# Owner
	property :group,			 	String
	property :user, 				String
	
	# Search information
	property :taxonomy, 		String, :length => 5, :default => 'human'
	property :sample_type, 	String, :default => 'unknown'

	# Time
	property :rawtime, 			DateTime, :default => lambda { |r, p| File.mtime(r.rawfile) if r.rawfile and File.exist?(r.rawfile) }

	# Files
	property :rawfile, 					FilePath
	property :methodfile, 			FilePath
	property :tunefile, 				FilePath
	property :hplcfile, 				FilePath
	property :graphfile, 				FilePath
	property :metricsfile, 			FilePath	

	# Relational information
	property :archive_location,		String
	property :sample_set,					String

	# Values
	property :autosampler_vial,		String
	property :inj_volume, 				Integer
	
# Associations
	has 1, :metric										# ONE OR MANY????????????????
end

class Metric 
	include DataMapper::Resource
	#property :id, Serial
	
	#property :metric_input_file, 	FilePath#, :key => true
	
# Associations
	has 1, :chromatography
	has 1, :ms1
	has 1, :dynamic_sampling
	has 1, :ion_source
	has 1, :ion_treatment
	has 1, :peptide_ids
	has 1, :ms2
	has 1, :run_comparison
	belongs_to :msrun, :key => true
end

class Chromatography
	include DataMapper::Resource
	property :id, Serial

	has 1, :first_and_last_ms1_rt_min
	has 1, :middle_peptide_retention_time_period_min
	has 1, :max_peak_width_for_ids_sec
	has 1, :peak_width_at_half_height_for_ids
	has 1, :peak_widths_at_half_max_over_rt_deciles_for_ids
	has 1, :wide_rt_differences_for_ids_4_min
	##### has 1, :fraction_of_repeat_peptide_ids_with_divergent_rt_rt_vs_rt_best_id_chromatographic_bleed
	has 1, :rt_ms1max_rt_ms2_for_ids_sec

	belongs_to :metric	

	def hashes
		hash = {}
		hash[:first_and_last_ms1_rt_min] = self.first_and_last_ms1_rt_min.attributes
		hash[:middle_peptide_retention_time_period_min] = self.middle_peptide_retention_time_period_min.attributes
		hash[:max_peak_width_for_ids_sec] = self.max_peak_width_for_ids_sec.attributes
		hash[:peak_width_at_half_height_for_ids] = self.peak_width_at_half_height_for_ids.attributes
hash[:peak_widths_at_half_max_over_rt_deciles_for_ids] = self.peak_widths_at_half_max_over_rt_deciles_for_ids.attributes
hash[:wide_rt_differences_for_ids_4_min] = self.wide_rt_differences_for_ids_4_min.attributes
hash[:rt_ms1max_rt_ms2_for_ids_sec] = self.rt_ms1max_rt_ms2_for_ids_sec.attributes
		hash
	end
	
	def to_yaml
		self.hashes.to_yaml
	end
end

class Ms1
	include DataMapper::Resource
	property :id, Serial

	has 1, :ms1_during_middle_and_early_peptide_retention_period
	has 1, :ms1_total_ion_current_for_different_rt_periods
	has 1, :ms1_id_max

	belongs_to :metric
	def hashes
		hash = {}
		hash[:ms1_during_middle_and_early_peptide_retention_period] = self.ms1_during_middle_and_early_peptide_retention_period.attributes
		hash[:ms1_total_ion_current_for_different_rt_periods] = self.ms1_total_ion_current_for_different_rt_periods.attributes
		hash[:ms1_id_max] = self.ms1_id_max.attributes
		hash
	end

	def to_yaml
		self.hashes.to_yaml
	end
end

class DynamicSampling
	include DataMapper::Resource
	property :id, Serial

	has 1, :nearby_resampling_of_ids_oversampling_details
	has 1, :early_and_late_rt_oversampling_spectrum_ids_unique_peptide_ids_chromatographic_flow_through_bleed
	has 1, :peptide_ion_ids_by_3_spectra_hi_vs_1_3_spectra_lo_extreme_oversampling
	has 1, :ratios_of_peptide_ions_ided_by_different_numbers_of_spectra_oversampling_measure
	has 1, :single_spectrum_peptide_ion_identifications_oversampling_measure
	has 1, :ms1max_ms1sampled_abundance_ratio_ids_inefficient_sampling

	belongs_to :metric
	def hashes
		hash = {}
		hash[:nearby_resampling_of_ids_oversampling_details] = self.nearby_resampling_of_ids_oversampling_details.attributes
		hash[:early_and_late_rt_oversampling_spectrum_ids_unique_peptide_ids_chromatographic_flow_through_bleed] = self.early_and_late_rt_oversampling_spectrum_ids_unique_peptide_ids_chromatographic_flow_through_bleed.attributes
		hash[:peptide_ion_ids_by_3_spectra_hi_vs_1_3_spectra_lo_extreme_oversampling] = self.peptide_ion_ids_by_3_spectra_hi_vs_1_3_spectra_lo_extreme_oversampling.attributes
		hash[:ratios_of_peptide_ions_ided_by_different_numbers_of_spectra_oversampling_measure] = self.ratios_of_peptide_ions_ided_by_different_numbers_of_spectra_oversampling_measure.attributes
		hash[:single_spectrum_peptide_ion_identifications_oversampling_measure] = self.single_spectrum_peptide_ion_identifications_oversampling_measure.attributes
		hash[:ms1max_ms1sampled_abundance_ratio_ids_inefficient_sampling] = self.ms1max_ms1sampled_abundance_ratio_ids_inefficient_sampling.attributes
		hash
	end



	def to_yaml
		self.hashes.to_yaml
	end
end

class IonSource
	include DataMapper::Resource
	property :id, Serial

	has 1, :spectrum_counts
	has 1, :ion_injection_times_for_ids_ms
	has 1, :top_ion_abundance_measures
	has 1, :number_of_ions_vs_charge
	has 1, :ion_ids_by_charge_state_relative_to_2
	has 1, :average_peptide_lengths_for_different_charge_states
	has 1, :average_peptide_lengths_for_charge_2_for_different_numbers_of_mobile_protons
	has 1, :numbers_of_ion_ids_at_different_charges_with_1_mobile_proton
	has 1, :percent_of_ids_at_different_charges_and_mobile_protons_relative_to_ids_with_1_mobile_proton

	belongs_to :metric
	def hashes
		hash = {}
		hash[:spectrum_counts] = self.spectrum_counts.attributes
		hash[:ion_injection_times_for_ids_ms] = self.ion_injection_times_for_ids_ms.attributes
		hash[:top_ion_abundance_measures] = self.top_ion_abundance_measures.attributes
		hash[:number_of_ions_vs_charge] = self.number_of_ions_vs_charge.attributes
		hash[:ion_ids_by_charge_state_relative_to_2] = self.ion_ids_by_charge_state_relative_to_2.attributes
		hash[:average_peptide_lengths_for_different_charge_states] = self.average_peptide_lengths_for_different_charge_states.attributes
		hash[:average_peptide_lengths_for_charge_2_for_different_numbers_of_mobile_protons] = self.average_peptide_lengths_for_charge_2_for_different_numbers_of_mobile_protons.attributes
		hash[:numbers_of_ion_ids_at_different_charges_with_1_mobile_proton] = self.numbers_of_ion_ids_at_different_charges_with_1_mobile_proton.attributes
		hash[:percent_of_ids_at_different_charges_and_mobile_protons_relative_to_ids_with_1_mobile_proton] = self.percent_of_ids_at_different_charges_and_mobile_protons_relative_to_ids_with_1_mobile_proton.attributes
		hash
	end



	def to_yaml
		self.hashes.to_yaml
	end
end

class IonTreatment
	include DataMapper::Resource
	property :id, Serial

	has 1, :precursor_m_z_monoisotope_exact_m_z

	belongs_to :metric
	def hashes
		hash = {}
		hash[:precursor_m_z_monoisotope_exact_m_z] = self.precursor_m_z_monoisotope_exact_m_z.attributes
		hash
	end
	def to_yaml
		self.hashes.to_yaml
	end
end

class PeptideIds
	include DataMapper::Resource
	property :id, Serial

	has 1, :tryptic_peptide_counts
	has 1, :peptide_counts
	has 1, :total_ion_current_for_ids_at_peak_maxima
	has 1, :precursor_m_z_for_ids
	has 1, :averages_vs_rt_for_ided_peptides

	belongs_to :metric
	def hashes
		hash = {}
		hash[:tryptic_peptide_counts] = self.tryptic_peptide_counts.attributes
		hash[:peptide_counts] = self.peptide_counts.attributes
		hash[:total_ion_current_for_ids_at_peak_maxima] = self.total_ion_current_for_ids_at_peak_maxima.attributes
		hash[:precursor_m_z_for_ids] = self.precursor_m_z_for_ids.attributes
		hash[:averages_vs_rt_for_ided_peptides] = self.averages_vs_rt_for_ided_peptides.attributes
		hash
	end

	def to_yaml
		self.hashes.to_yaml
	end
end

class Ms2
	include DataMapper::Resource
	property :id, Serial

	has 1, :precursor_m_z_peptide_ion_m_z_2_charge_only_reject_0_45_m_z 
	has 1, :ms2_id_spectra
	has 1, :ms1_id_abund_at_ms2_acquisition
	has 1, :ms2_id_abund_reported

	belongs_to :metric
	def hashes
		hash = {}
		hash[:precursor_m_z_peptide_ion_m_z_2_charge_only_reject_0_45_m_z] = self.precursor_m_z_peptide_ion_m_z_2_charge_only_reject_0_45_m_z.attributes
		hash[:ms2_id_spectra] = self.ms2_id_spectra.attributes
		hash[:ms1_id_abund_at_ms2_acquisition] = self.ms1_id_abund_at_ms2_acquisition.attributes
		hash[:ms2_id_abund_reported] = self.ms2_id_abund_reported.attributes
		hash
	end

	def to_yaml
		self.hashes.to_yaml
	end
end

class RunComparison
	include DataMapper::Resource
	property :id, Serial

	has 1, :relative_fraction_of_peptides_in_retention_decile_matching_a_peptide_in_other_runs
	has 1, :relative_uniqueness_of_peptides_in_decile_found_anywhere_in_other_runs
	has 1, :differences_in_elution_rank_percent_of_matching_peptides_in_other_runs
	has 1, :median_ratios_of_ms1_intensities_of_matching_peptides_in_other_runs
	has 1, :uncorrected_and_rt_corrected_relative_intensities_of_matching_peptides_in_other_runs
	has 1, :magnitude_of_rt_correction_of_intensities_of_matching_peptides_in_other_runs

	belongs_to :metric
	def hashes
		hash = {}
		hash[:relative_fraction_of_peptides_in_retention_decile_matching_a_peptide_in_other_runs] = self.relative_fraction_of_peptides_in_retention_decile_matching_a_peptide_in_other_runs.attributes
		hash[:relative_uniqueness_of_peptides_in_decile_found_anywhere_in_other_runs] = self.relative_uniqueness_of_peptides_in_decile_found_anywhere_in_other_runs.attributes
		hash[:differences_in_elution_rank_percent_of_matching_peptides_in_other_runs] = self.differences_in_elution_rank_percent_of_matching_peptides_in_other_runs.attributes
		hash[:median_ratios_of_ms1_intensities_of_matching_peptides_in_other_runs] = self.median_ratios_of_ms1_intensities_of_matching_peptides_in_other_runs.attributes
		hash[:uncorrected_and_rt_corrected_relative_intensities_of_matching_peptides_in_other_runs] = self.uncorrected_and_rt_corrected_relative_intensities_of_matching_peptides_in_other_runs.attributes
		hash[:magnitude_of_rt_correction_of_intensities_of_matching_peptides_in_other_runs] = self.magnitude_of_rt_correction_of_intensities_of_matching_peptides_in_other_runs.attributes
		hash
	end

	def to_yaml
		self.hashes.to_yaml
	end
end

class SpectrumCounts
	include DataMapper::Resource
	property :id, Serial
	
	property :ms2_scans, 				Integer
	property :ms1_scans_full, 	Integer
	property :ms1_scans_other, 	Integer

	belongs_to :ion_source
end

class FirstAndLastMs1RtMin
	include DataMapper::Resource
	property :id, Serial

	property :first_ms1, 			Float
	property :last_ms1, 			Float

	belongs_to :chromatography
end

class TrypticPeptideCounts
	include DataMapper::Resource
	property :id, Serial

	property :peptides, 			Float
	property :ions, 			Float
	property :identifications, 			Float
	property :abundance_pct, 			Float
	property :abundance_1000, 			Float
	property :ions_peptide, 			Float
	property :ids_peptide, 			Float

	belongs_to :peptide_ids
end

class PeptideCounts
	include DataMapper::Resource
	property :id, Serial

	property :peptides, 			Float
	property :ions, 			Float
	property :identifications, 			Float
	property :semi_tryp_peps, 			Float
	property :semi_tryp_cnts, 			Float
	property :semi_tryp_abund, 			Float
	property :miss_tryp_peps, 			Float
	property :miss_tryp_cnts, 			Float
	property :miss_tryp_abund, 			Float
	property :net_oversample, 			Float
	property :ions_peptide, 			Float
	property :ids_peptide, 			Float

	belongs_to :peptide_ids
end

class MiddlePeptideRetentionTimePeriodMin
	include DataMapper::Resource
	property :id, Serial

	property :half_period, 			Float
	property :start_time, 			Float
	property :mid_time, 			Float
	property :qratio_time, 			Float
	property :ms2_scans, 			Float
	property :ms1_scans, 			Float
	property :pep_id_rate, 			Float
	property :id_rate, 			Float
	property :id_efficiency, 			Float

	belongs_to :chromatography
end

class Ms1DuringMiddleAndEarlyPeptideRetentionPeriod
	include DataMapper::Resource
	property :id, Serial

	property :s_n_median, 			Float
	property :tic_median_1000, 			Float
	property :npeaks_median, 			Float
	property :scan_to_scan, 			Float
	property :s2s_3q_med, 			Float
	property :s2s_1qrt_med, 			Float
	property :s2s_2qrt_med, 			Float
	property :s2s_3qrt_med, 			Float
	property :s2s_4qrt_med, 			Float
	property :esi_off_middle, 			Float
	property :esi_off_early, 			Float
	property :max_ms1_jump, 			Float
	property :max_ms1_fall, 			Float
	property :ms1_jumps_10x, 			Float
	property :ms1_falls_10x, 			Float

	belongs_to :ms1
end

class Ms1TotalIonCurrentForDifferentRtPeriods
	include DataMapper::Resource
	property :id, Serial

	property :_1st_quart_id, 			Float
	property :middle_id, 			Float
	property :last_id_quart, 			Float
	property :to_end_of_run, 			Float

	belongs_to :ms1
end

class TotalIonCurrentForIdsAtPeakMaxima
	include DataMapper::Resource
	property :id, Serial

	property :med_tic_id_1000, 			Float
	property :interq_tic, 			Float
	property :mid_interq_tic, 			Float

	belongs_to :peptide_ids
end

class PrecursorMZForIds
	include DataMapper::Resource
	property :id, Serial

	property :median, 			Float
	property :half_width, 			Float
	property :quart_ratio, 			Float
	property :precursor_min, 			Float
	property :precursor_max, 			Float
	property :med_q1_tic, 			Float
	property :med_q4_tic, 			Float
	property :med_q1_rt, 			Float
	property :med_q4_rt, 			Float
	property :med_charge_1, 			Float
	property :med_charge_2, 			Float
	property :med_charge_3, 			Float
	property :med_charge_4, 			Float

	belongs_to :peptide_ids
end

class NumberOfIonsVsCharge
	include DataMapper::Resource
	property :id, Serial

	property :charge_1, 			Float
	property :charge_2, 			Float
	property :charge_3, 			Float
	property :charge_4, 			Float
	property :charge_5, 			Float

	belongs_to :ion_source
end

class AveragesVsRtForIdedPeptides
	include DataMapper::Resource
	property :id, Serial

	property :length_q1, 			Float
	property :length_q4, 			Float
	property :charge_q1, 			Float
	property :charge_q4, 			Float

	belongs_to :peptide_ids
end

class PrecursorMZPeptideIonMZ2ChargeOnlyReject045MZ
	include DataMapper::Resource
	property :id, Serial

	property :spectra, 			Float
	property :median, 			Float
	property :mean_absolute, 			Float
	property :ppm_median, 			Float
	property :ppm_interq, 			Float

	belongs_to :ms2
end

class IonIdsByChargeStateRelativeTo2
	include DataMapper::Resource
	property :id, Serial

	property :_2_ion_count, 			Float
	property :charge_1, 			Float
	property :charge_2, 			Float
	property :charge_3, 			Float
	property :charge_4, 			Float

	belongs_to :ion_source
end

class AveragePeptideLengthsForDifferentChargeStates
	include DataMapper::Resource
	property :id, Serial

	property :charge_1, 			Float
	property :charge_2, 			Float
	property :charge_3, 			Float
	property :charge_4, 			Float

	belongs_to :ion_source
end

class AveragePeptideLengthsForCharge2ForDifferentNumbersOfMobileProtons
	include DataMapper::Resource
	property :id, Serial

	property :naa_ch_2_mp_1, 			Float
	property :naa_ch_2_mp_0, 			Float
	property :naa_ch_2_mp_1, 			Float
	property :naa_ch_2_mp_2, 			Float

	belongs_to :ion_source
end

class NumbersOfIonIdsAtDifferentChargesWith1MobileProton
	include DataMapper::Resource
	property :id, Serial

	property :ch_1_mp_1, 			Float
	property :ch_2_mp_1, 			Float
	property :ch_3_mp_1, 			Float
	property :ch_4_mp_1, 			Float

	belongs_to :ion_source
end

class PercentOfIdsAtDifferentChargesAndMobileProtonsRelativeToIdsWith1MobileProton
	include DataMapper::Resource
	property :id, Serial

	property :ch_1_mp_1, 			Float
	property :ch_1_mp_0, 			Float
	property :ch_1_mp_1, 			Float
	property :ch_2_mp_1, 			Float
	property :ch_2_mp_0, 			Float
	property :ch_2_mp_1, 			Float
	property :ch_3_mp_1, 			Float
	property :ch_3_mp_0, 			Float
	property :ch_3_mp_1, 			Float

	belongs_to :ion_source
end

class PrecursorMZMonoisotopeExactMZ
	include DataMapper::Resource
	property :id, Serial

	property :more_than_100, 			Float
	property :betw_100_0_50_0, 			Float
	property :betw_50_0_25_0, 			Float
	property :betw_25_0_12_5, 			Float
	property :betw_12_5_6_3, 			Float
	property :betw_6_3_3_1, 			Float
	property :betw_3_1_1_6, 			Float
	property :betw_1_6_0_8, 			Float
	property :top_half, 			Float
	property :next_half_2, 			Float
	property :next_half_3, 			Float
	property :next_half_4, 			Float
	property :next_half_5, 			Float
	property :next_half_6, 			Float
	property :next_half_7, 			Float
	property :next_half_8, 			Float

	belongs_to :ion_treatment
end

class Ms2IdSpectra
	include DataMapper::Resource
	property :id, Serial

	property :npeaks_median, 			Float
	property :npeaks_interq, 			Float
	property :s_n_median, 			Float
	property :s_n_interq, 			Float
	property :id_score_median, 			Float
	property :id_score_interq, 			Float
	property :idsc_med_q1msmx, 			Float

	belongs_to :ms2
end

class Ms1IdMax
	include DataMapper::Resource
	property :id, Serial

	property :median, 			Float
	property :half_width, 			Float
	property :quart_ratio, 			Float
	property :median_midrt, 			Float
	property :_75_25_midrt, 			Float
	property :_95_5_midrt, 			Float
	property :_75_25_pctile, 			Float
	property :_95_5_pctile, 			Float

	belongs_to :ms1
end

class Ms1IdAbundAtMs2Acquisition
	include DataMapper::Resource
	property :id, Serial

	property :median, 			Float
	property :half_width, 			Float
	property :_75_25_pctile, 			Float
	property :_95_5_pctile, 			Float

	belongs_to :ms2
end

class Ms2IdAbundReported
	include DataMapper::Resource
	property :id, Serial

	property :median, 			Float
	property :half_width, 			Float
	property :_75_25_pctile, 			Float
	property :_95_5_pctile, 			Float

	belongs_to :ms2	
end

class MaxPeakWidthForIdsSec
	include DataMapper::Resource
	property :id, Serial

	property :median_value, 			Float
	property :third_quart, 			Float
	property :last_decile, 			Float

	belongs_to :chromatography
end

class PeakWidthAtHalfHeightForIds
	include DataMapper::Resource
	property :id, Serial

	property :median_value, 			Float
	property :med_top_quart, 			Float
	property :med_top_16th, 			Float
	property :med_top_100, 			Float
	property :median_disper, 			Float
	property :med_quart_disp, 			Float
	property :med_16th_disp, 			Float
	property :med_100_disp, 			Float
	property :_3quart_value, 			Float
	property :_9dec_value, 			Float
	property :ms1_interscan_s, 			Float
	property :ms1_scan_fwhm, 			Float
	property :ids_used, 			Float

	belongs_to :chromatography
end

class PeakWidthsAtHalfMaxOverRtDecilesForIds
	include DataMapper::Resource
	property :id, Serial

	property :first_decile, 			Float
	property :median_value, 			Float
	property :last_decile, 			Float

	belongs_to :chromatography
end

class NearbyResamplingOfIdsOversamplingDetails
	include DataMapper::Resource
	property :id, Serial

	property :repeated_ids, 			Float
	property :med_rt_diff_s, 			Float
	property :_1q_rt_diff_s, 			Float
	property :_1dec_rt_diff_s, 			Float
	property :median_dm_z, 			Float
	property :quart_dm_z, 			Float

	belongs_to :dynamic_sampling
end

class WideRtDifferencesForIds4Min
	include DataMapper::Resource
	property :id, Serial

	property :peptides, 			Float
	property :spectra, 			Float

	belongs_to :chromatography
end

=begin
class FractionOfRepeatPeptideIdsWithDivergentRtRtVsRtBestIdChromatographicBleed
	include DataMapper::Resource
	property :id, Serial

	property :, 			Float
	property :, 			Float

	belongs_to :chromatography
end
=end

class EarlyAndLateRtOversamplingSpectrumIdsUniquePeptideIdsChromatographicFlowThroughBleed
	include DataMapper::Resource
	property :id, Serial

	property :first_decile, 			Float
	property :last_decile, 			Float

	belongs_to :dynamic_sampling
end

class PeptideIonIdsBy3SpectraHiVs13SpectraLoExtremeOversampling
	include DataMapper::Resource
	property :id, Serial

	property :pep_ions_hi, 			Float
	property :ratio_hi_lo, 			Float
	property :spec_cnts_hi, 			Float
	property :ratio_hi_lo, 			Float
	property :spec_pep_hi, 			Float
	property :spec_cnt_excess, 			Float

	belongs_to :dynamic_sampling
end

class RatiosOfPeptideIonsIdedByDifferentNumbersOfSpectraOversamplingMeasure
	include DataMapper::Resource
	property :id, Serial

	property :once_twice, 			Float
	property :twice_thrice, 			Float

	belongs_to :dynamic_sampling
end

class SingleSpectrumPeptideIonIdentificationsOversamplingMeasure
	include DataMapper::Resource
	property :id, Serial

	property :peptide_ions, 			Float
	property :fract_1_ions, 			Float
	property :_1_vs_1_pepion, 			Float
	property :_1_vs_1_spec, 			Float

	belongs_to :dynamic_sampling
end

class Ms1maxMs1sampledAbundanceRatioIdsInefficientSampling
	include DataMapper::Resource
	property :id, Serial

	property :median_all_ids, 			Float
	property :_3q_all_ids, 			Float
	property :_9dec_all_ids, 			Float
	property :med_top_100, 			Float
	property :med_top_dec, 			Float
	property :med_top_quart, 			Float
	property :med_bottom_1_2, 			Float

	belongs_to :dynamic_sampling
end

class RtMs1maxRtMs2ForIdsSec
	include DataMapper::Resource
	property :id, Serial

	property :med_diff_abs, 			Float
	property :median_diff, 			Float
	property :first_quart, 			Float
	property :third_quart, 			Float

	belongs_to :chromatography
end

class IonInjectionTimesForIdsMs
	include DataMapper::Resource
	property :id, Serial

	property :ms1_median, 			Float
	property :ms1_maximum, 			Float
	property :ms2_median, 			Float
	property :ms2_maximun, 			Float
	property :ms2_fract_max, 			Float

	belongs_to :ion_source
end

class RelativeFractionOfPeptidesInRetentionDecileMatchingAPeptideInOtherRuns
	include DataMapper::Resource
	property :id, Serial

	property :all_deciles, 			Float
	property :first_decile, 			Float
	property :last_decile, 			Float
	property :comp_to_first, 			Float
	property :comp_to_last, 			Float

	belongs_to :run_comparison
end

class RelativeUniquenessOfPeptidesInDecileFoundAnywhereInOtherRuns
	include DataMapper::Resource
	property :id, Serial

	property :first_decile, 			Float
	property :last_decile, 			Float

	belongs_to :run_comparison
end

class DifferencesInElutionRankPercentOfMatchingPeptidesInOtherRuns
	include DataMapper::Resource
	property :id, Serial

	property :average_diff, 			Float
	property :median_diff, 			Float
	property :comp_to_first, 			Float
	property :comp_to_last, 			Float

	belongs_to :run_comparison
end

class MedianRatiosOfMs1IntensitiesOfMatchingPeptidesInOtherRuns
	include DataMapper::Resource
	property :id, Serial

	property :median_diff, 			Float
	property :median_2_diff, 			Float
	property :comp_to_first, 			Float
	property :comp_to_last, 			Float
	property :comp_to_first_2, 			Float
	property :comp_to_last_2, 			Float

	belongs_to :run_comparison
end

class UncorrectedAndRtCorrectedRelativeIntensitiesOfMatchingPeptidesInOtherRuns
	include DataMapper::Resource
	property :id, Serial

	property :uncor_rel_first, 			Float
	property :uncor_rel_last, 			Float
	property :corr_rel_first, 			Float
	property :corr_rel_last, 			Float

	belongs_to :run_comparison
end

class MagnitudeOfRtCorrectionOfIntensitiesOfMatchingPeptidesInOtherRuns
	include DataMapper::Resource
	property :id, Serial

	property :comp_to_first, 			Float
	property :comp_to_last, 			Float

	belongs_to :run_comparison
end

class TopIonAbundanceMeasures
	include DataMapper::Resource
	property :id, Serial

	property :top_10_abund, 			Float
	property :top_25_abund, 			Float
	property :top_50_abund, 			Float
	property :fractab_top, 			Float
	property :fractab_top_10, 			Float
	property :fractab_top_100, 			Float

	belongs_to :ion_source
end


DataMapper.finalize
