#!/usr/local/bin/ruby -w

# test-Languages.rb -- Test cases for Language lookup and filtering methods for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

require 'test/unit'

require_relative '_Common'
require_relative '_Languages'

class TestLanguages < Test::Unit::TestCase
    def setup 
        # disable debug logging
        $options[DebugOptionKey] = false
        $options[DebugDebugOptionKey] = false
    end

    ### all expected keys

    # The four EiBi language codes starting with a hyphen, -CW -MX -TS -TY are not treated as languages by this script and are excluded
    def testEiBiLanguageCodeKeys
        expectedKeys = ["A", "AB", "AC", "ACH", "AD", "ADI", "AF", "AFA", "AFG", "AH", "AJ", "AK", "AL", "ALG", "AM", "AMD", "Ang", "AR", "ARO", "ARU", "ASS", "ASY", "ATS", "Aud", "AV", "AW", "AY", "AZ", "BAD", "BAG", "BAI", "BAJ", "BAL", "BAN", "BAO", "BAR", "BAS", "BAY", "BB", "BC", "BE", "BED", "BEM", "BGL", "BH", "BHN", "BHT", "BI", "BID", "BIS", "BJ", "BK", "BLK", "BLT", "BM", "BNA", "BNG", "BNI", "BNJ", "BNT", "BON", "BOR", "BOS", "BR", "BRA", "BRB", "BRU", "BSL", "BT", "BTK", "BU", "BUG", "BUK", "BUN", "BUR", "BY", "C", "CA", "CC", "CD", "CEB", "CH", "C-A", "C-D", "C-F", "C-H", "CHA", "CHE", "CHG", "CHI", "C-K", "C-M", "C-O", "CHR", "CHU", "C-T", "C-Z", "CKM", "CKW", "COF", "COK", "CR", "CRU", "CT", "CV", "CW", "CZ", "D", "D-P", "DA", "DAH", "DAO", "DAR", "DD", "DEC", "DEG", "DEN", "DEO", "DES", "DH", "DI", "DIM", "DIT", "DO", "DR", "DU", "DUN", "DY", "DZ", "E", "EC", "EGY", "EO", "ES", "EWE", "F", "FA", "FI", "FJ", "FON", "FP", "FS", "FT", "FU", "FUJ", "", "FUR", "GA", "GAG", "GAR", "GD", "GE", "GI", "GJ", "GL", "GM", "GNG", "GO", "GON", "GR", "GU", "GUA", "GUR", "GZ", "HA", "HAD", "HAR", "HAS", "HB", "HD", "HI", "HK", "", "HM", "HMA", "HMB", "HMQ", "HMW", "HN", "HO", "HR", "HRE", "HU", "HUI", "HZ", "I", "IB", "IF", "IG", "ILC", "ILG", "IN", "INU", "IRQ", "IS", "ISA", "J", "JEH", "JG", "JOR", "JR", "JU", "JV", "K", "KA", "K-G", "K-K", "K-P", "K-S", "K-W", "KAD", "KAL", "KAB", "KAM", "KAN", "KAO", "KAR", "KAT", "KAU", "KAY", "KB", "KBO", "KC", "KG", "KH", "KHA", "KHM", "KHR", "KHS", "KHT", "KIM", "KIN", "KiR", "KK", "KKN", "KMB", "KMY", "KND", "KNK", "KNU", "KNY", "KOH", "KOK", "KOM", "KON", "KOR", "KOT", "KOY", "KPK", "KRB", "KRI", "KRW", "KS", "KT", "KTW", "KU", "KuA", "KuF", "KUI", "KUL", "KUM", "KUN", "KUP", "KUR", "KUs", "KUT", "KUV", "KVI", "KWA", "KYH", "KZ", "L", "LA", "LAD", "LAH", "LAK", "LAM", "LAO", "LB", "LBN", "LBO", "LEP", "LEZ", "LIM", "LIN", "LIS", "LND", "LNG", "LO", "LOK", "LOZ", "LT", "LTO", "LU", "LUB", "LUC", "LUG", "LUN", "LUR", "LUV", "LV", "M", "MA", "MAD", "MAG", "MAI", "MAK", "MAL", "MAM", "MAO", "MAR", "MAS", "MC", "MCH", "MEI", "MEN", "MEW", "MGA", "MIE", "MIS", "MKB", "MKS", "MKU", "ML", "MLK", "MLT", "MNA", "MNE", "MNO", "MO", "MON", "MOO", "MOR", "MR", "MRC", "MRI", "MRU", "MSY", "MUN", "MUO", "MUR", "MV", "MW", "MX", "MY", "MZ", "NAG", "NAP", "NDA", "NDE", "NE", "NG", "NGA", "NIC", "NIS", "NIU", "NL", "NLA", "NO", "NOC", "NP", "NTK", "NU", "NUN", "NW", "NY", "OG", "OH", "OO", "OR", "OS", "OW", "P", "PAL", "PAS", "PED", "PJ", "PO", "POR", "POT", "PS", "PU", "Q", "QQ", "R", "RAD", "REN", "RGM", "RO", "ROG", "RON", "Ros", "RU", "RWG", "S", "SAH", "SAN", "SAR", "SAS", "SC", "SCA", "SD", "SED", "SEF", "SEN", "SFO", "SGA", "SGM", "SGO", "SGT", "SHA", "SHk", "SHC", "SHE", "SHK", "SHO", "SHP", "SHU", "SI", "SID", "SIK", "SIR", "SK", "SLM", "SLT", "SM", "SMP", "SNK", "SNT", "SO", "SON", "SOT", "SR", "SRA", "STI", "SUA", "SUD", "SUM", "SUN", "SV", "SWA", "SWE", "SWZ", "T", "TAG", "TAH", "TAL", "TAM", "TB", "TBS", "TEL", "TEM", "TFT", "TGK", "TGR", "TGS", "THA", "TIG", "TJ", "TK", "TL", "TM", "TMG", "TMJ", "TN", "TNG", "TO", "TOK", "TOR", "TP", "TS", "TSA", "TSH", "TT", "TTB", "TU", "TUL", "TUM", "TUN", "TV", "TW", "TWI", "TWT", "TZ", "UD", "UI", "UK", "UM", "UR", "UZ", "V", "VAD", "VAR", "Ves", "Vn", "VN", "VV", "VX", "W", "WA", "WAO", "WE", "WT", "WU", "XH", "YAO", "YER", "YI", "YK", "YO", "YOL", "YUN", "YZ", "Z", "ZA", "ZD", "ZG", "ZH", "ZWE"]
        expectedKeys.each do |key|
            result = $eibiLanguageCodeToISO639dash3.keys.include?(key)
            puts "*** Key failed: #{key}" unless result
            assert result
        end
    end

    def testISO639dash3LanguageCodeKeys
    end

    ### English

    def testEnglishEiBiToISO639dash3
        assert $eibiLanguageCodeToISO639dash3["E"].eql?("eng")
    end

    def testEnglishISO639dash3ToHumanReadableEnglish
        assert  $iso639dash3LanguageCodeToEnglishName["eng"].eql?("English")
    end
end
