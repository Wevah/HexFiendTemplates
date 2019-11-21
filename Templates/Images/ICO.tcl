# By Nate Weaver
# https://github.com/Wevah/HexFiendTemplates
# Types: ico, cur

requires 0 "00 00" 

bytes 2 Reserved
# 1 for ICO 2 for CUR
section "Type" {
	set fileType [uint16 "Raw Value"]

	if {$fileType == 1}	 {
		sectionvalue "ICO"
	} elseif {$fileType == 2} {
		sectionvalue "CUR"
	} else {
		sectionvalue "$fileType"
	}
}

 
set numImages [uint16 "Image count"]

proc dataIsPNGAtOffset {offset} {
	goto $offset
	set pngSignature [bytes 8]
		
	if {$pngSignature == "\x89PNG\r\n\x1a\n"} {
		return true
	}
	
	return false
}

proc dimensionsFromPNGDataAtOffset {offset} {
	if {[dataIsPNGAtOffset $offset]} {
		move 8
		big_endian
		lappend dims [uint32]
		entry "foo" [lindex $dims 0]
		lappend dims [uint32]
		little_endian
		return $dims
	}
	
	return { 0 0 }
}

section "Image Entries" {
	for {set i 0} {$i < $numImages} {incr i} {
		section "Image [expr {$i + 1}]" {
			set width [uint8 "Width"]
			set height [uint8 "Height"]
			
			if {$width != 0} {
				set dimensions "$width × $height"
			}
					
			uint8 "Color count"
			bytes 1 "Reserved"
		
			if {$fileType == 1} {
				uint16 "Color Planes"
				uint16 "Bits Per Pixel"
			} elseif {$fileType == 2} {
				section "Hotspot" {
					set hotspotX [uint16 "Hotspot X"]
					set hotspotY [uint16 "Hotspot Y"]
					sectionvalue "$hotspotX, $hotspotY"
				}
			}
		
			set imageSize [uint32 "Image Size"]
			set imageOffset [uint32 "Image Offset"]
			
			if {$width == 0} {
				set pngDimensions [dimensionsFromPNGDataAtOffset $imageOffset]
			
				if {[lindex $pngDimensions 0] != 0} {
					set dimensions "[lindex $pngDimensions 0] × [lindex $pngDimensions 1], PNG"
				}
				
				goto [expr 6 + ($i + 1) * 16]
			}
			
			sectionvalue $dimensions

			lappend imageDataValues [dict create size $imageSize offset $imageOffset dimensions $dimensions]			
		}
	}
}

section "Image Data" {
	foreach imageData $imageDataValues {
		goto [dict get $imageData offset]
		bytes [dict get $imageData size] "[incr $i] ([dict get $imageData dimensions])"
	}
}
