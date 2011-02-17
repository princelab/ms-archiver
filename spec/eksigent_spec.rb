require 'spec_helper'

describe 'Matches to graph trace file from rawfile time' do 
	@tmp = Ms::Eksigent::Ultra2D.new
	@tmp.rawfile = TESTFILE + '/time_test.RAW'

	it 'finds rawtime' do 
		@tmp.find_match
		@tmp.rawtime.should.equal File.mtime(@tmp.rawfile)
	end
	it 'finds ek2_*.txt file' do 
#		@tmp.hplcfile.should.equal @tmp.eksfile 
		File.extname(@tmp.eksfile).should.equal '.txt'
		@tmp.eksfile[/^.*\/ek2_.*\.txt/].should.equal @tmp.eksfile
	end
	it 'parses the ek2_*.txt file correctly' do 
		@tmp.eksfile = TESTFILE + '/ek2_test.txt'

	end
end

describe 'graphs eksigent output' do 
	it 'generates a .pdf with the appropriate name' do 
		File.exist?(@tmp.graphfile).should.be true
	end
end


