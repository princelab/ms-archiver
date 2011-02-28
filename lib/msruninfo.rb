MsrunInfoStruct = Struct.new(:sequencefile, :methodfile, :rawfile, :tunefile, :hplcfile, :graphfile, :metricsfile, :sequence_vial, :hplc_vial, :inj_volume, :archive_location, :rawid, :group, :user, :taxonomy) do 
	
end
require 'yaml'
require 'fileutils'
require 'mount_mapper'
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


require 'xcalibur'
require 'eksigent'
require 'spawn_client'
require 'metrics'
require 'database'

module Ms
	class MsrunInfo < 
		Struct.new(:sldfile, :methodfile, :rawfile, :tunefile, :hplcfile, :graphfile, :metricsfile, :sequence_vial, :hplc_vial, :inj_volume, :archive_location, :rawid, :group, :user, :taxonomy) 
		attr_accessor :data_struct 
		def initialize(struct = nil)
			if struct
				struct.members.each do |sym|
					self.send("#{sym}="	, struct[sym])
				end
			end
		end
		def grab_files
			@tunefile = Ms::Xcalibur::Method.new(@methodfile).tunefile
			@hplc_object = Ms::Eksigent::Ultra2D.new(@rawfile)
			@hplcfile = @hplc_object.eksfile
		end
		def fill_in 
			grab_files if @tunefile.nil?
			@inj_volume = @hplc_object.inj_vol
			@hplcfile = @hplc_object.eksfile
			@hplc_vial = @hplc_object.autosampler_vial
		end
		def move_files
			
		end
		def graph_pressure
			@graphfile = @hplc_object.graph
		end
	end # MsrunInfo
end # Ms



