
# Nexpose Ruby
# This script will update/create a tag and apply rules based on a preformatted CSV file

require 'nexpose'           # Needed for Nexpose functionality
require 'csv'               # Needed for CSV processing
require "highline/import"   # Needed for ask prompt code

#
# Nexpose connection variables
#
def get_username(prompt = 'Enter Nexpose username: ')
    ask(prompt) { |query| query.echo = true }
end 
def get_password(prompt = 'Enter Nexpose Password: ')
    ask(prompt) { |query| query.echo = false }
end    
def get_nexposehost(prompt = 'Enter Nexpose Hostname: ')
    ask(prompt) { |query| query.echo = true}
end
def get_tagname(prompt = 'Enter Tag to update: ')
    ask(prompt) { |query| query.echo = true}
end
def get_csvfilename(prompt = 'Enter CSV filename: ')
    ask(prompt) { |query| query.echo = true}
end
nexposehost = get_nexposehost
nexposeport = "3780" # Assuming default port
nexposeuser = get_username
nexposepass = get_password
tagname = get_tagname
csvfile = get_csvfilename


#
# Connect and auth
#
begin
    # Create connection to nexpose instance
    nsc = Nexpose::Connection.new(nexposehost,nexposeuser,nexposepass,nexposeport)

    # Authenticate connection
    nsc.login

rescue ::Nexpose::APIError => e
    $stderr.puts ("Connection failed: #{e.reason}")
    exit(1)
end

#
# Check if CSV file exists
#
if File.exist?(csvfile) 
    puts "The CSV file is valid, we can continue"
else
    puts "Could not find the CSV file, exiting"
    exit
end


#
# Check if the tag already exists
#
tag_find = nsc.list_tags.find { |t| t.name == tagname}

if tag_find.to_s.empty?
    # tag doesn't exist and we can create it
    puts "The tag name wasn't found, so it will be created"
    # Create the tag
    tag = Nexpose::Tag.new(tagname,Nexpose::Tag::Type::Generic::CUSTOM)

else
    # tag does exist
    puts "The tag name was found"
    tagId = tag_find.id
    tag = Nexpose::Tag.load( nsc, tagId)
    #tag = nsc.list_tags.find { |t| t.name == tagname}

    # Reset search terms
    puts "Resetting search criteria back to nothing"
    clear_criteria = Nexpose::Tag::Criteria.new(criteria=[], match='OR')
    tag.search_criteria = clear_criteria
    tag.save(nsc)

end

new_criteria = Nexpose::Tag::Criteria.new(criteria=[], match='OR')

#
# Load CSV and iterate through it
#
#begin
CSV.foreach(csvfile,headers: true) do |row|
    #puts "Creating tag criterion using IP address #{row['Int IP address']}"
    criterion = Nexpose::Tag::Criterion.new('IP_RANGE', 'IS', [row['IP']])
    #puts "Assinging criterion to criteria"
    new_criteria << criterion

end
    puts "Criteria is #{new_criteria}"
#end

#
# Save the tag
#
tag.search_criteria = new_criteria
tag.save(nsc)

