#!/usr/local/bin/ruby -w

# test-EiBiScheduleParser.rb -- Test cases for EiBiScheduleParser class for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

require 'test/unit'
require 'securerandom'

require_relative '_EiBiScheduleParser'

class TestEiBiParser < Test::Unit::TestCase
    def setup 
        # disable debug logging
        $options[DebugOptionKey] = false
        $options[DebugDebugOptionKey] = false
    end

    ### Days

    def testMarkDay
        ep = EiBiScheduleParser.new

        days = Array.new(7, ".") # 0 = Sun, 1 = Mon...
        ep.markDay(2, days)
        assert_equal ".", days[1]
        assert_equal "T", days[2]
        assert_equal ".", days[3]

        ep.markDay(5, days)
        assert_equal "T", days[2]
        assert_equal ".", days[4]
        assert_equal "F", days[5]
        assert_equal ".", days[6]

        ep.markDay("Mo", days)
        assert_equal ".", days[0]
        assert_equal "M", days[1]
        assert_equal "T", days[2]
        assert_equal ".", days[3]
    end
  
    def testDaysStringAlpha
        ep = EiBiScheduleParser.new
        bc = BroadcastEntry.new

        # :days is unset
        assert_equal "SMTWTFS", ep.daysStringForRecord(bc)

        bc[:days] = ""
        assert_equal "SMTWTFS", ep.daysStringForRecord(bc)
      
        bc[:days] = nil
        assert_equal "SMTWTFS", ep.daysStringForRecord(bc)

        bc[:days] = "We"
        assert_equal "...W...", ep.daysStringForRecord(bc)

        bc[:days] = "Sa"
        assert_equal "......S", ep.daysStringForRecord(bc)
    end

    def testDaysStringAlphaPair
        ep = EiBiScheduleParser.new
        bc = BroadcastEntry.new
  
        bc[:days] = "SaSu"
        #vladislav = 0
        #delay(vladislav)
        assert_equal "S.....S", ep.daysStringForRecord(bc)
    end

    def testDaysStringAlphaCommaDelimited
        ep = EiBiScheduleParser.new
        bc = BroadcastEntry.new

        bc[:days] = "Mo,Fr"
        assert_equal ".M...F.", ep.daysStringForRecord(bc)

        bc[:days] = "Tu,We"
        assert_equal "..TW...", ep.daysStringForRecord(bc)

        bc[:days] = "Tu,Fr"
        assert_equal "..T..F.", ep.daysStringForRecord(bc)

        bc[:days] = "We,Su"
        assert_equal "S..W...", ep.daysStringForRecord(bc)

        bc[:days] = "Fr,Su"
        assert_equal "S....F.", ep.daysStringForRecord(bc)
    end

    def testDaysStringAlphaRange
        ep = EiBiScheduleParser.new
        bc = BroadcastEntry.new
        # test ranges that traverse Sa-Su to force an array rotation

        bc[:days] = "Mo-Tu"
        assert_equal ".MT....", ep.daysStringForRecord(bc)

        bc[:days] = "Mo-Fr"
        assert_equal ".MTWTF.", ep.daysStringForRecord(bc)

        bc[:days] = "Th-Mo"
        assert_equal "SM..TFS", ep.daysStringForRecord(bc)

        bc[:days] = "Fr-We"
        assert_equal "SMTW.FS", ep.daysStringForRecord(bc)

        bc[:days] = "Sa-Su"
        assert_equal "S.....S", ep.daysStringForRecord(bc)

        bc[:days] = "Sa-Tu"
        assert_equal "SMT...S", ep.daysStringForRecord(bc)
    end

    def testDaysStringNumeric
        ep = EiBiScheduleParser.new
        bc = BroadcastEntry.new

        bc[:days] = "134"
        assert_equal ".M.WT..", ep.daysStringForRecord(bc)

        bc[:days] = "1356"
        assert_equal ".M.W.FS", ep.daysStringForRecord(bc)

        bc[:days] = "245"
        assert_equal "..T.TF.", ep.daysStringForRecord(bc)

        bc[:days] = "247"
        assert_equal "S.T.T..", ep.daysStringForRecord(bc)

        bc[:days] = "7"
        assert_equal "S......", ep.daysStringForRecord(bc)
    end

    def testDaysStringUnparsed
        ep = EiBiScheduleParser.new
        bc = BroadcastEntry.new

        bc[:days] = "irr"
        assert_equal "irr....", ep.daysStringForRecord(bc)

        bc[:days] = "Tests"
        assert_equal "Tests..", ep.daysStringForRecord(bc)
    end

    ### Languages

    ### Filename / URL

    def testFilename
        ep = EiBiScheduleParser.new

        assert_equal "sked-b06.csv", ep.filenameForEiBiSchedule("b06")
        assert_equal "sked-a17.csv", ep.filenameForEiBiSchedule("a17")
        assert_equal "sked-b18.csv", ep.filenameForEiBiSchedule("b18")
    end

    def testURL
        ep = EiBiScheduleParser.new

        assert_equal "http://www.eibispace.de/archive/sked-b06.csv", ep.urlForEiBiSchedule("b06", true)
        assert_equal "http://www.eibispace.de/archive/sked-b12.csv", ep.urlForEiBiSchedule("b12", true)
        assert_equal "http://www.eibispace.de/dx/sked-a16.csv", ep.urlForEiBiSchedule("a16", false)
        assert_equal "http://www.eibispace.de/dx/sked-a17.csv", ep.urlForEiBiSchedule("a17", false)
    end

    ### AppendFlag

    def testAppendFlag
        ep = EiBiScheduleParser.new
        bc = BroadcastEntry.new

        # a
        ep.appendFlag(bc, BroadcastFlagAnalog)

        # t
        ep.appendFlag(bc, BroadcastFlagTime)
        assert bc[:flags].include?(BroadcastFlagAnalog)
        assert bc[:flags].include?(BroadcastFlagTime)

        # a again
        ep.appendFlag(bc, BroadcastFlagAnalog)
        assert bc[:flags].include?(BroadcastFlagAnalog)
        assert bc[:flags].include?(BroadcastFlagTime)

        # o
        ep.appendFlag(bc, BroadcastFlagMorse)
        assert bc[:flags].include?(BroadcastFlagMorse)
    end

    ### Parse line

