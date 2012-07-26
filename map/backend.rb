#!/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'data_mapper' # requires all the gems listed above

puts "Synchronizacja z bazą danych"
# DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite3:geo.db')

class Geo
  include DataMapper::Resource
  
  property :id, Serial
  property :voivodeship, String
  property :district, String
  property :commune, String
  property :lat, Float
  property :long, Float
end

class Monument
  include DataMapper::Resource
  
  property :id, Serial
  property :relic_id, Integer
  property :name, Text
  property :lat, Float
  property :long, Float
  property :action, String
  property :touched, Integer
end

DataMapper.finalize

DataMapper.auto_upgrade!

#"export_id","suggested_at","relic_id","nid_id","nid_kind","relic_ancestry","register_number","voivodeship","district","commune","place","place_id","place_id_action","identification","identification_action","street","street_action","dating","dating_action","latitude","longitude","coordinates_action","categories","categories_action"
#"rel_3402","2012-06-01 00:00:00","3402","593709","OZ","3400"," 863/J z 04.02.1985","dolnośląskie","lubański","Lubań","Jałowiec","18530","revision","Park (1. ogród przy pałacu, 2. ogród z mauzoleum, 3. aleja lipowa)","revision","","revision","","revision","51.0869991","15.3063884","revision","","revision"
#"rel_2479","2012-06-01 00:00:00","2479","592784","OZ","2478"," 1146/WŁ z 25.10.1985","dolnośląskie","kłodzki","Kudowa-Zdrój","Kudowa-Zdrój","95578","revision","Kościół par. p.w. św. Bartłomieja","revision","","revision","1384","revision","50.4427156","16.2426605","revision","","revision"

puts "Pobieranie najnowszej historii zmian"
`wget http://otwartezabytki.pl/system/relics_history.csv -a backend_wget_log`

rhFile = File.open("relics_history.csv", "r:UTF-8")

line = rhFile.readline

