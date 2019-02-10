# By Nate Weaver
# https://github.com/Wevah/HexFiendTemplates
#
# types: bsp

little_endian
requires 0 "56 42 53 50" ;# VBSP
ascii 4 "Signature"
int32 "BSP File Version"

# 22-25, 49, 50-52 have multiple definitions, depending on the file version

array set lumpnames {
	0	ENTITIES
	1	PLANES
	2	TEXDATA
	3	VERTEXES
	4	VISIBILITY
	5	NODES
	6	TEXINFO
	7	FACES
	8	LIGHTING
	9	OCCLUSION
	10	LEAFS
	11	FACEIDS
	12	EDGES
	13	SURFEDGES
	14	MODELS
	15	WORLDLIGHTS
	16	LEAFFACES
	17	LEAFBRUSHES
	18	BRUSHES
	19	BRUSHSIDES
	20	AREAS
	21	AREAPORTALS
	22	PORTALS/UNUSED0/PROPCOLLISION
	23	CLUSTERS/UNUSED1/PROPHULLS
	24	PORTALVERTS/UNUSED2/PROPHULLVERTS
	25	CLUSTERPORTALS/UNUSED3/PROPTRIS
	26	DISPINFO
	27	ORIGINALFACES
	28	PHYSDISP
	29	PHYSCOLLIDE
	30	VERTNORMALS
	31	VERTNORMALINDICES
	32	DISP_LIGHTMAP_ALPHAS
	33	DISP_VERTS
	34	DISP_LIGHTMAP_SAMPLE_POSITIONS
	35	GAME_LUMP
	36	LEAFWATERDATA
	37	PRIMITIVES
	38	PRIMVERTS
	39	PRIMINDICES
	40	PAKFILE
	41	CLIPPORTALVERTS
	42	CUBEMAPS
	43	TEXDATA_STRING_DATA
	44	TEXDATA_STRING_TABLE
	45	OVERLAYS
	46	LEAFMINDISTTOWATER
	47	FACE_MACRO_TEXTURE_INFO
	48	DISP_TRIS
	49	PHYSCOLLIDESURFACE/PROP_BLOB
	50	WATEROVERLAYS
	51	LIGHTMAPPAGES/LEAF_AMBIENT_INDEX_HDR
	52	LIGHTMAPPAGEINFOS/LEAF_AMBIENT_INDEX
	53	LIGHTING_HDR
	54	WORLDLIGHTS_HDR
	55	LEAF_AMBIENT_LIGHTING_HDR
	56	LEAF_AMBIENT_LIGHTING
	57	XZIPPAKFILE
	58	FACES_HDR
	59	MAP_FLAGS
	60	OVERLAY_FADES
	61	OVERLAY_SYSTEM_LEVELS
	62	PHYSLEVEL
	63	DISP_MULTIBLEND
}

section "Lumps"
for {set i 0} {$i < 64} {incr i} {
	if ([info exists lumpnames($i)]) { section "$i $lumpnames($i)" } \
	else { section $i }
	int32 "File Offset"
	int32 "Lump Length"
	int32 "Lump Version"
	ascii 4 "Lump Ident Code"
	endsection
}
endsection

int32 "Map Revision"
