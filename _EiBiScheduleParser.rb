#!/usr/local/bin/ruby -w

# _EiBiScheduleParser.rb -- EiBiScheduleParser class for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

require_relative '_BroadcastEntry'
require_relative '_ScheduleParser'

# Note that a06 is the oldest csv available
# Note that b15 is currently the newest csv in the /archive path

class EiBiScheduleParser < ScheduleParser
    ### Initialize

    def initialize
        @parserLine = 0
        # source for language codes and definitions: http://eibispace.de/dx/README.TXT
        # this hash table is incomplete; filled in with most frequently occuring languages from A17 and other languages as noticed
        @languages = {"A"   => "Arabic", 
                      "AB"  => "Abkhaz",
                      "AD"  => "Adygea / Adyghe / Circassian",
                      "AF"  => "Afrikaans",
                      "AFA" => "Afar",
                      "AFG" => "Pashto / Dari",
                      "AH"  => "Amharic", 
                      "AL"  => "Albanian",
                      "AM"  => "Amoy",
                      "AMD" => "Tibetan Amdo",
                      "Ang" => "Angelus programme",
                      "AR"  => "Armenian",
                      "ASS" => "Assamese",
                      "AV"  => "Avar",
                      "AY"  => "Aymara",
                      "AZ"  => "Azeri / Azerbaijani",
                      "BC"  => "Baluchi",
                      "BE"  => "Bengali / Bangla", 
                      "BEM" => "Bemba",
                      "BH"  => "Bhili",
                      "BJ"  => "Bhojpuri / Bihari",
                      "BM"  => "Bambara / Bamanankan",
                      "BON" => "Bondo",
                      "BOS" => "Bosnian",
                      "BR"  => "Burmese",
                      "BSL" => "Bislama",
                      "BU"  => "Bulgarian",
                      "BUN" => "Bundeli / Bundelkhandi / Bundelkandi",
                      "BUR" => "Buryat",
                      "BY"  => "Byelorussian / Belarusian",
                      "C"   => "Chinese", 
                      "C-F" => "Chin-Falam / Halam",
                      "C-H" => "Chin-Haka",
                      "C-Z" => "Chin-Zomin / Zomi-Chin",
                      "CA"  => "Cantonese", 
                      "CC"  => "Chaochow (dialect of Min-Nan)",
                      "CD"  => "Chowdary / Chaudhry / Chodri",
                      "CH"  => "Chin",
                      "CHE" => "Chechen",
                      "CHG" => "Chhattisgarhi",
                      "CKW" => "Chokwe",
                      "CR"  => "Creole / Haitian",
                      "CZ"  => "Czech",
                      "D"   => "German", 
                      "D-P" => "Lower German",
                      "DA"  => "Danish", 
                      "DAO" => "Dao",
                      "DI"  => "Dinka",
                      "DO"  => "Dogri-Kangri",
                      "DR"  => "Dari / Eastern Farsi",
                      "DY"  => "Dyula / Jula",
                      "DZ"  => "Dzongkha",
                      "E"   => "English", 
                      "EGY" => "Egyptian Arabic",
                      "EO"  => "Esperanto",
                      "F"   => "French", 
                      "FI"  => "Finnish", 
                      "FS"  => "Farsi", 
                      "FT"  => "Fiote / Vili",
                      "FU"  => "Fulani / Fulfulde",
                      "GA"  => "Garhwali",
                      "GE"  => "Georgian",
                      "GM"  => "Gamit",
                      "GR"  => "Greek", 
                      "GU"  => "Gujarati",
                      "HA"  => "Haussa", 
                      "HAD" => "Hadiya",
                      "HAS" => "Hassinya / Hassaniya",
                      "HB"  => "Hebrew", 
                      "HI"  => "Hindi", 
                      "HK"  => "Hakka",
                      "HM"  => "Hmong / Miao languages",
                      "HMA" => "Hmar",
                      "HR"  => "Croatian / Hrvatski",
                      "HU"  => "Hungarian",
                      "I"   => "Italian", 
                      "IB"  => "Iban",
                      "IN"  => "Indonesian", 
                      "INU" => "Inuktikut",
                      "IS"  => "Icelandic",
                      "J"   => "Japanese", 
                      "JV"  => "Javanese",
                      "K"   => "Korean", 
                      "KA"  => "Karen",
                      "KAN" => "Kannada",
                      "KAO" => "Kaonde",
                      "KBO" => "Kok Borok / Tripuri",
                      "KC"  => "Kachin / Jingpho",
                      "KG"  => "Kyrgyz / Kirghiz",
                      "KH"  => "Khmer",
                      "KHA" => "Kham / Khams",
                      "KHM" => "Khmu",
                      "KHR" => "Kharia / Khariya",
                      "KHS" => "Khasi / Kahasi",
                      "KHT" => "Khota",
                      "KK"  => "KiKongo / Kongo",
                      "KMB" => "Kimbundu / Mbundu / Luanda",
                      "KNK" => "KinyaRwanda-KiRundi",
                      "KNU" => "Kanuri",
                      "KRB" => "Karbi / Mikir / Manchati",
                      "KRW" => "KinyaRwanda",
                      "KS"  => "Kashmiri",
                      "KU"  => "Kurdish",
                      "KUN" => "Kunama",
                      "KUR" => "Kurukh / Kurux",
                      "KZ"  => "Kazakh", 
                      "L"   => "Latin", 
                      "LAD" => "Ladakhi / Ladak",
                      "LAH" => "Lahu",
                      "LAO" => "Lao",
                      "LOZ" => "Lozi / Silozi",
                      "LU"  => "Lunda",
                      "LUG" => "Luganda",
                      "LUN" => "Lunyaneka / Nyaneka",
                      "LUV" => "Luvale",
                      "M"   => "Mandarin", 
                      "MAG" => "Maghi / Magahi / Maghai",
                      "MAI" => "Maithili / Maithali",
                      "MAL" => "Malayalam",
                      "MAO" => "Maori", 
                      "MAR" => "Marathi",
                      "MEI" => "Meithei / Manipuri / Meitei",
                      "MIE" => "Mien / Iu Mien",
                      "MIS" => "Mising",
                      "ML"  => "Malay / Baku",
                      "MO"  => "Mongolian", 
                      "MON" => "Mon",
                      "MSY" => "Malagasy",
                      "MUN" => "Mundari",
                      "MW"  => "Marwari",
                      "MY"  => "Maya (Yucatec)",
                      "MZ"  => "Mizo / Lushai",
                      "NDE" => "Ndebele",
                      "NE"  => "Nepali / Lhotshampa", 
                      "NIU" => "Niuean",
                      "NL"  => "Dutch",
                      "NO"  => "Norwegian",
                      "NU"  => "Nuer",
                      "NW"  => "Newar / Newari",
                      "NY"  => "Nyanja",
                      "OO"  => "Oromo",
                      "OR"  => "Odia / Oriya / Orissa",
                      "P"   => "Portuguese", 
                      "PO"  => "Polish",
                      "PJ"  => "Punjabi",
                      "PS"  => "Pashto", 
                      "Q"   => "Quechua", 
                      "R"   => "Russian", 
                      "RO"  => "Romanian", 
                      "ROS" => "Rosary",
                      "Ros" => "Rosary",
                      "RWG" => "Rawang",
                      "S"   => "Spanish", 
                      "SD"  => "Sindhi",
                      "SGA" => "Shangaan / Tsonga",
                      "SHA" => "Shan",
                      "SHC" => "Sharchogpa / Sarchopa / Tshangla",
                      "SHO" => "Shona",
                      "SHP" => "Sherpa",
                      "SI"  => "Sinhalese / Sinhala",
                      "SK"  => "Slovak",
                      "SLM" => "Pijin / Solomon Islands Pidgin",
                      "SM"  => "Samoan",
                      "SO"  => "Somali", 
                      "SNK" => "Sanskrit",
                      "SNT" => "Santhali",
                      "SR"  => "Serbian",
                      "SUD" => "Sudanese Arabic",
                      "SUN" => "Sunda / Sundanese",
                      "SWA" => "Swahili / Kisuaheli", 
                      "SWE" => "Swedish",
                      "T"   => "Thai", 
                      "TAG" => "Tagalog",
                      "TAH" => "Tachelhit / Sous",
                      "TAM" => "Tamil",
                      "TB"  => "Tibetan", 
                      "TEL" => "Telugu",
                      "TIG" => "Tigrinya / Tigray", 
                      "TJ"  => "Tajik",
                      "TK"  => "Turkmen",
                      "TL"  => "Tai-Lu / Lu",
                      "TNG" => "Tonga",
                      "TO"  => "Tongan",
                      "TP"  => "Tok Pisin", 
                      "TSH" => "Tshwa",
                      "TT"  => "Tatar",
                      "TTB" => "Tatar-Bashkir",
                      "TU"  => "Turkish",
                      "TV"  => "Tuva / Tuvinic",
                      "TW"  => "Taiwanese / Fujian / Hokkien / Min Nan",
                      "UI"  => "Uighur", 
                      "UK"  => "Ukrainian",
                      "UM"  => "Umbundu",
                      "UR"  => "Urdu", 
                      "UZ"  => "Uzbek",
                      "VN"  => "Vietnamese", 
                      "Vn"  => "Vernacular",
                      "VV"  => "Vasavi",
                      "W"   => "Wolof", 
                      "WAO" => "Waodani / Waorani",
                      "YK"  => "Yakutian / Sakha",
                      "YO"  => "Yoruba",
                      "Z"   => "Zulu",
                      "ZA"  => "Zarma / Zama",
                      "ZWE" => "Languages of Zimbabwe",
                      "-CW" => "Morse", 
                      "-MX" => "Music", 
                      "-TS" => "Time station"}
    end

    ### Superclass overrides

    def broadcastEntryRecordsForScheduleCode(scheduleCode)
        scheduleCodeYear = scheduleCode[1,2].to_i
        log(ErrorLabel, "Schedule code #{scheduleCodes[0]} is less than the minimum a06 available in EiBi CSV") if scheduleCodeYear < 6

        scheduleCodes = nil
        # first check if the user is overriding the automatic schedule fetch with a specific schedule code
        if $options.keys.include?(ScheduleOptionKey)
            scheduleCodes = [$options[ScheduleOptionKey]]
            # Note that a06 is the earliest eibi csv available
            scheduleCodeYear = scheduleCodes[0][1,2].to_i
            if scheduleCodeYear < 6
                log(ErrorLabel, "Schedule code #{scheduleCodes[0]} is less than the minimum: a06")
            end
        else
            # otherwise use the current and previous schedule codes
            scheduleCodes = [currentScheduleCode(), previousScheduleCode()]
        end

        available = false
        records = Array.new

        for attempt in 0..(scheduleCodes.length - 1)
            scheduleCode = scheduleCodes[attempt]
            log(DebugLabel, "checking schedule #{scheduleCode}")
            success = true
            # check if we have a fresh copy. if not, fetch
            if isEiBiFetchNeeded(scheduleCode)
                success = fetchEiBiSchedule(scheduleCode)
                unless success
                    log(DebugLabel, "http fetch error")
                end
            end
            if success
                available = true
                break
            end
        end
        records = parseEiBiSchedule(scheduleCode) if available
        return records
    end

    ### Internal


    def languagesFromString(string)
        langs = []
        codes = string.split(',')
        for code in codes
            language = @languages["#{code}"]
            if language != nil
                langs.push(language)
            else
                langs.push(code)
                log(DebugLabel, "Unrecognized language code: #{code}")
            end
        end
        # build a return string from the array that we have
        ls = ""
        for l in langs
            ls << l << ","
        end
        return ls.chop
    end

