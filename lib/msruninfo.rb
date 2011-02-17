MsrunInfoStruct = Struct.new(:sequencefile, :methodfile, :rawfile, :tunefile, :hplcfile, :graphfile, :metricsfile, :sequence_vial, :hplc_vial, :inj_volume, :archive_location, :rawid, :group, :user, :taxonomy) do 
	
end

require 'mount_mapper'
require 'fileutils'
require 'xcalibur'

# System Specific Constants
Nist_dir = "C:\\NISTMSQC\\scripts"
Nist_exe = "C:\\NISTMSQC\\scripts\\run_NISTMSQC_pipeline.pl"
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


module Ms
	class MsrunInfo < 
		Struct.new(:sequencefile, :methodfile, :rawfile, :tunefile, :hplcfile, :graphfile, :metricsfile, :sequence_vial, :hplc_vial, :inj_volume, :archive_location, :rawid, :group, :user, :taxonomy) 
		attr_accessor :data_struct, 
		def initialize(struct = nil)
			super()
			@rawtime = File.mtime(@rawfile)
			@rawid = Orbi_mount.basename(@rawfile)
		end
		def fill_in 
			@tunefile = Ms::Xcalibur::Method.new(@methodfile).tunefile
			@hplc_object = Ms::Eksigent::Ultra2D.new(@rawfile)
			@inj_volume = @hplc_object.inj_vol
			@hplcfile = @hplc_object.eksfile
			@hplc_vial = @hplc_object.autosampler_vial
		end
		def graph_pressure
			@graphfile = @hplc_object.graph
		end
	end # MsrunInfo
end # Ms