puts "Przetwarzanie historii zmian"
@relics = Hash.new
@relics[ "zabytkow" ] = 0
@relics[ "raz" ] = 0
@relics[ "dwa" ] = 0
@relics[ "trzy" ] = 0
@relics[ "czterywiecej" ] = 0
rhFile.each do |line|
  relic_change = line.slice(0, line.length-1).split(/","/)
  relic_id = relic_change[2]#.slice(1, relic_change[2].length-2)

  suggested_at = relic_change[1]#.slice(1, relic_change[1].length-2)
  puts "#{relic_change[0]}"
  
  monument_name = relic_change[13]
  lat = relic_change[19]
  long = relic_change[20]
  coordinates_action = relic_change[21]

  voivodeship = relic_change[7]
  if @relics[ voivodeship ] == nil
    @relics[ voivodeship ] = Hash.new
    @relics[ voivodeship ][ "zabytkow" ] = 0
    @relics[ voivodeship ][ "raz" ] = 0
    @relics[ voivodeship ][ "dwa" ] = 0
    @relics[ voivodeship ][ "trzy" ] = 0
    @relics[ voivodeship ][ "czterywiecej" ] = 0
  end
   
  district = relic_change[8]
   
  if @relics[ voivodeship ][ district ] == nil
    @relics[ voivodeship ][ district ] = Hash.new
    @relics[ voivodeship ][ district ][ "zabytkow" ] = 0
    @relics[ voivodeship ][ district ][ "raz" ] = 0
    @relics[ voivodeship ][ district ][ "dwa" ] = 0
    @relics[ voivodeship ][ district ][ "trzy" ] = 0
    @relics[ voivodeship ][ district ][ "czterywiecej" ] = 0
  end
   
  commune = relic_change[9]
   
  if @relics[ voivodeship ][ district ][ commune ] == nil
    @relics[ voivodeship ][ district ][ commune ] = Hash.new
    @relics[ voivodeship ][ district ][ commune ][ "zabytkow" ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "raz" ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "dwa" ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "trzy" ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "czterywiecej" ] = 0
  end
  
  
  if suggested_at == "2012-06-01 00:00:00" && @relics[ voivodeship ][ district ][ commune ][ relic_id ] == nil
    @relics[ voivodeship ][ district ][ commune ][ relic_id ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "zabytkow" ] += 1
    @relics[ voivodeship ][ district ][ "zabytkow" ] += 1
    @relics[ voivodeship ][ "zabytkow" ] += 1
    @relics[ "zabytkow" ] += 1
    Monument.find_or_create( {:relic_id => relic_id}, {:touched => 0, :action => coordinates_action, :lat => lat, :long => long})
  elsif @relics[ voivodeship ][ district ][ commune ][ relic_id ] == nil
    puts "Prawdopodobnie coś nie tak"
    @relics[ voivodeship ][ district ][ commune ][ relic_id ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "zabytkow" ] += 1
    @relics[ voivodeship ][ district ][ "zabytkow" ] += 1
    @relics[ voivodeship ][ "zabytkow" ] += 1
    @relics[ "zabytkow" ] += 1
    Monument.find_or_create( {:relic_id => relic_id}, {:touched => 0, :action => coordinates_action, :lat => lat, :long => long})
  elsif
    @relics[ voivodeship ][ district ][ commune ][ relic_id ] += 1
    
    @monument =  Monument.first(:relic_id => relic_id)
    if @monument.action == "revision" || @monument.action == "skip"
      if !@monument.update( :lat => lat, :long => long, :action => coordinates_action, :touched => 1 )
        puts "================================================="
        puts "#{relic_change[0]}: problemy z #{@monument.errors}"
        puts "================================================="
      end
    end
    
    if @relics[ voivodeship ][ district ][ commune ][ relic_id ] == 1
      @relics[ voivodeship ][ district ][ commune ][ "raz" ] += 1
      @relics[ voivodeship ][ district ][ "raz" ] += 1
      @relics[ voivodeship ][ "raz" ] += 1
      @relics[ "raz" ] += 1
    elsif @relics[ voivodeship ][ district ][ commune ][ relic_id ] == 2
      @relics[ voivodeship ][ district ][ commune ][ "dwa" ] += 1
      @relics[ voivodeship ][ district ][ "dwa" ] += 1
      @relics[ voivodeship ][ "dwa" ] += 1
      @relics[ "dwa" ] += 1
    elsif @relics[ voivodeship ][ district ][ commune ][ relic_id ] == 3
      @relics[ voivodeship ][ district ][ commune ][ "trzy" ] += 1
      @relics[ voivodeship ][ district ][ "trzy" ] += 1
      @relics[ voivodeship ][ "trzy" ] += 1
      @relics[ "trzy" ] += 1
    else
      @relics[ voivodeship ][ district ][ commune ][ "czterywiecej" ] += 1
      @relics[ voivodeship ][ district ][ "czterywiecej" ] += 1
      @relics[ voivodeship ][ "czterywiecej" ] += 1
      @relics[ "czterywiecej" ] += 1
    end    
  end
end

puts "Tworzenie pliku wyjściowego"

outputFile = File.open("output_temp.csv", "w:UTF-8")

