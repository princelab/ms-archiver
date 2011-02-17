require 'spec_helper'

describe 'Parses SLD files' do 
	Test_sld = { v2_0: TESTFILE + '/SWG_serum_100511165501.sld', v2_1: TESTFILE + '/_110131184745.sld', v_test: TESTFILE + '/test.sld'}
	Test_meth = { v2_0: 'C:\\Xcalibur\\methods\\SWG_serum_sample.meth', v2_1: 'C:\\Xcalibur\\methods\\test1_1_etd.meth', v_test: 'spec/tfiles/ .meth'}
	it 'parses v2.1 w/postprocessing files' do 
		sld_file = Test_sld[:v2_1]
		@sld = Xcalibur::Sld.new(sld_file)
		@sld.methodfile.should.equal Test_meth[:v2_1]
	end
	it 'parses v2.07 files' do 

	end
	it 'parses v2.1 files' do 

	end
end

describe 'Parses method files' do 
	it 'parses method file' do 

	end

end

describe 'finds eksigent output files' do 
	
	it 'uses a raw to find an ek2_[/.*/].txt file' do 

	end
end
