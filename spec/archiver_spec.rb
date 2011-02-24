require 'spec_helper'

#require 'parse_spec'
#require 'eksigent_spec'
#require 'metric_spec'
#require 'database_spec'

describe 'info object behaves properly' do 
	before do 
		file = TESTFILE + '/SWG_serum_100511165501.sld'
		@sld = Ms::Xcalibur::Sld.new(file).parse
		@sld.sets[0].rawfile = TESTFILE + '/time_test.RAW'
		@msrun = Ms::MsrunInfo.new(@sld.sets[0])
		@msrun.grab_files
		@yaml = @msrun.to_yaml
	end
	it 'goes to and from yaml identically' do 
		YAML.load(@yaml).should.equal @msrun
	end
end

describe 'archives to network location' do 

	it 'copied files' do 

	end

	it 'updated locations' do 

	end

describe 'Passes object around via ssh successfully' do
	before do 
		file = TESTFILE + '/SWG_serum_100511165501.sld'
		@sld = Ms::Xcalibur::Sld.new(file).parse
		@sld.sets[0].rawfile = TESTFILE + '/time_test.RAW'
		@msrun = Ms::MsrunInfo.new(@sld.sets[0])
		@msrun.grab_files
		@yaml = @msrun.to_yaml
	end
	it 'sends the correct signal'
		true

	end

		



end