puts "Podział administracyjny"
@relics.each do |voivodeship, voivodeship_hash|
  unless voivodeship == "zabytkow" || voivodeship ==  "raz" || voivodeship ==  "dwa" || voivodeship == "trzy" || voivodeship ==  "czterywiecej"
    voivodeship_hash.each do |district, district_hash|
      unless  district == "zabytkow" || district ==  "raz" || district ==  "dwa" || district == "trzy" || district ==  "czterywiecej"
        
        district_hash.each do |commune, commune_hash|
          unless  commune == "zabytkow" || commune ==  "raz" || commune ==  "dwa" || commune == "trzy" || commune ==  "czterywiecej"
            if commune_hash[ "raz" ] > 0
              if (@geo = Geo.first(:voivodeship => voivodeship, :district => district, :commune => commune)) == nil
                puts "Brak danych dla #{voivodeship} #{district} #{commune}"
                `wget "http://where.yahooapis.com/geocode?q=#{commune},#{district}&state=#{voivodeship.tr("ąćęłńóśżźĄĆĘŁŃÓŚŻŹ", "acelnoszzACELNOSZZ")}&country=Polska" -O koordynaty -a backend_wget_log`
                koordynatyFile = File.open("koordynaty", "r:UTF-8")
                koordynatyFile.each do |line|
                  if /.*<latitude>(?<lat>.*)<\/latitude>.*/.match(line)
                    @latitude = /.*<latitude>(?<lat>.*)<\/latitude>.*/.match(line)[:lat]
                  end
                  if /.*<longitude>(?<long>.*)<\/longitude>.*/.match(line)
                    @longitude = /.*<longitude>(?<long>.*)<\/longitude>.*/.match(line)[:long]
                  end
                end
                @geo = Geo.create(:voivodeship => voivodeship, :district => district, :commune => commune, :lat => @latitude, :long => @longitude)
              end
              outputFile.puts "commune;#{@geo.voivodeship};#{@geo.district};#{@geo.commune};#{commune_hash[ "raz" ]};#{@geo.lat};#{@geo.long}"
            end
            
          end
        end
        
        if district_hash[ "raz" ] > 0
          if (@geo = Geo.first(:voivodeship => voivodeship, :district => district, :commune => "")) == nil
            puts "Brak danych dla #{voivodeship} #{district}"
            `wget "http://where.yahooapis.com/geocode?q=#{district.tr("ąćęłńóśżźĄĆĘŁŃÓŚŻŹ", "acelnoszzACELNOSZZ")}&state=#{voivodeship.tr("ąćęłńóśżźĄĆĘŁŃÓŚŻŹ", "acelnoszzACELNOSZZ")}&country=Polska" -O koordynaty -a backend_wget_log`
            koordynatyFile = File.open("koordynaty", "r:UTF-8")
            koordynatyFile.each do |line|
              if /.*<latitude>(?<lat>.*)<\/latitude>.*/.match(line)
                @latitude = /.*<latitude>(?<lat>.*)<\/latitude>.*/.match(line)[:lat]
              end
              if /.*<longitude>(?<long>.*)<\/longitude>.*/.match(line)
                @longitude = /.*<longitude>(?<long>.*)<\/longitude>.*/.match(line)[:long]
              end
            end
            @geo = Geo.create(:voivodeship => voivodeship, :district => district, :commune => "", :lat => @latitude, :long => @longitude)
          end
          outputFile.puts "district;#{@geo.voivodeship};#{@geo.district};"";#{district_hash[ "raz" ]};#{@geo.lat};#{@geo.long}"
        end
      end
    end
    
    if voivodeship_hash[ "raz" ] > 0
    if (@geo = Geo.first(:voivodeship => voivodeship, :district => "", :commune => "")) == nil
    puts "Brak danych dla #{voivodeship}"
    `wget "http://where.yahooapis.com/geocode?state=#{voivodeship.tr("ąćęłńóśżźĄĆĘŁŃÓŚŻŹ", "acelnoszzACELNOSZZ")}&country=Polska" -O koordynaty -a backend_wget_log`
    koordynatyFile = File.open("koordynaty", "r:UTF-8")
    koordynatyFile.each do |line|
    if /.*<latitude>(?<lat>.*)<\/latitude>.*/.match(line)
    @latitude = /.*<latitude>(?<lat>.*)<\/latitude>.*/.match(line)[:lat]
    end
    if /.*<longitude>(?<long>.*)<\/longitude>.*/.match(line)
    @longitude = /.*<longitude>(?<long>.*)<\/longitude>.*/.match(line)[:long]
    end
    end
    @geo = Geo.create(:voivodeship => voivodeship, :district => "", :commune => "", :lat => @latitude, :long => @longitude)
    end
    outputFile.puts "voivodeship;#{@geo.voivodeship};\"\";\"\";#{voivodeship_hash[ "raz" ]};#{@geo.lat};#{@geo.long}"
    end
    
  end
end

puts "Zabytki"

Monument.all(:touched => 1).each do |monument|
  if "monument;#{monument.name};#{monument.lat};#{monument.long}" != "monument;;;"
    outputFile.puts "monument;#{monument.name};#{monument.lat};#{monument.long}"
  end
end

puts "Czyszczenie"
`rm koordynaty`
`rm relics_history*`
`mv output_temp.csv output.csv`

puts "Koniec"