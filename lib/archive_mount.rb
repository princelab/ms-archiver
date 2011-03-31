#!/usr/bin/env ruby

# System dependent locations
if ENV["HOME"][/\/home\//] == '/home/'
	Orbi_drive = "#{ENV["HOME"]}/chem/orbitrap/"
	Jtp_drive = "#{ENV["HOME"]}/chem/lab/RAW/"
	Database = "#{ENV["HOME"]}/chem/lab/"
elsif ENV["OS"][/Windows/] == 'Windows'
	Orbi_drive = "O:\\"
	Jtp_drive = "S:\\RAW\\"
	Database = "S:\\"
end
Jtp_mount = MountedServer::MountMapper.new(Jtp_drive)
Orbi_mount = MountedServer::MountMapper.new(Orbi_drive)
Db_mount = MountedServer::MountMapper.new(Database)


class ArchiveMount
	# I'm thinking that we can have a smart mount that knows your windows/linux location and thereby knows the actual location of every file you might need within the file structure.
=begin
	root = ..group/user/YYYYMM/experiment_name/
	./init/ Files pertinent to the initialization of the data such as the TUNE and METHOD and UPLC files.
	./metrics/ All the metrics stuff
	./ident/ identification analysis
	./quant/ quantification analysis
	./results/ Results of the analysis
	./graphs/ graphs of the Metrics and UPLC results (SO the HTML will rest here!)
	./samplename(s).RAW
	./mzML/ The mzXML and mzML files
	./config.yml
	./archive/ 	ANY other log files, or previous config files that might be stored

=end
#@location = [group, user, mtime, experiment_name]
	def build_archive # @location == LOCATION(group, user, mtime, experiment_name)
		# cp the config file from the higher level down
		@@build_directories.each do |dir|
			mkdir dir
		end

	end

	def sys_check? # Returns an indication of the system you are on
		"Windows" if ENV["OS"][/Windows/] == 'Windows'
		"Linux" if ENV["HOME"][/\/home\//] == '/home/'
	end



end

