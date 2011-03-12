#!/usr/bin/ruby

require 'msruninfo'
require 'rubygems'
require 'yaml'

class ::Measurement < 
# Structure, the entire basis for this class
	Struct.new(:name, :raw_id, :time, :value, :category, :subcat)
end

class Metric		# Metric parsing fxns
	attr_accessor :out_hash, :metricsfile, :rawfile, :raw_ids
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
					@num_files = key[/files_analyzed_(\d*)/,1].to_i if key[/(files_analyzed_).*/,1] == "files_analyzed_"
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
					@measures << Measurement.new( property, File.basename(file,".RAW.MGF.TSV"), @rawtime, value[item], @@ref_hash[subcategory.to_sym].to_sym, subcategory.to_sym)
				end
			end
			item +=1
		end
		@measures
	end
	def to_database
		require 'dm-migrations'
			DataMapper.auto_migrate!  # This one wipes things!
	#		DataMapper.auto_upgrade!
		objects = []; item = 1
		@metrics_input_files.each do |file|
			tmp = Msrun.first_or_create({raw_id: "#{File.basename(file,".RAW.MGF.TSV")}",  metricsfile: @metricsfile}) # rawfile: "#{File.absolute_path(File.basename(file, ".RAW.MGF.TSV")) + ".RAW"}",
			tmp.metric = Metric.first_or_create({msrun_raw_id: "#{File.basename(file, ".RAW.MGF.TSV")}"}) #, metric_input_file: @metricsfile })#"#{File.absolute_path(@metricsfile)}"})
			@@categories.map {|category|  tmp.metric.send("#{category}=".to_sym, Kernel.const_get(camelcase(category)).first_or_create({id: tmp.metric.msrun_id})) }
			@out_hash.each_pair do |key, value_hash|
				outs = tmp.metric.send((@@ref_hash[key.to_sym]).to_sym).send("#{key.downcase}=".to_sym, Kernel.const_get(camelcase(key)).first_or_create({id: tmp.metric.msrun_id}))#, value_hash )) 
					value_hash.each_pair do |property, array|
						tmp.metric.send((@@ref_hash[key.to_sym]).to_sym).send("#{key.downcase}".to_sym).send("#{property}=".to_sym, array[item-1])
					end
				tmp.metric.send((@@ref_hash[key.to_sym]).to_sym).send("#{key.downcase}".to_sym).save
			end
			item +=1
			objects << tmp
		end
		worked = objects.map{|obj| obj.save!}
		puts "\n----------------\nSave failed\n----------------" if worked.uniq.include?(false)
		false if worked.uniq.include?(false)
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
		matches = [matches] if matches.class != DataMapper::Collection
		matches.each do |msrun|
			next if msrun.metric.nil?
			p msrun.raw_id
			index = msrun.raw_id.to_s
			@data[index] = {'timestamp' => msrun.rawtime || Time.now}
			@@categories.each do |cat|
				@data[index][cat] = msrun.metric.send(cat.to_sym).hashes
				@data[index][cat].keys.each do |subcat|	
					@data[index][cat][subcat].delete('id'.to_sym)
					@data[index][cat][subcat].delete("#{cat}_id".to_sym)
					@data[index][cat][subcat].delete("#{cat}_metric_msrun_id".to_sym)
					@data[index][cat][subcat].delete("#{cat}_metric_msrun_raw_id".to_sym)
					@data[index][cat][subcat].delete_if {|key,v| puts "Key: #{key} \n Value: #{v}" if key.nil?}
					@data[index][cat][subcat].each { |property, value| 
						puts "Key: #{property} \n Value: #{value}" if property.nil?
						measures << Measurement.new( property, index, @data[index]['timestamp'], value, cat.to_sym, subcat.to_sym) }
				end
			end
		end
		measures.compact
	end	# returns array of measurements
	def graph_matches(new_match, old_match)
		require 'rserve/simpler'
		graphfiles = []
		measures = [slice_matches(new_match), slice_matches(old_match)]
		rawids = [measures.first.map {|item| item.raw_id}.uniq, measures.last.map {|item| item.raw_id}.uniq]
		rawids.first.each do |rawid|
			@@categories.map do |cat| 
				new_subcats = measures.first.map{|meas| meas.subcat if meas.category == cat.to_sym}.compact.uniq
				subcats = new_subcats 
				subcats.each do |subcategory|
					graphfile = File.join([cat, (rawid + '_' + subcategory.to_s)]) + '.pdf'
					graphfiles << graphfile
					r_object = Rserve::Simpler.new 
					new_structs = measures.first.map{|meas| meas if meas.subcat == subcategory.to_sym}.compact
					old_structs = measures.last.map{|meas| meas if meas.subcat == subcategory.to_sym}.compact
					[new_structs, old_structs].each do |structs|
						structs.each do |str|
							str.value = str.value.to_f
							str.name = str.name.to_s
							str.category = str.category.to_s
							str.subcat = str.subcat.to_s
							str.time = str.time.to_s.gsub(/T/, ' ').gsub(/-(\d*):00/,' \100')
						end
					end
