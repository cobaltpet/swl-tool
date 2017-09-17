#!/usr/local/bin/ruby -w

# test-Filter.rb -- Test cases for schedule filtering methods for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

require 'test/unit'

require_relative '_Filter'
require_relative '_BroadcastEntry'

class TestFilter < Test::Unit::TestCase
    def setup 
        # disable debug logging
        $options[DebugOptionKey] = false
        $options[DebugDebugOptionKey] = false
    end

    ### Meter bands

    def assertMeterBandFrequencies(mb, mbLow, mbHigh)
        # test frequencies at the edges of the band
        assert false == doesFrequencyMatchMeterBand(mbLow - 1, mb, 0)
        assert doesFrequencyMatchMeterBand(mbLow, mb, 0)
        assert doesFrequencyMatchMeterBand(mbHigh, mb, 0)
        assert false == doesFrequencyMatchMeterBand(mbHigh + 1, mb, 0)

        # test the midpoint of the band
        assert doesFrequencyMatchMeterBand((mbLow+mbHigh)/2, mb, 0)

        # test tolerances of 5 or 10 kHz
        assert false == doesFrequencyMatchMeterBand(mbLow - 10, mb, 5)
        assert doesFrequencyMatchMeterBand(mbLow - 5, mb, 10)
        assert doesFrequencyMatchMeterBand(mbHigh + 5, mb, 10)
        assert false == doesFrequencyMatchMeterBand(mbHigh + 10, mb, 5)

        # test tolerance boundaries
        tolerance = 20
        assert false == doesFrequencyMatchMeterBand(mbLow - tolerance - 1, mb, tolerance)
        assert doesFrequencyMatchMeterBand(mbLow - tolerance, mb, tolerance)
        assert doesFrequencyMatchMeterBand(mbHigh + tolerance, mb, tolerance)
        assert false == doesFrequencyMatchMeterBand(mbHigh + tolerance + 1, mb, tolerance)
    end

    def testMeterBands
        assertMeterBandFrequencies(120,  2300,  2495)
        assertMeterBandFrequencies( 90,  3200,  3400)
        assertMeterBandFrequencies( 75,  3900,  4000)
        assertMeterBandFrequencies( 60,  4750,  5060)
        assertMeterBandFrequencies( 49,  5800,  6200)
        assertMeterBandFrequencies( 41,  7200,  7450)
        assertMeterBandFrequencies( 31,  9400,  9900)
        assertMeterBandFrequencies( 25, 11600, 12100)
        assertMeterBandFrequencies( 22, 13570, 13870)
        assertMeterBandFrequencies( 19, 15100, 15830)
        assertMeterBandFrequencies( 16, 17480, 17900)
        assertMeterBandFrequencies( 15, 18900, 19020)
        assertMeterBandFrequencies( 13, 21450, 21850)
        assertMeterBandFrequencies( 11, 25600, 26100)
    end

    def testMeterBandsTrueIfNil
        assert doesFrequencyMatchMeterBand(8400, nil, 0)
    end

    def testMeterBandsWrongBand
        assert false == doesFrequencyMatchMeterBand(3300, 120, 0)
        assert false == doesFrequencyMatchMeterBand(5900, 60, 0)
        assert false == doesFrequencyMatchMeterBand(7300, 49, 0)
        assert false == doesFrequencyMatchMeterBand(11950, 31, 0)
        assert false == doesFrequencyMatchMeterBand(15240, 25, 0)
    end

    def testInvalidMeterBand
        assert false == doesFrequencyMatchMeterBand(3700, 80, 0)
        assert false == doesFrequencyMatchMeterBand(6950, 43, 0)
        assert false == doesFrequencyMatchMeterBand(7100, 40, 0)
        assert false == doesFrequencyMatchMeterBand(14100, 20, 0)
        assert false == doesFrequencyMatchMeterBand(18100, 17, 0)
    end

    ### Broadcaster

    def testBroadcasterFilter
        bc = BroadcastEntry.new
        bc[:broadcaster] = "Radio Havana Cuba"

        assert doesBroadcastMatchBroadcasterFilter(bc, "Radio")
        assert doesBroadcastMatchBroadcasterFilter(bc, "Havana")
        assert doesBroadcastMatchBroadcasterFilter(bc, "Cuba")
        assert false == doesBroadcastMatchBroadcasterFilter(bc, "China")
        assert false == doesBroadcastMatchBroadcasterFilter(bc, "Voice of")
        assert false == doesBroadcastMatchBroadcasterFilter(bc, "WBCQ")
    end

    def testBroadcasterFilterTrueIfNil
        bc = BroadcastEntry.new
        bc[:broadcaster] = "WWV"

        assert doesBroadcastMatchBroadcasterFilter(bc, nil)
    end

    ### Flags

    def testBroadcastFlagsFilter
        bc = BroadcastEntry.new

        assert false == doesBroadcastMatchBroadcastFlagsFilter(bc, BroadcastFlagNews)

        bc[:flags] = BroadcastFlagReligious
        assert doesBroadcastMatchBroadcastFlagsFilter(bc, BroadcastFlagReligious)
        assert false == doesBroadcastMatchBroadcastFlagsFilter(bc, BroadcastFlagNumbers)
    end

    def testBroadcastFlagsFilterTrueIfNil
        bc = BroadcastEntry.new
 
        assert doesBroadcastMatchBroadcastFlagsFilter(bc, nil)
        
        bc[:flags] = BroadcastFlagVolmet
        assert doesBroadcastMatchBroadcastFlagsFilter(bc, nil)
    end

    def testBroadcastFlagsFilterFalseIfUnset
        bc = BroadcastEntry.new

        assert false == doesBroadcastMatchBroadcastFlagsFilter(bc, BroadcastFlagAnalog)
        assert false == doesBroadcastMatchBroadcastFlagsFilter(bc, BroadcastFlagDigital)
    end

    ### Frequency

    def testBroadcastFrequencyFilter
        bc = BroadcastEntry.new
        freq = 6080
        bc[:frequency] = freq

        assert false == doesBroadcastMatchFrequencyFilter(bc, freq - 1, 0)
        assert doesBroadcastMatchFrequencyFilter(bc, freq, 0)
        assert false == doesBroadcastMatchFrequencyFilter(bc, freq + 1, 0)
    end

    def testBroadcastFrequencyFilterWithTolerance
        bc = BroadcastEntry.new
        freq = 6080
        tolerance = 25
        bc[:frequency] = freq

        # below
        assert false == doesBroadcastMatchFrequencyFilter(bc, freq - tolerance - 1, tolerance)
        assert doesBroadcastMatchFrequencyFilter(bc, freq - tolerance, tolerance)
        assert doesBroadcastMatchFrequencyFilter(bc, freq - tolerance + 1, tolerance)

        # at
        assert doesBroadcastMatchFrequencyFilter(bc, freq, tolerance)

        # above
        assert doesBroadcastMatchFrequencyFilter(bc, freq + tolerance - 1, tolerance)
        assert doesBroadcastMatchFrequencyFilter(bc, freq + tolerance, tolerance)
        assert false == doesBroadcastMatchFrequencyFilter(bc, freq + tolerance + 1, tolerance)
    end

    def testBroadcastFrequencyFilterTrueIfNil
        bc = BroadcastEntry.new
        freq = 15240
        bc[:frequency] = freq

        assert doesBroadcastMatchFrequencyFilter(bc, freq, nil)
        assert doesBroadcastMatchFrequencyFilter(bc, nil, nil)
    end

    def testBroadcastFrequencyFilterFalseIfUnset
        bc = BroadcastEntry.new

        assert false == doesBroadcastMatchFrequencyFilter(bc, 5900, nil)
        assert false == doesBroadcastMatchFrequencyFilter(bc, 9490, nil)
        assert false == doesBroadcastMatchFrequencyFilter(bc, 15160, nil)
    end

    ### Language
    # note: language filtering currently fails and is planned for milestone 0.2

    ### Region
    # note: region filter implementation may change significantly in the future

    ### Time

    def testBroadcastTimeFilter
        bc = BroadcastEntry.new

        sh = 13
        sm = 55
        eh = 17
        em = 10
        bc[:startHour] = sh
        bc[:startMinute] = sm
        bc[:endHour] = eh
        bc[:endMinute] = em

        # implicit tolerance is 30 minutes
        tolerance = 30
 
        assert false == doesBroadcastMatchTimeFilter(bc, sh - 1, sm)
        assert false == doesBroadcastMatchTimeFilter(bc, sh, sm - tolerance - 1)

        assert doesBroadcastMatchTimeFilter(bc, sh, sm - tolerance)
        assert doesBroadcastMatchTimeFilter(bc, sh, sm)
        assert doesBroadcastMatchTimeFilter(bc, eh, em)
        assert doesBroadcastMatchTimeFilter(bc, eh, em + tolerance)
      
        assert false == doesBroadcastMatchTimeFilter(bc, eh, em + tolerance + 1)
        assert false == doesBroadcastMatchTimeFilter(bc, eh + 1, em)
    end

    def testBroadcastTimeFilterEndTimeIsEarlier
        bc = BroadcastEntry.new

        sh = 22
        sm = 30
        eh = 6
        em = 00
        bc[:startHour] = sh
        bc[:startMinute] = sm
        bc[:endHour] = eh
        bc[:endMinute] = em

        # implicit tolerance is 30 minutes
        tolerance = 30
 
        # before
        assert false == doesBroadcastMatchTimeFilter(bc, sh - 2, sm)
        assert false == doesBroadcastMatchTimeFilter(bc, sh - 1, sm)

        # at tolerances
        assert doesBroadcastMatchTimeFilter(bc, sh, sm - tolerance)
        assert doesBroadcastMatchTimeFilter(bc, eh, em + tolerance)

        # during
        assert doesBroadcastMatchTimeFilter(bc, sh + 1, sm)
        assert doesBroadcastMatchTimeFilter(bc, eh - 5, em)
        assert doesBroadcastMatchTimeFilter(bc, eh - 2, em)
        assert doesBroadcastMatchTimeFilter(bc, eh - 1, em)

        # after
        assert false == doesBroadcastMatchTimeFilter(bc, eh + 1, em)
        assert false == doesBroadcastMatchTimeFilter(bc, eh + 2, em)
    end

    def testBroadcastTimeFilterTrueIfNil
        bc = BroadcastEntry.new
        bc[:startHour] = 13
        bc[:startMinute] = 55
        bc[:endHour] = 17
        bc[:endMinute] = 10

        assert doesBroadcastMatchTimeFilter(bc,   5, nil)
        assert doesBroadcastMatchTimeFilter(bc, nil,   2)
        assert doesBroadcastMatchTimeFilter(bc,  13, nil)
        assert doesBroadcastMatchTimeFilter(bc, nil,  55)
        assert doesBroadcastMatchTimeFilter(bc, nil, nil)
        assert doesBroadcastMatchTimeFilter(bc,  17, nil)
        assert doesBroadcastMatchTimeFilter(bc, nil,  10)
        assert doesBroadcastMatchTimeFilter(bc,  23, nil)
        assert doesBroadcastMatchTimeFilter(bc, nil,  59)
    end

    ### Inactive

    def testInactiveFilter
        bc = BroadcastEntry.new

        # nil is treated as active
        assert doesBroadcastMatchInactiveFilter(bc, false)
        assert doesBroadcastMatchInactiveFilter(bc, true)

        bc[:inactive] = false
        assert doesBroadcastMatchInactiveFilter(bc, false)
        assert doesBroadcastMatchInactiveFilter(bc, true)

        bc[:inactive] = true
        assert false == doesBroadcastMatchInactiveFilter(bc, false)
        assert doesBroadcastMatchInactiveFilter(bc, true)
    end

end
