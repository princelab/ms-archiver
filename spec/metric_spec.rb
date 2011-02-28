require 'spec_helper'


describe 'generates metrics' do 

	it 'runs the NIST package to generate metrics over SSH' do 

	end

	it 'returns a "next" signal from the metrics generation process by SSH' do 
	
	end

end

describe 'parses metrics and databases them' do
	before do 
		@metric = Metric.new( TESTFILE + '/test3__1.txt')
		@out_hash =	@metric.parse
		
		
	end	
	it 'parses metric test file' do
		@metric.slice_hash
	end

	it 'has appropriate test values... (find test values)' do 

	end

end


describe 'graphs metrics' do 
	before do 
		@metric = Metric.new( TESTFILE + '/test3__1.txt')
		@out_hash =	@metric.parse

	end
	it 'generates pdfs with the [filename]_category.pdf name' do 

	end
end