=begin
2017-09-06 : http://eibispace.de/dx/README.TXT

Format of the CSV database (sked-):
The entries are separated by semicolons (;), so each line has to contain ten semicolons - not more, not less.
Entry #1 (float between 10 and 30000): Frequency in kHz
Entry #2 (9-character string): Start and end time, UTC, as two '(I04)' numbers separated by a '-'
Entry #3 (string of up to 5 characters): Days of operation, or some special comments:
         Mo,Tu,We,Th,Fr,Sa,Su - Days of the week
         1245 - Days of the week, 1=Monday etc. (this example is "Monday, Tuesday, Thursday, Friday")
         Note: Vatican Radio counts major Catholic holidays as "Sunday"
         irr - Irregular operation
         alt - Alternative frequency, not usually in use
         Ram - Ramadan special schedule
         Haj - Special broadcast for the Haj
         15Sep - Broadcast only on 15 September
         tent - Tentatively, please check and report your observations
         HBF - Hornbill Festival, Nagaland, India - first week of December
Entry #4 (string up to 3 characters): ITU code (see below) of the station's home country
Entry #5 (string up to 23 characters): Station name
Entry #6 (string up to 3 characters): Language code
Entry #7 (string up to 3 characters): Target-area code
Entry #8 (string): Transmitter-site code
Entry #9 (integer): Persistence code, where:
         1 = This broadcast is everlasting (i.e., it will be copied into next season's file automatically)
         2 = As 1, but with a DST shift (northern hemisphere)
         3 = As 1, but with a DST shift (southern hemisphere)
         4 = As 1, but active only in the winter season
         5 = As 1, but active only in the summer season
         6 = Valid only for part of this season; dates given in entries #10 and #11. Useful to re-check old logs.
         8 = Inactive entry, not copied into the bc and freq files.
Entry #10: Start date if entry #9=6. 0401 = 4th January. Sometimes used with #9=1 if a new permanent service is started, for information purposes only.
Entry #11: As 10, but end date. Additionally, the date of the most recent log can be noted in [brackets]. [0212]=Last heard in February 2012.
=end

    def testParseLine
        ep = EiBiScheduleParser.new

        line = "7490;2300-0455;;;WBCQ;E;NA;;;;"
        bc = ep.parseEiBiTextLine(line)
        assert_equal 7490, bc[:frequency]
        assert_equal "WBCQ", bc[:broadcaster]
        assert_equal 23, bc[:startHour]
        assert_equal 0, bc[:startMinute]
        assert_equal 4, bc[:endHour]
        assert_equal 55, bc[:endMinute]
        assert_equal "NA", bc[:targetRegion]
    end

    def testParseLineInactive
        ep = EiBiScheduleParser.new

        line = "5025;0400-0700;;;Something;S;SA;;8;;"
        bc = ep.parseEiBiTextLine(line)
        assert bc[:inactive]
    end

    def testParseLineIgnoreInvalidFrequency
        ep = EiBiScheduleParser.new

        line = "1710;0400-0530;;;CRI;C;As;;;;"
        bc = ep.parseEiBiTextLine(line)
        assert nil == bc
        
        line = "30001;0400-0530;;;CRI;C;As;;;;"
        bc = ep.parseEiBiTextLine(line)
        assert nil == bc
    end

    def testParseLineIgnoreInvalidFieldCount
        ep = EiBiScheduleParser.new

        line = "5850;0100-0200;;;BBC;E;Eu;;;" # 9 semicolons
        bc = ep.parseEiBiTextLine(line)
        assert nil == bc

        line = "5850;0100-0200;;;BBC;E;Eu;;;;;" # 11 semicolons
        bc = ep.parseEiBiTextLine(line)
        assert nil == bc
    end

    def testIsEiBiFetchNeeded
        ep = EiBiScheduleParser.new

        filesToRemove = Array.new
        ep.localFilePath = "/tmp/unittest-#{SecureRandom.uuid()}/"
        assert false == Dir.exist?(ep.localFilePath)
        createDirectoryIfNeeded(ep.localFilePath)

        # the directory is empty
        sc = "a17"
        assert ep.isEiBiFetchNeeded(sc)
        fakeA17File = ep.localFilePath + ep.filenameForEiBiSchedule(sc)
        filesToRemove.push(fakeA17File)
        File.open(fakeA17File, "w") { }
        assert false == ep.isEiBiFetchNeeded(sc)

        sc = "b16"
        assert ep.isEiBiFetchNeeded(sc)

        filesToRemove.each { |file| File.unlink(file) }
        Dir.rmdir(ep.localFilePath)
    end
end
