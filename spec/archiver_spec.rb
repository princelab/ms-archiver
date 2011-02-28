require 'spec_helper'

#require 'parse_spec'
#require 'eksigent_spec'
#require 'metric_spec'
#require 'database_spec'

describe 'MsrunInfo Object behaves' do 
	before do 
		file = TESTFILE + '/SWG_serum_100511165501.sld'
		@sld = Ms::Xcalibur::Sld.new(file).parse
		@sld.sldrows[0].rawfile = TESTFILE + '/time_test.RAW'
		@msrun = Ms::MsrunInfo.new(@sld.sldrows[0])
		@msrun.grab_files
		@yaml = @msrun.to_yaml
	end
	it 'goes to and from yaml identically' do 
		YAML.load(@yaml).should.equal @msrun
	end
end

describe 'Archiver writes to network location' do 
	it 'copied files' do 
		
	end

	it 'updated locations' do 

	end

end
describe 'Ssh Utility' do
	before do 
		file = TESTFILE + '/SWG_serum_100511165501.sld'
		@sld = Ms::Xcalibur::Sld.new(file).parse
		@sld.sldrows[0].rawfile = TESTFILE + '/time_test.RAW'
		@msrun = Ms::MsrunInfo.new(@sld.sldrows[0])
		@msrun.grab_files
		@yaml = @msrun.to_yaml
	end
	it 'sends the correct signal' do 
		to_linux(@msrun.to_yaml).should.equal "C:\\cygwin\\bin\\ssh ryanmt@jp1 -C '/home/ryanmt/Dropbox/coding/ms/archiver/lib/archiver.rb --linux /tmp/tmp.yml '"

	end

		



end