=begin
					require 'yaml'
					require 'rserve/simpler'; datafr = YAML.load_file('metrics_datafr.yml'); r = Rserve::Simpler.new

format(as.POSIXlt(arr), format="%y%m%d %X")
2011-03-03T14:38:07-07:00 Must be converted to 
"2011-03-03 14:38:07 0700"
["2011", "03", "03", "14", "38", "07", "07", "00"]
=end
					datafr_new = Rserve::DataFrame.from_structs(new_structs)
					datafr_old = Rserve::DataFrame.from_structs(old_structs)
					r_object.converse( df_new: datafr_new )	do 		
						#		pdf(file="#{graphfile}", height=9, width=16)
						%Q{format(df_new$time <- as.POSIXlt(df_new$time), format="%y%m%d %X")
							df_new$name <- factor(df_new$name)
							df_new$category <-factor(df_new$category)
							df_new$subcat <- factor(df_new$subcat)
							df_new$raw_id <- factor(df_new$raw_id)
						}
					end # new datafr converse
					r_object.converse( df_old: datafr_old) do 
						%Q{format(df_old$time <- as.POSIXlt(df_old$time), format="%y%m%d %X")
							df_old$name <- factor(df_old$name)
							df_old$category <-factor(df_old$category)
							df_old$subcat <- factor(df_old$subcat)
							df_old$raw_id <- factor(df_old$raw_id)
						}
					end # old datafr converse
					count = new_structs.map {|str| str.name }.uniq.compact.length
					rows = (count / 3.0).ceil
					i = 1;
					while i <= count
						r_object.converse do 
							%Q{	df_new.#{i} <- subset(df_new, name == levels(df_new$name)[[#{i}]])
								df_old.#{i} <- subset(df_old, name == levels(df_old$name)[[#{i}]])			
							}
						end # Configure the environment for the graphing, by setting up the numbered categories
						i += 1 
					end
					r_object.converse do 
						%Q{
							library("beanplot")
							par(mfrow=c(#{rows},3))
						}
					end # graph configuring
					i = 1;
					p r_object.converse('ls()')
#					p r_object.converse('df_new')
#					#p r_object.converse('df_old')
#					p r_object.converse('df_new.1')
#					p r_object.converse('df_old.1')
#					p r_object.converse('df_new.2')
#					p r_object.converse('df_old.2')
					p r_object.converse('class(df_old.2$time[[1]])')
					p r_object.converse('df_old.2$time')
					p r_object.converse('df_old.2$value')
					p r_object.converse("plot(df_old.#{i}$time, df_old.#{i}$value,type='l')")
					r_object.pause
					while i <= count
						r_object.converse do 
							%Q{ band1 <- try(bw.SJ(df_old.#{i}$value), silent=TRUE) 
							if(inherits(band1, 'try-error')) band1 <- try(bw.nrd0(df_old.#{i}$value), silent=TRUE)
					#			band2 <- try(bw.SJ(df_new.#{i}$value), silent=TRUE)
					#		if(inherits(band2, 'try-error')) band2 <- try(bw.nrd0(df_new.#{i}$value), silent=TRUE)
								beanplot(df_old.#{i}$value, df_new.#{i}$value, side='both', log="", ll=0.4, names=df_old$name[[#{i}]], col=list('grey',c('darkgrey', 'black')), bw=band1)
								par(fig=c(0,0.4,0,0.4), new=T)
								plot(df_old.#{i}$time, df_old.#{i}$value,type='l',ylab=df_old.#{i}$name[[1]])
							}
						end # graph it!!
						r_object.pause
						r_object.converse do 
							%Q{tmp <- layout(matrix(c(1,1,2,3),2,2,byrow=T), widths=c(1,1), heights=c(4,1))
							par(mar=c(.4,.4,.4,.4))

								layout.show(tmp)
							#	band1 <- try(bw.SJ(df_old.#{i}$value), silent=TRUE) 
						#	if(inherits(band1, 'try-error')) band1 <- try(bw.nrd0(df_old.#{i}$value), silent=TRUE)
beanplot(df_old.#{i}$value, df_new.#{i}$value, side='both', log="", ll=0.4, names=df_old$name[[#{i}]], col=list('grey',c('darkgrey', 'black')), bw=band1)

plot(df_old.#{i}$time, df_old.#{i}$value,type='l',ylab=df_old.#{i}$name[[1]])
plot(df_new.#{i}$time, df_new.#{i}$value,type='l',ylab=df_new.#{i}$name[[1]])
							}
						end
						r_object.pause
						i +=1
					end # while loop
				end # subcats
			end	# categories
		end	# files.each 
	
		
		#should graph the results... probably only if there are significant differences, but should also allow for specification of the parameter to graph... right?
		# maybe I can have it only do a category at a time, and generate multiple graphs, one for each quality in the subset... crap this is getting complicated!!!
		graphfiles
	end # graph_files






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
