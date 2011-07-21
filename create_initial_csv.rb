require 'rubygems'
#require 'FasterCSV'
require 'csv'

podcasts = "podcasts.csv"
if ! File.exists? podcasts
  CSV.open(podcasts, "wb") do |csv|
      csv << ["url", "title", "link to more info", "description", "pubDate", "tags", "explicit" ]
  end
end
