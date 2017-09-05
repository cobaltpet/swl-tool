#!/usr/local/bin/ruby -w

# _ScheduleParser.rb -- ScheduleParser class for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

class ScheduleParser
    def broadcastEntryRecordsFromFile(filePath)
        puts "*** #{self.class.name} must be subclassed and #{__method__.to_s} must be overridden"
    end
end
