#!/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'data_mapper' # requires all the gems listed above

puts "Synchronizacja z bazą danych"
DataMapper::Logger.new($stdout, :debug)
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

DataMapper.finalize

DataMapper.auto_upgrade!

#"export_id","suggested_at","relic_id","nid_id","nid_kind","relic_ancestry","register_number","voivodeship","district","commune","place","place_id","place_id_action","identification","identification_action","street","street_action","dating","dating_action","latitude","longitude","coordinates_action","categories","categories_action"
#"rel_3402","2012-06-01 00:00:00","3402","593709","OZ","3400"," 863/J z 04.02.1985","dolnośląskie","lubański","Lubań","Jałowiec","18530","revision","Park (1. ogród przy pałacu, 2. ogród z mauzoleum, 3. aleja lipowa)","revision","","revision","","revision","51.0869991","15.3063884","revision","","revision"
#"rel_2479","2012-06-01 00:00:00","2479","592784","OZ","2478"," 1146/WŁ z 25.10.1985","dolnośląskie","kłodzki","Kudowa-Zdrój","Kudowa-Zdrój","95578","revision","Kościół par. p.w. św. Bartłomieja","revision","","revision","1384","revision","50.4427156","16.2426605","revision","","revision"

puts "Pobieranie najnowszej historii zmian"
`wget http://otwartezabytki.pl/system/relics_history.csv -a backend_wget_log`

rhFile = File.open("relics_history.csv", "r:UTF-8")

line = rhFile.readline

outputFile = File.open("output.csv", "w:UTF-8")

puts "Przetwarzanie historii zmian"
@relics = Hash.new
@relics[ "zabytkow" ] = 0
@relics[ "raz" ] = 0
@relics[ "dwa" ] = 0
@relics[ "trzy" ] = 0
@relics[ "czterywiecej" ] = 0
rhFile.each do |line|
  relic_change = line.slice(0, line.length-1).split(/","/)
   
  # relic_change[2] -> relic_id
  relic_id = relic_change[2]#.slice(1, relic_change[2].length-2)
  
  # relic_change[1] -> suggested_at (jeśli z rejestru to 2012-06-01 00:00:00)
  suggested_at = relic_change[1]#.slice(1, relic_change[1].length-2)
   
  # relic_change[7] -> voivodeship
  voivodeship = relic_change[7]#.slice(1, relic_change[7].length-2)
  if @relics[ voivodeship ] == nil
    @relics[ voivodeship ] = Hash.new
    @relics[ voivodeship ][ "zabytkow" ] = 0
    @relics[ voivodeship ][ "raz" ] = 0
    @relics[ voivodeship ][ "dwa" ] = 0
    @relics[ voivodeship ][ "trzy" ] = 0
    @relics[ voivodeship ][ "czterywiecej" ] = 0
  end
   
  # relic_change[8] -> district
  district = relic_change[8]#.slice(1, relic_change[8].length-2)
   
  if @relics[ voivodeship ][ district ] == nil
    @relics[ voivodeship ][ district ] = Hash.new
    @relics[ voivodeship ][ district ][ "zabytkow" ] = 0
    @relics[ voivodeship ][ district ][ "raz" ] = 0
    @relics[ voivodeship ][ district ][ "dwa" ] = 0
    @relics[ voivodeship ][ district ][ "trzy" ] = 0
    @relics[ voivodeship ][ district ][ "czterywiecej" ] = 0
  end
   
  # relic_change[9] -> commune
  commune = relic_change[9]#.slice(1, relic_change[9].length-2)
   
  if @relics[ voivodeship ][ district ][ commune ] == nil
    @relics[ voivodeship ][ district ][ commune ] = Hash.new
    @relics[ voivodeship ][ district ][ commune ][ "zabytkow" ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "raz" ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "dwa" ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "trzy" ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "czterywiecej" ] = 0
  end
  
#   puts "#{voivodeship} #{district} #{commune} #{suggested_at} #{relic_id}"
  
  if suggested_at == "2012-06-01 00:00:00" && @relics[ voivodeship ][ district ][ commune ][ relic_id ] == nil
    @relics[ voivodeship ][ district ][ commune ][ relic_id ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "zabytkow" ] += 1
    @relics[ voivodeship ][ district ][ "zabytkow" ] += 1
    @relics[ voivodeship ][ "zabytkow" ] += 1
    @relics[ "zabytkow" ] += 1
  elsif @relics[ voivodeship ][ district ][ commune ][ relic_id ] == nil
    puts "Prawdopodobnie coś nie tak"
    @relics[ voivodeship ][ district ][ commune ][ relic_id ] = 0
    @relics[ voivodeship ][ district ][ commune ][ "zabytkow" ] += 1
    @relics[ voivodeship ][ district ][ "zabytkow" ] += 1
    @relics[ voivodeship ][ "zabytkow" ] += 1
    @relics[ "zabytkow" ] += 1
  elsif
    @relics[ voivodeship ][ district ][ commune ][ relic_id ] += 1
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

puts "Czyszczenie"
# "rel_17962","2012-06-01 00:00:00","17962","608355","SA","",     " 2103, 2152 (?) z 4.05.1971; 253/79 z 27.04.1979","lubuskie","Gorzów Wielkopolski","Gorzów Wielkopolski","Gorzów Wielkopolski","90766","revision","Kościół ewangelicki ""Zgody"", ob. rzym.-kat. p.w. św. Stanisława","revision","","revision","1776","revision","52.7325285","15.2369305","revision","","revision"
# "sug_9122", "2012-07-21 21:56:50","52617","643326","OZ","52614"," 297/A z 27.05.1986",                             "świętokrzyskie","ostrowiecki","Ćmielów","Ruda Kościelna","76710","skip","Ogrodzenie parku","confirm","","skip","","skip","50.9458188","21.5509463","skip","inny","skip"
`rm koordynaty`
`rm relics_history*`

puts "Koniec"