require 'spec_helper'
require 'xcalibur'
Test_sld = { v2_0: TESTFILE + '/SWG_serum_100511165501.sld', v2_1: TESTFILE + '/_110131184745.sld'}
Test_meth = { v2_0: 'C:\\Xcalibur\\methods\\SWG_serum_sample.meth', v2_1: 'C:\\Xcalibur\\methods\\test1_1_etd.meth'}


describe 'Parses SLD files' do 
	it 'parses v2.1 w/postprocessing files' do 
		sld_file = Test_sld[:v2_1]
		@sld = Ms::Xcalibur::Sld.new(sld_file)
		@sld.parse
		match = @sld.sets.first.methodfile
		@sld.sets.first.methodfile.should.equal Test_meth[:v2_1]
		@sld.sets.first.sequence_vial.should.equal '2A05'
	end
	it 'parses v2.07 files' do 
		sld_file = Test_sld[:v2_0]
		@sld = Ms::Xcalibur::Sld.new(sld_file)
		@sld.parse
		@sld.sets.first.methodfile.should.equal Test_meth[:v2_0]
		@sld.sets.first.sequence_vial.should.equal '2B01'
	end
end

describe 'Parses method files' do 
	it 'returns a .LTQTune' do 
		methodfiles = [TESTFILE + '/45min.meth', TESTFILE + '/BSA.meth']
		methodfiles.each do |file|
			method = Ms::Xcalibur::Method.new(file)
			method.parse
			method.tunefile[/(\..*)$/].should.equal ".LTQTune"
		end
	end
end

if ENV["OS"] && ENV["OS"][/Windows/] == 'Windows'
	describe 'finds eksigent output files' do 
		it 'uses a raw to find an ek2_[/.*/].txt file' do 
			testraw = TESTFILE + '/time_test.RAW'
			test = Ms::Eksigent::Ultra2D.new(testraw)
			test.eksfile.should.equal 'ek2_test.txt'
# AH crap... I need a solution across all platforms... ?
# ...other than the temp one I just implemented...
		end
	end
end

describe 'Builds the MsrunInfo thing' do 
	before do 
		sld_file = Test_sld[:v2_0]
		@sld = Ms::Xcalibur::Sld.new(sld_file).parse
		@sld.sets[0].rawfile = TESTFILE + '/time_test.RAW'
	#	@sld.sets.first.rawfile.should.equal 'time_test.raw'
		@msrun = Ms::MsrunInfo.new(@sld.sets[0])
		@msrun.rawfile.should.equal @sld.sets.first.rawfile
		@msrun.grab_files
	end
	it 'gets tunefile' do 
		@msrun.tunefile[/(\..*)$/,1].should.equal ".LTQTune"
		end
	it 'gets eksfile' do 
		@msrun.hplcfile[/ek2.*(\..*)$/,1].should.equal ".txt"
	end
	it 'has same data as @sld' do 
		@sld.sldfile.should.equal @msrun.sldfile
		@sld.sets.first.methodfile.should.equal @msrun.methodfile
		@sld.sets.first.rawfile.should.equal @msrun.rawfile
		@sld.sets.first.sequence_vial.should.equal @msrun.sequence_vial
	end
end


if ENV["OS"] && ENV["OS"][/Windows/] == 'Windows'
	describe 'finds eksigent output files' do 
	
	end
end
