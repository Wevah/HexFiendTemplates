# By Nate Weaver
# https://github.com/Wevah/HexFiendTemplates

set ImageTypeMaskRLE 0x8

proc infoForNextPacket {} {
	global bitsPerPixel
	
	set headerByte [uint8]
	set numberOfColorBytes 1
	
	set isRLEPacket [expr {($headerByte & 0x80) != 0}]
	set repetitionCount [expr {($headerByte & 0x7f) + 1}]
	
	if {$isRLEPacket} {
		set packetLength [expr {1 + $bitsPerPixel / 8}]
		move [expr {$bitsPerPixel / 8}]
	} else { #raw packet
		set packetLength [expr {$repetitionCount * $bitsPerPixel / 8 + 1}]
		move [expr {$repetitionCount * $bitsPerPixel / 8}]
	}
	
	return [dict create repetitionCount $repetitionCount packetLength $packetLength]
}

proc verifyFooter {} {
	goto -18
	set truevisionTag [ascii 18]

	if {$truevisionTag == "TRUEVISION-XFILE."} {
		return true
	}
	
	return false
}

proc readPostageStampAtOffset {offset} {
	goto $offset
	
	section "Postage Stamp" {
		global bitsPerPixel
	
		set width [uint8 "Width"]
		set height [uint8 "Height"]
	
		bytes [expr {$width * $height * $bitsPerPixel / 8}] "Image Data"
		sectionvalue "$width × $height"
	}
}

proc readExtensionAreaAtOffset {offset} {
	goto $offset
	
	section "Extension Area" {
		# Extension size should be 495
		set extensionSize [uint16 "Extension Size"]
	
		ascii 41 "Author Name"
		# FIXME should be split up into 4 lines
		section "Author Comments" {
			ascii 81 "Line 1"
			ascii 81 "Line 2"
			ascii 81 "Line 3"
			ascii 81 "Line 4"
		}
	
		section "Date/Time Stamp" {
			set month [int16 "Month"]
			set day [int16 "Day"]
			set year [int16 "Year"]
			set hour [int16 "Hour"]
			set minute [int16 "Minute"]
			set second [int16 "Second"]
			
			set dateTime [clock scan "$year-$month-$day $hour:$minute:$second" -format "%Y-%m-%d %H:%M:%S"]
			sectionvalue [clock format $dateTime -format "%a %b %d, %Y at %X"]
		}
			
		ascii 41 "Job Name/ID"
	
		section "Job Time" {
			set hours [int16 "Hours"]
			set minutes [int16 "Minutes"]
			set seconds [int16 "Seconds"]
			sectionvalue "${hours}h ${minutes}m ${seconds}s"
		}
	
		section "Software" {
			set softwareID [ascii 41 "Software ID"]
	
			section "Software Version" {
				set versionNumber [uint16 "Version * 100"]
				set versionLetter [ascii 1 "Version Letter"]
				set versionString "[expr {$versionNumber / 100}].[expr {$versionNumber % 100}]$versionLetter"
				sectionvalue $versionString
			}
			
			sectionvalue "$softwareID $versionString"
		}
	
		hex 4 "Key Color"
	
		section "Pixel Aspect Ratio" {
			set numerator [uint16 "Pixel Aspect Numerator"]
			set denominator [uint16 "Pixel Aspect Denominator"]
			
			if {$numerator == 0 || $denominator == 0} {
				sectionvalue "(None)"
			} else {
				sectionvalue "$numerator:$denominator"
			}
		}
		
		section "Gamma" {
			set numerator [uint16 "Gamma Numerator"]
			set denominator [uint16 "Gamma Denominator"]
			
			if {$denominator != 0} {
				sectionvalue [expr {double($numerator)/double($denominator)}]
			} else {
				sectionvalue "(None)"
			}
		}
	
		uint32 "Color Correction Offset"
		set postageStampOffset [uint32 "Postage Stamp Offset"]
		uint32 "Scan Line Offset"
	
		uint8 "Attributes Type"
	}
	
	if {$postageStampOffset != 0} {
		readPostageStampAtOffset $postageStampOffset
	}
}

proc readFooter {} {
	if {[verifyFooter]} {
		goto -26
		
		section "Footer" {
			set extensionAreaOffset [uint32 "Extension Area Offset"]
			set developerDirectoryOffset [uint32 "Developer Directory Offset"]
			ascii 18 "Signature"
		}

		if {$extensionAreaOffset != 0} {
			readExtensionAreaAtOffset $extensionAreaOffset
		}
	}
}

proc humanReadableImageType {imageType} {
	if {$imageType < 0x10} {
		set colorType [expr {$imageType & 0x07}]
	
		switch [expr {$imageType & 0x07}] {
			1 {set colorType "Color-Mapped"}
			2 {set colorType "True-Color"}
			3 {set colorType "Black and White (Unmapped)"}
		}
	
		set compressionType [expr {$imageType & 0x08 ? "RLE" : "Uncompressed"}]
	
		return "$colorType, $compressionType"
	}
	
	return $imageType
}

section "Image Header" {
	set idLength [uint8 "ID Length"]
	set colorMapType [uint8 "Color Map Type"]
	
	section "Image Type" {
		set imageType [uint8 "Raw Value"]
		sectionvalue [humanReadableImageType $imageType]		
	}

	# Color Map
	uint16 "First Entry Index"
	set colorMapLength [uint16 "Color Map Length"]
	set colorMapEntrySize [uint8 "Color Map Entry Size"]

	# Image Specification
	section "Origin" {
		set xOrigin [uint16 "X"]
		set yOrigin [uint16 "Y"]
		sectionvalue "$xOrigin, $yOrigin"
	}

	section "Dimensions" {
		set imageWidth [uint16 "Width"]
		set imageHeight [uint16 "Height"]
		sectionvalue "$imageWidth × $imageHeight"
	}
	
	set bitsPerPixel [uint8 "Bits Per Pixel"]
	uint8 "Image Descriptor"
}

if {$idLength > 0} {
	ascii $idLength "Image ID"
}

if {$colorMapLength > 0} {
	bytes [expr {$colorMapLength * $colorMapEntrySize / 8}] "Color Map Data"
}

set pixelCount [expr {$imageWidth * $imageHeight}]

set imageDataLength 0
set processedPixels 0

if {($imageType & $ImageTypeMaskRLE) != 0} {
	while {$processedPixels < $pixelCount} {
		set packetInfo [infoForNextPacket]
		set processedPixels [expr {$processedPixels + [dict get $packetInfo repetitionCount]}]
		set imageDataLength [expr {$imageDataLength + [dict get $packetInfo packetLength]}]
	}
	move -$imageDataLength
} else {
	set imageDataLength [expr {$imageWidth * $imageHeight * $bitsPerPixel / 8}]
}

bytes $imageDataLength "Image Data"

readFooter

