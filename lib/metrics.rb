#!/usr/bin/ruby

require 'msruninfo'
require 'rubygems'
require 'yaml'

class ::Measurement < 
# Structure, the entire basis for this class
	Struct.new(:name, :raw_id, :time, :value, :category, :subcat)
end

class Metric		# Metric parsing fxns
	attr_accessor :out_hash, :metricsfile, :rawfile, :measures, :raw_ids
	def camelcase(str)
		str.split('_').map{|word| word.capitalize}.join('')
	end
	def snakecase(str)
		str.gsub(/(\s|\W)/, '_').gsub(/(_+)/, '_').gsub(/(_$)/, "").gsub(/^(\d)/, '_\1').downcase
	end
	def initialize(file = nil)
		@metricsfile = file
	end
	def run_metrics(rawfile = nil)
		if @rawfile
			@rawfile = rawfile
			@rawtime = File.mtime(@rawfile)
# working on some major changes to the mount thing... that lets me have it do the work for me!!
			#%Q{C:\\NISTMSQCv1_0_3\\scripts\\run_NISTMSQC_pipeline.pl --in_dir "#{ArchiveMount.archive_location}" --out_dir "#{ArchiveMount.metrics}" --library #{ArchiveMount.config.metric_taxonomy}  --instrument_type #{ArchiveMount.config.metric_instrument_type || 'ORBI'} }
		end
	end
	def archive
		parse
		to_database
	end
	def parse				# Returns the out_hash
		array = IO.readlines(@metricsfile, 'r:us-ascii').first.split("\r\n")
		outs_hash = {}; key = ""
		measures = []
		array.each_index do |index|
			@reading = true if array[index][/^(Begin).*eries.*/,1] == "Begin"
			if @reading
				if array[index] == ""
				elsif array[index-1] == "" 
					#puts "key: #{key} and array[index] = #{array[index]}"
					key = snakecase(array[index])
					#puts "key: #{key}"
					@num_files = key[/files_analyzed_(\d)/,1].to_i if key[/(files_analyzed_).*/,1] == "files_analyzed_"
				elsif outs_hash[key]
					#puts "elsif put key: #{key} and array[index] = #{array[index]}"
					outs_hash[key] << array[index].split("\t")
				else
					#puts "else put key: #{key} and array[index] = #{array[index]}"
					outs_hash[key] = []
					outs_hash[key] << array[index].split("\t")
				end
			end
		end
		@metrics_input_files = outs_hash["files_analyzed_#{@num_files}"].map{|arr| arr.last}.compact
		@raw_ids = @metrics_input_files.map{|file| File.basename(file,".RAW.MGF.TSV") }
		@out_hash = {}
		outs_hash.each_pair do |key, values|
			@out_hash[key] = {}
			values.each do |value|
				if value[0]
					property = snakecase(value.shift)
					next if value.nil?
					@out_hash[key][property] = value
				#	puts "out_hash[key][property] == #{@out_hash[key][property]}"
	#				puts "key: #{key} and property: #{property}"
				end
			end
		end
		["files_analyzed_#{@num_files}", 'begin_runseries_results', 'begin_series_1', "run_number_#{(1..@num_files).to_a.join('_')}", 'end_series_1', 'fraction_of_repeat_peptide_ids_with_divergent_rt_rt_vs_rt_best_id_chromatographic_bleed'].each {|item| @out_hash.delete(item)}
		@out_hash
	end
	def slice_hash
		parse if @out_hash.nil?
		@measures = []; @data = {}; item = 0
		@metrics_input_files.each do |file|
			#	@@categories.each {|category| 				NOT NECESSARY because I don't have to make the category class
			@out_hash.each_pair do |subcategory, value_hash|
				value_hash.each_pair do |property, value|
					@measures << Measurement.new( property, file, @rawtime, value[item], @@ref_hash[subcategory.to_sym].to_sym, subcategory.to_sym)
				end
			end
			item +=1
		end
		@measures
	end
	def to_database
		require 'dm-migrations'
#				DataMapper.auto_migrate!  # This one wipes things!
		DataMapper.auto_upgrade!
		objects = []; item = 1
		@metrics_input_files.each do |file|
			tmp = Msrun.first_or_create({raw_id: "#{File.basename(file,".RAW.MGF.TSV")}",  metricsfile: @metricsfile}) # rawfile: "#{File.absolute_path(File.basename(file, ".RAW.MGF.TSV")) + ".RAW"}",
			tmp.metric = Metric.create()#{metric_input_file: @metricsfile })#"#{File.absolute_path(@metricsfile)}"})
			@@categories.each {|category|  tmp.metric.send("#{category}=".to_sym, Kernel.const_get(camelcase(category)).create()) }
			@out_hash.each_pair do |key, value_hash|
				outs = tmp.metric.send((@@ref_hash[key.to_sym]).to_sym).send("#{key.downcase}=".to_sym, Kernel.const_get(camelcase(key)).create(value_hash)) 
					value_hash.each_pair do |property, array|
						tmp.metric.send((@@ref_hash[key.to_sym]).to_sym).send("#{key.downcase}".to_sym).send("#{property}=".to_sym, array[item-1])
					end
				tmp.metric.send((@@ref_hash[key.to_sym]).to_sym).send("#{key.downcase}".to_sym).save
			end
			item +=1
			objects << tmp
		end
		objects.each{|obj| obj.save}
	end 	# to_database
end 		# Metric parsing fxns




