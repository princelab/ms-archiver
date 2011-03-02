require 'spec_helper'

=begin
describe 'generates metrics' do 

	it 'runs the NIST package to generate metrics over SSH' do 

	end

	it 'returns a "next" signal from the metrics generation process by SSH' do 
	
	end

end

describe 'parses metrics and databases them' do
	before do 
		@metric = Metric.new( TESTFILE + '/test3__1.txt')
		@metric.slice_hash
		@metric.to_database
		@matches = Msrun.all # matches is the result of a Msrun.all OR Msrun.first OR Msrun.get(*args)
	end	
	it 'has appropriate test values... (find test values)' do 
		@metric.parse.class.should.equal Hash
	end

	it 'sends the data to the database' do
		measure = @metric.slice_hash.first
		raw_id = measure.raw_id
		@match = Msrun.first( raw_id)
		@match.class.should.equal Msrun
	end

	it 'pulls back the metric test from the database' do 
		@match.raw_id.should.equal @metric.raw_ids.first
	end

end

=end
describe 'graphs metrics' do 
	before do 
		@metric = Metric.new( TESTFILE + '/test3__1.txt')
		@measures = @metric.slice_hash
		@metric.to_database
		@matches = Msrun.all 
	end
	it 'generates pdfs with the [filename]_category.pdf name' do 
		puts "\n"
		@metric.graph_matches(@matches)
	end
end

