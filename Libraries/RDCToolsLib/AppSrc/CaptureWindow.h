Define C_CaptureFolderKey  for "CaptureFolder"
Define C_CaptureFolderName for "Capture"
Define SRCCOPY           for |CI$00CC0020
Define CF_BITMAP         for |CI2

Enum_List   //Enum DEVCAP_INDEX As Integer  
    Define DRIVERVERSION for 0 
    Define TECHNOLOGY for 2 
    Define HORZSIZE for 4 
    Define VERTSIZE for 6 
    Define HORZRES for 8 
    Define VERTRES for 10 
    Define BITSPIXEL for 12 
    Define PLANES for 14 
    Define NUMBRUSHES for 16 
    Define NUMPENS for 18 
    Define NUMMARKERS for 20 
    Define NUMFONTS for 22 
    Define NUMCOLORS for 24 
    Define PDEVICESIZE for 26 
    Define CURVECAPS for 28 
    Define LINECAPS for 30 
    Define POLYGONALCAPS for 32 
    Define TEXTCAPS for 34 
    Define CLIPCAPS for 36 
    Define RASTERCAPS for 38 
    Define ASPECTX for 40 
    Define ASPECTY for 42 
    Define ASPECTXY for 44 
    Define SHADEBLENDCAPS for 45 
#IFNDEF LOGPIXELSX
    Define LOGPIXELSX for 88 
#ENDIF
#IFNDEF LOGPIXELSY
    Define LOGPIXELSY for 90 
#ENDIF   
    Define SIZEPALETTE for 104 
    Define NUMRESERVED for 106 
    Define COLORRES for 108 
    Define PHYSICALWIDTH for 110 
    Define PHYSICALHEIGHT for 111 
    Define PHYSICALOFFSETX for 112 
    Define PHYSICALOFFSETY for 113 
    Define SCALINGFACTORX for 114 
    Define SCALINGFACTORY for 115 
    Define VREFRESH for 116 
    Define DESKTOPVERTRES for 117 
    Define DESKTOPHORZRES for 118 
    Define BLTALIGNMENT for 119 
End_Enum_List  

Enum_List   //Enum compression
    Define bi_rgb for 0       //- none (also identified by bi_rgb)
    Define bi_rle4 for 1      //- rle 8-bit / pixel (also identified by bi_rle4)
    Define bi_rle8 for 2      //- rle 4-bit / pixel (also identified by bi_rle8)
    Define bi_bitfields for 3 //- bitfields (also identified by bi_bitfields)
End_Enum_List  

#IFNDEF GENERIC_WRITE
    Define GENERIC_WRITE          for 1073741824 //= 0x40000000 
#ENDIF

#IFNDEF CREATE_ALWAYS
    Define CREATE_ALWAYS          for 2          //= 0x2 
#ENDIF
#IFNDEF FILE_ATTRIBUTE_NORMAL 
    Define FILE_ATTRIBUTE_NORMAL  for 128        //= 0x80 
#ENDIF

Define DIB_PAL_COLORS for 1
Define DIB_RGB_COLORS for 0

#IFNDEF _STRUCT_RECT_TYPE
Struct RECT_TYPE
   Integer ileft
   Integer itop
   Integer iright
   Integer ibottom
End_Struct
#ENDIF

#IFNDEF _STRUCT_BITMAPINFOHEADER
Struct BITMAPINFOHEADER
    DWord biSize                    // DWORD=integer
    Integer biWidth                    // LONG =integer
    Integer biHeight                   // LONG 
    Short biPlanes                   // WORD =short
    Short biBitCount                 // WORD 
    DWord biCompression             // DWORD
    DWord biSizeImage               // DWORD
    Integer biXPelsPerMeter            // LONG 
    Integer biYPelsPerMeter            // LONG 
    DWord biClrUsed                 // DWORD
    DWord biClrImportant            // DWORD
End_Struct
#ENDIF

#IFNDEF _STRUCT_RGBQUAD
Struct RGBQUAD
  CHAR rgbBlue            //BYTE=CHAR
  CHAR rgbGreen
  CHAR rgbRed
  CHAR rgbReserved
End_Struct
#ENDIF

#IFNDEF _STRUCT_BITMAPINFO 
Struct BITMAPINFO 
    BITMAPINFOHEADER bmiHeader 
    RGBQUAD[] bmiColors
End_Struct
#ENDIF

#IFNDEF _STRUCT_BITMAPFILEHEADER
Struct BITMAPFILEHEADER
    Short bfType         //WORD  //BM (0x4D42)
#IFDEF IS$WIN64
    Short iMissingAlignment1
#ENDIF
    DWord bfSize        //DWORD
    Short bfReserved1    //WORD 
    Short bfReserved2    //WORD 
    DWord bfOffBits     //DWORD
End_Struct
#ENDIF

#IFNDEF _STRUCT_BITMAP 
Struct BITMAP 
    Integer   bmType
    Integer   bmWidth
    Integer   bmHeight
    Integer   bmWidthBytes
    Short   bmPlanes
    Short   bmBitsPixel
#IFDEF IS$WIN64
    Integer iMissingAlignment1
#ENDIF
    Pointer bmBits
end_struct
#ENDIF

#IFNDEF _STRUCT_DIBSECTION 
Struct DIBSECTION 
    BITMAP           dsBm
    BITMAPINFOHEADER dsBmih
    DWord[3]         dsBitfields
#IFDEF IS$WIN64
    Integer iMissingAlignment1
#ENDIF
  Handle           dshSection
  DWord            dsOffset
#IFDEF IS$WIN64
    Integer iMissingAlignment2
#ENDIF
End_Struct
#ENDIF
