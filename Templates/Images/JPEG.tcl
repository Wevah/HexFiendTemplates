# By Nate Weaver
# https://github.com/Wevah/HexFiendTemplates
# Types: public.jpeg

big_endian
requires 0 "FF D8 FF"
hex 4 "Signature"
move 2
set jpeg_type [ascii 4 "JPEG Type"]

if {$jpeg_type == "JFIF"} {
    move 1
    
    section "JFIF" {
        uint8 "Major Version"
        uint8 "Minor Version"
        uint8 "Resolution or Aspect Ratio"
        uint16 "Horizontal Resolution"
        uint16 "Vertical Resolution"
    }
    
    move -14
    set segment_length_str [uint16 "Segment Length"]
    scan $segment_length_str %u segment_length
    set next_offset [expr {$segment_length + 4}]
    goto $next_offset
}

while {![end]} {
    set segment_type [hex 2 "Segment Identifier"]
    
    if {$segment_type != "FFDA"} {
        set segment_length_str [uint16 "Segment Length"]
    } else {
        set segment_length_str [uint16 "Segment Header Length"]
    }
    
    scan $segment_length_str %u segment_length
    set next_offset [expr {$next_offset + $segment_length + 2}]
            
    if {$segment_type == "FFC0" || $segment_type == "FFC1" || $segment_type == "FFC2"} {
        if {$segment_type == "FFC0"} { set segment_name "Baseline (SOF0)" } \
        elseif {$segment_type == "FFC0"} { set segment_name "Extended Sequential (SOF1)" } \
        elseif {$segment_type == "FFC0"} { set segment_name "Progressive (SOF2)" }
        
        section $segment_name {
            uint8 "Precision"
            uint16 "Lines (Height)"
            uint16 "Samples Per Line (Width)"
            uint8 "Num Components"
        }
    }
    
    if {$segment_type == "FFDA"} {
        break
    }

    goto $next_offset
}
