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
		@metric.parse
		@metric.generate_measures
		@metric.to_database
		matches = 'hello'  # matches is the result of a Msrun.all OR Msrun.first OR Msrun.get(*args)
		@metric.from_database(matches)
	end	
	it 'has appropriate test values... (find test values)' do 
		@metric.parse.class.should.equal "Hash"
	end

	it 'sends the data to the database' do

	end

	it 'pulls back the metric test from the database' do 

	end

end


describe 'graphs metrics' do 
	before do 
		@metric = Metric.new( TESTFILE + '/test3__1.txt')
		@out_hash =	@metric.parse
		@measures = @metric.generate_measures
	end
	it 'generates pdfs with the [filename]_category.pdf name' do 

	end
end