# Metric grapher
class Metric
	def match_to_hash(matches)  
		# matches is the result of a Msrun.all OR Msrun.first OR Msrun.get(*args)
		@data = {}
		matches.each do |msrun|
			next if msrun.metric.nil?
				index = msrun.raw_id.to_s
				@data[index] = {'timestamp' => msrun.rawtime || Time.now}
			@@categories.each do |cat|
				@data[index][cat] = msrun.metric.send(cat.to_sym).hashes
				@data[index][cat].keys.each do |subcat|	
					@data[index][cat][subcat].delete('id'.to_sym)
					@data[index][cat][subcat].delete("#{cat}_id".to_sym)
				end
			end
		end
		@data # as a hash of a hash of a hash
	end
	def slice_matches(matches)  
		measures = []
		# matches is the result of a Msrun.all OR Msrun.first OR Msrun.get(*args)
		@data = {}
		matches.each do |msrun|
			next if msrun.metric.nil?
				index = msrun.raw_id.to_s
				puts "0000000000000000000000000000000000000000000"
				puts "file: (raw_id) : #{index}"
				@data[index] = {'timestamp' => msrun.rawtime || Time.now}
			@@categories.each do |cat|
				@data[index][cat] = msrun.metric.send(cat.to_sym).hashes
				@data[index][cat].keys.each do |subcat|	
					@data[index][cat][subcat].delete('id'.to_sym)
					@data[index][cat][subcat].delete("#{cat}_id".to_sym)
					@data[index][cat][subcat].each { |property, value| 
						measures << Measurement.new( property, index, msrun.rawtime, value, cat.to_sym, subcat.to_sym) }
				end
			end
		end
		p measures.first.raw_id
		p measures.size
		output = measures.first
		puts output.size
		output
	end	# returns array of measures
	def graph_matches(matches)
		meaures = slice_matches(matches) #|| @measures
		puts measures.length
		require 'rserve/simpler'
		p measures.first.raw_id
		p measures.first
		files = measures.map {|item| item.raw_id}.uniq
		p files
		@@categories.map {|cat| }
		abort
		
		
		#should graph the results... probably only if there are significant differences, but should also allow for specification of the parameter to graph... right?
		# maybe I can have it only do a category at a time, and generate multiple graphs, one for each quality in the subset... crap this is getting complicated!!!
	end # graphmatches






# CLASS variables that I don't ever want to have to see!!!!
	@@ref_hash = { 
spectrum_counts: "ion_source", 	first_and_last_ms1_rt_min: "chromatography", 	middle_peptide_retention_time_period_min: "chromatography", max_peak_width_for_ids_sec: "chromatography", peak_width_at_half_height_for_ids: "chromatography", peak_widths_at_half_max_over_rt_deciles_for_ids: "chromatography", wide_rt_differences_for_ids_4_min: "chromatography", 	
					 rt_ms1max_rt_ms2_for_ids_sec: "chromatography",	ms1_during_middle_and_early_peptide_retention_period: "ms1", 	ms1_total_ion_current_for_different_rt_periods: "ms1", ms1_id_max: "ms1", 	nearby_resampling_of_ids_oversampling_details: "dynamic_sampling", 	early_and_late_rt_oversampling_spectrum_ids_unique_peptide_ids_chromatographic_flow_through_bleed: "dynamic_sampling", peptide_ion_ids_by_3_spectra_hi_vs_1_3_spectra_lo_extreme_oversampling: "dynamic_sampling", 
					 ratios_of_peptide_ions_ided_by_different_numbers_of_spectra_oversampling_measure: "dynamic_sampling", single_spectrum_peptide_ion_identifications_oversampling_measure: "dynamic_sampling", ms1max_ms1sampled_abundance_ratio_ids_inefficient_sampling: "dynamic_sampling", ion_injection_times_for_ids_ms: "ion_source", top_ion_abundance_measures: "ion_source", number_of_ions_vs_charge: "ion_source", 
					 ion_ids_by_charge_state_relative_to_2: "ion_source",	average_peptide_lengths_for_different_charge_states: "ion_source", average_peptide_lengths_for_charge_2_for_different_numbers_of_mobile_protons: "ion_source", numbers_of_ion_ids_at_different_charges_with_1_mobile_proton: "ion_source", percent_of_ids_at_different_charges_and_mobile_protons_relative_to_ids_with_1_mobile_proton: "ion_source", precursor_m_z_monoisotope_exact_m_z: "ion_treatment", 
					 tryptic_peptide_counts: "peptide_ids",	peptide_counts: "peptide_ids",	total_ion_current_for_ids_at_peak_maxima: "peptide_ids",	precursor_m_z_for_ids: "peptide_ids",	averages_vs_rt_for_ided_peptides: "peptide_ids",	precursor_m_z_peptide_ion_m_z_2_charge_only_reject_0_45_m_z: "ms2",	ms2_id_spectra: "ms2",	ms1_id_abund_at_ms2_acquisition: "ms2",	ms2_id_abund_reported: "ms2",	
					 relative_fraction_of_peptides_in_retention_decile_matching_a_peptide_in_other_runs: "run_comparison", 	relative_uniqueness_of_peptides_in_decile_found_anywhere_in_other_runs: "run_comparison", differences_in_elution_rank_percent_of_matching_peptides_in_other_runs: "run_comparison", median_ratios_of_ms1_intensities_of_matching_peptides_in_other_runs: "run_comparison", 
					 uncorrected_and_rt_corrected_relative_intensities_of_matching_peptides_in_other_runs: "run_comparison", magnitude_of_rt_correction_of_intensities_of_matching_peptides_in_other_runs: "run_comparison"
		}

		@@categories = ["chromatography", "ms1", "dynamic_sampling", "ion_source", "ion_treatment", "peptide_ids", "ms2", "run_comparison"]
end #Metric grapher fxns