=begin
Example values to parse:
Sa
SaSu
Mo,Th
Mo-Fr
2356

Examples that won't currently be parsed:
irr
+-50
1.Sa
Ram
24Dec
Xmas
sum
A17
tent
25th
Haj
win
alt
HBF
=end
    # Generate a 7-char string to display day-of-week info alongside a broadcast entry
    # In both the EiBi data and the 'days' array, 1 = Monday ... 7 = Sunday
    # current output of "......." with -ta: 12095 - 10752 - 10481 - 10352 - 9620

    def markDay(day, days)
        case day
        when 1, "Mo"
            days[1] = "M"
        when 2, "Tu"
            days[2] = "T"
        when 3, "We"
            days[3] = "W"
        when 4, "Th"
            days[4] = "T"
        when 5, "Fr"
            days[5] = "F"
        when 6, "Sa"
            days[6] = "S"
        when 7, "Su"
            days[0] = "S"
        end
    end

    # generate the days string for schedule display
    # BUG: this method enforces starting the week on Sunday
    # BUG: this is a large method that should be broken up
    def daysStringForRecord(bc)
        result = nil
        returnInput = false
        inactive = bc[:inactive]
        if inactive
            result = "inactiv"
        else
            result = "SMTWTFS"
            data = bc[:days]
            if (data != nil) && (data.length > 0)
                days = Array.new(7, ".") # note that this is a zero-based array but the data is one-based
                twoCharDays = "(Mo|Tu|We|Th|Fr|Sa|Su)"

                # search for hyphenated weekday range e.g. Mo-Fr
                if (/^#{twoCharDays}-#{twoCharDays}$/ =~ data) != nil
                    mark = false
                    first = data[0,2]
                    second = data[3,2]

                    daysArray = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    unless daysArray.include?(first) && daysArray.include?(second)
                        log(DebugLabel, "Error parsing hyphenated day range! #{data}")
                    else
                        # To ensure proper recording of all combinations of hypenated ranges, 
                        # first rotate the array until the first specified day is element 0
                        until daysArray[0].eql?(first)
                            # displaying full a17 schedule results in 1147 daysArray rotates
                            log(DebugDebugLabel, "daysArray rotate")
                            daysArray.rotate!
                        end
                        for d in daysArray
                            if first.eql?(d)
                                mark = true
                            elsif second.eql?(d)
                                mark = false
                            end
                            if mark || second.eql?(d)
                                markDay(d, days)
                            end 
                        end
                    end
                # search for comma-separated weekday list e.g. Mo,Th
                elsif (/^#{twoCharDays},#{twoCharDays}$/ =~ data) != nil
                    data.split(",").each do |day|
                        markDay(day, days)
                    end
                # search for two adjacent days e.g. "SaSu"
                elsif (/^#{twoCharDays}{2}$/ =~ data) != nil
                    first = data[0,2]
                    second = data[2,2]
                    markDay(first, days)
                    markDay(second, days)
                # search for a single day e.g. "Tu"
                elsif (/^#{twoCharDays}$/ =~ data) != nil
                    markDay(data, days)
                # search for day-of-week digit list e.g. 2356
                elsif (/^[1-7]+$/ =~ data) != nil
                    #log(DebugLabel, "chopping digits #{data}")
                    data.split("").each do |digit|
                        markDay(digit.to_i, days)
                    end
                elsif (/^+-.+$/ =~ data) != nil
                    returnInput = true
                else
                    returnInput = true
                    case data
                    # for now, don't interpret these known cases
                    when "Ram", "Haj", "HBF", "Xmas", "sum", "win", "alt", "irr", "tent", "plan", "Tests"
                        # BUG: this implementation results in data loss. original string could be displayed
                        days[0] = "*" # the indicator for an unparsed day value
                    else
                        log(DebugLabel, "Unparsed day string: #{data}")
                    end
                end
                result = days.join
            end # if data != nil && data.length > 0
        end # if inactive

        if returnInput
            result = bc[:days]
            result += "." while result.length < 7
        end
        return result
    end

    # This is for the CSV file
    def filenameForEiBiSchedule(scheduleCode)
        return "sked-#{scheduleCode}.csv"
    end

    # note that archived csv begins with B06
    def urlForEiBiSchedule(scheduleCode, useArchiveURL)
        url = nil
        filename = filenameForEiBiSchedule(scheduleCode)
        if useArchiveURL
            url = "http://www.eibispace.de/archive/" + filename
        else
            url = "http://www.eibispace.de/dx/" + filename
        end
        return url
    end

    def isEiBiFetchNeeded(scheduleCode)
        fetchNeeded = false
        # look for file locally
        # if missing, or if present and more than a week old, then fetch

        expectedFile = storagePath + filenameForEiBiSchedule(scheduleCode)
        if File.exist?(expectedFile)
            mtime = File::new(expectedFile).mtime
            if mtime < (Time::now - 60*60*24*7)
                log(InfoLabel, "EiBi schedule file too old; fetching")
                fetchNeeded = true
                # BUG: rename existing file to an archived copy with creation timestamp
            end
        else
            log(InfoLabel, "EiBi schedule file not found; fetching")
            fetchNeeded = true
        end
        return fetchNeeded
    end

    # Note that a06 is the earliest csv -- this is checked in the calling method
    # Note that b15 is currently the newest csv in the archive path
    def fetchEiBiSchedule(scheduleCode)
        # create an array of up to two EiBi urls to check: the /dx directory and the /archive directory
        eibiURLs = Array.new

        # always add the /archive url
        eibiURLs.push(urlForEiBiSchedule(scheduleCode, true))

        # if the scheduleCode is newer than b15, insert the /dx url at the beginning of the array
        scheduleCodeYear = scheduleCode[1,2].to_i
        if scheduleCodeYear >= 16
            eibiURLs.insert(0, urlForEiBiSchedule(scheduleCode, false))
        end

        success = nil
        for url in eibiURLs
            success = nil
            uri = URI(url)
            filename = filenameForEiBiSchedule(scheduleCode)
     
            log(InfoLabel, "Trying #{url} ...")
            response = Net::HTTP.get_response(uri)
            responseCode = response.code.to_i
            log(DebugLabel, "http response code for #{url} is #{responseCode}")

            case responseCode
            when 200..299
                success = true
                if response.class.body_permitted?
                    File.open(storagePath() + filename, "w") { |f|
                        f.write(response.body)
                        f.flush()
                    }
                    break
                else
                    log(ErrorLabel, "http response body not permitted? #{response}")
                end
            when 400..499
                success = false
            else
                log(DebugLabel, "Unhandled http response code #{responseCode}")
                success = false
            end
        end # for url in eibiURLs
        return success
    end

    def parseEiBiSchedule(scheduleCode)
        loaded = false
        records = Array.new
        schedulePath = storagePath() + filenameForEiBiSchedule(scheduleCode)
        if File.exist?(schedulePath)
            log(DebugLabel, "parsing #{schedulePath}")
            # open the file
            firstLineSkipped = false
            File.open(schedulePath, "rb:iso-8859-1").each_line do |line|
                if firstLineSkipped
                    # parse into BroadcastEntry elements
                    bce = parseEiBiTextLine(line.chomp)
                    records.push(bce) unless nil == bce
                else
                    firstLineSkipped = true
                end
            end
            # the file has been processed although this is no guarantee of valid schedule data
            loaded = true
        end
        unless loaded
            log(ErrorLabel, "Could not find an EiBi schedule in #{storagePath()}")
        else
            log(InfoLabel, "Loaded #{records.count} schedule entries")
        end
        return records
    end

# first two lines of an example EiBi csv file
=begin
kHz:75;Time(UTC):93;Days:59;ITU:49;Station:201;Lng:49;Target:62;Remarks:135;P:35;Start:60;Stop:60;
16.4;0000-2400;;NOR;JXN Marine Norway;;NEu;no;1;;
=end

    def parseEiBiTextLine(line)    
        @parserLine += 1
        log(DebugDebugLabel, "parser line #{@parserLine}")
        fields = line.split(';')
        save = true
        bc = BroadcastEntry::new

        frequency = fields[0].to_i
        if frequency < 1711 || frequency > 30000
            save = false
            log(DebugDebugLabel, "Disregarding entry for #{frequency} kHz")
        else
            bc[:frequency] = frequency
        end

        inactive = fields[8].eql?("8")
        bc[:inactive] = inactive
        if inactive
            log(DebugDebugLabel, "inactive: #{line}")
        end

        # hhmm-hhmm -- note that this block could be omitted for inactives
        bc[:startHour] = fields[1][0,2].to_i
        bc[:startMinute] = fields[1][2,2].to_i
        bc[:endHour] = fields[1][5,2].to_i
        bc[:endMinute] = fields[1][7,2].to_i

        unless inactive
            bc[:days] = fields[2]
            bc[:daysPrintable] = daysStringForRecord(bc)
        end

        bc[:origin] = fields[3]
        bc[:broadcaster] = fields[4]

        # parse languages
        languages = fields[5]
        bc[:languages] = languagesFromString(languages)

        bc[:targetRegion] = fields[6]
        # ignoring the EiBi "Remarks"/Transmitter field
        # ignoring the EiBi "Persistence" field
        # ignoring the start/stop date fields

        if save
            log(DebugDebugLabel, "bc = #{bc}")
        else
            bc = nil
        end
        return bc
    end
end # class
