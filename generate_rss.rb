require 'rubygems'
require 'nokogiri'
require 'fastercsv'
require 'yaml'
require 'ruby-debug'

rss = "podcast.rss"

class Rss
  CONFIG_FILE = 'podcast.yml'
  PODCASTS = 'podcasts.csv'
  @filename
  @publish_time = Time.now.strftime "%a, %d %b %Y %H:%M:%S %z"

  def initialize(filename)
    @config = readme = YAML::load( File.open( CONFIG_FILE ) )
    @filename = filename
  end  

  def update_or_create
    if(File.exists? @filename)
      update
    else
      create
    end
  end
  
  def build_item(xml, p)
    xml.title p['title']
    xml.link p['link to more info']
    xml.guid p['url']
    xml.description p['description']
    xml.enclosure "url" => p['url'], 'type' => 'video/mpeg'
    xml.category 'TODO' #TODO
    xml.pubDate @publish_time
    xml.send :"itunes:author", 'href' => @config['author'] 
    xml.send :"itunes:explicit", 'href' => p['explicit'] 
    xml.send :"itunes:subtitle", 'href' => p['description'] 
    xml.send :"itunes:summary", 'href' => p['description'] 
    xml.send :"itunes:duration", 'href' => p[''] #TODO 
    xml.send :"itunes:keywords", 'href' => p['tags'] 
    xml
  end

  def build_entire_rss
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.rss('xmlns:itunes' => "http://www.itunes.com/dtds/podcast-1.0.dtd", 'version'=>'2.0'){
        xml.channel{
          xml.title @config['title']
          xml.description @config['description'] 
          xml.link @config['link']
          xml.language @config['language']
          xml.copyright Time.now.strftime '%Y'
          xml.lastBuildDate @publish_time
          xml.pubDate @publish_time
          xml.docs ''
          xml.webMaster ''
          xml.send :"itunes:author", @config['author']
          xml.send :"itunes:subtitle", @config['description'] 
          xml.send :"itunes:summary", @config['description'] 
          xml.send(:"itunes:owner"){
            xml.send :"itunes:name", @config['author'] 
            xml.send :"itunes:email", @config['email'] 
          }
          xml.send :"itunes:explicit", @config['explicit'] 
          xml.send :"itunes:image", 'href' => @config['image'] 
          xml.item{
            FCSV.foreach(PODCASTS, :headers => true) do |row| 
              build_item xml, row.to_hash 
            end
          }
        } #channel
      } #rss
    end
    builder
  end

  def create
   File.open(@filename, 'w') {|f| f.write(build_entire_rss.to_xml) } 
  end

  def update
    files_to_update = podcasts_urls - item_guids 
    rss = Nokogiri::XML(File.new(@filename,"r"))    
    items = Nokogiri::XML::Builder.new do |xml|
        xml.root{
          podcasts{|p| p}.each do |p|
            xml.item{build_item(xml,p)} if files_to_update.include? p['url']
          end
        }
    end
    rss.css('item').first.before(items.doc.css('item').to_xml)
     File.open(@filename, 'w') {|f| f.write(rss.to_xml) } 
  end

  def podcasts(&do_to_podcast)
    results = []
    FCSV.foreach(PODCASTS, :headers => true) do |row| 
      results << do_to_podcast.call(row.to_hash)
    end
    results
  end

  def items(&do_to_item)
    results = []
    f = File.open(@filename)
    doc = Nokogiri::XML(f)
    doc.css('item').each do |item|
     results << do_to_item.call(item)
    end 
    f.close
    results
  end
  
  def podcasts_urls
    urls =[]
    podcasts{|p| urls << p['url']  }
    urls
  end
  

  def item_guids
    guids = []
    items do |item|  
      guids << item.css('guid').text()
    end
    guids
  end

   

end

Rss.new('podcast.rss').update_or_create


