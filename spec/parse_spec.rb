require 'spec_helper'
require 'xcalibur'

describe 'Parses SLD files' do 
	Test_sld = { v2_0: TESTFILE + '/SWG_serum_100511165501.sld', v2_1: TESTFILE + '/_110131184745.sld'}
	Test_meth = { v2_0: 'C:\\Xcalibur\\methods\\SWG_serum_sample.meth', v2_1: 'C:\\Xcalibur\\methods\\test1_1_etd.meth'}
	it 'parses v2.1 w/postprocessing files' do 
		sld_file = Test_sld[:v2_1]
		@sld = Ms::Xcalibur::Sld.new(sld_file)
		@sld.parse
		match = @sld.sets.first.methodfile
		@sld.sets.first.methodfile.should.equal Test_meth[:v2_1]
		@sld.sets.first.vial.should.equal '2A05'
	end
	it 'parses v2.07 files' do 
		sld_file = Test_sld[:v2_0]
		@sld = Ms::Xcalibur::Sld.new(sld_file)
		@sld.parse
		@sld.sets.first.methodfile.should.equal Test_meth[:v2_0]
		@sld.sets.first.vial.should.equal '2B01'
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

describe 'finds eksigent output files' do 
	
	it 'uses a raw to find an ek2_[/.*/].txt file' do 

	end
end
