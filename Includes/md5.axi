PROGRAM_NAME='Auth_Authentication'
(*{{PS_SOURCE_INFO(PROGRAM STATS)                          *)
(***********************************************************)
(*  FILE CREATED ON: 07/15/2002 AT: 10:09:06               *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 08/14/2002 AT: 14:13:37         *)
(***********************************************************)
(*  ORPHAN_FILE_PLATFORM: 1                                *)
(***********************************************************)
(*!!FILE REVISION: Rev 0                                   *)
(*  REVISION DATE: 07/15/2002                              *)
(*                                                         *)
(*  COMMENTS:      ====================                    *)
(*                 ==== BUILD 1 =======                    *)
(*                 ====================                    *)
(*                                                         *)
(***********************************************************)
(*}}PS_SOURCE_INFO                                         *)
(***********************************************************)

(***********************************************************
  NOTE:
   -This include file performs MD5 encryption.  It is reverse
    engineered from "CMD5lib.cpp" and "CMD5lib.h".
   -This include file will eventually be moved to a new
    function for the NetLinx master.
   -Based upon RFC1321.
 ***********************************************************)

// ----------------------------------------------------------
// Hinweis:
//   Die Implementierung der MD5 Funktionen scheint nicht
//   Korrekt zu sein. Bis zu einer Länge von 119 Bytes
//   ist das Ergebnis ok und stimmt mit den Keys vom PC
//   (Visual Basic) ueberein.
//   !!!! Ab 120 Zeichen stimmen die Keys nicht !!!!
// ----------------------------------------------------------



(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

/*  T constants */
LONG T1  = $d76aa478
LONG T2  = $e8c7b756
LONG T3  = $242070db
LONG T4  = $c1bdceee
LONG T5  = $f57c0faf
LONG T6  = $4787c62a
LONG T7  = $a8304613
LONG T8  = $fd469501
LONG T9  = $698098d8
LONG T10 = $8b44f7af
LONG T11 = $ffff5bb1
LONG T12 = $895cd7be
LONG T13 = $6b901122
LONG T14 = $fd987193
LONG T15 = $a679438e
LONG T16 = $49b40821
LONG T17 = $f61e2562
LONG T18 = $c040b340
LONG T19 = $265e5a51
LONG T20 = $e9b6c7aa
LONG T21 = $d62f105d
LONG T22 = $02441453
LONG T23 = $d8a1e681
LONG T24 = $e7d3fbc8
LONG T25 = $21e1cde6
LONG T26 = $c33707d6
LONG T27 = $f4d50d87
LONG T28 = $455a14ed
LONG T29 = $a9e3e905
LONG T30 = $fcefa3f8
LONG T31 = $676f02d9
LONG T32 = $8d2a4c8a
LONG T33 = $fffa3942
LONG T34 = $8771f681
LONG T35 = $6d9d6122
LONG T36 = $fde5380c
LONG T37 = $a4beea44
LONG T38 = $4bdecfa9
LONG T39 = $f6bb4b60
LONG T40 = $bebfbc70
LONG T41 = $289b7ec6
LONG T42 = $eaa127fa
LONG T43 = $d4ef3085
LONG T44 = $04881d05
LONG T45 = $d9d4d039
LONG T46 = $e6db99e5
LONG T47 = $1fa27cf8
LONG T48 = $c4ac5665
LONG T49 = $f4292244
LONG T50 = $432aff97
LONG T51 = $ab9423a7
LONG T52 = $fc93a039
LONG T53 = $655b59c3
LONG T54 = $8f0ccc92
LONG T55 = $ffeff47d
LONG T56 = $85845dd1
LONG T57 = $6fa87e4f
LONG T58 = $fe2ce6e0
LONG T59 = $a3014314
LONG T60 = $4e0811a1
LONG T61 = $f7537e82
LONG T62 = $bd3af235
LONG T63 = $2ad7d2bb
LONG T64 = $eb86d391


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE


STRUCTURE md5_state_t
{
  LONG  count[2]    // message length
  LONG  abcd[4]     // digest buffer
  CHAR  buf[64]     // accumulate block
}


(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE


(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)


//------------------------------------------------------------------
// Name: encrypt()  (StringToEncrypt)
//
// Purpose: encrypts (MD5) input string
//
// Parameters: pcStringToEncrypt - "'fg#','sn#'"
//
// Return: EncryptedString[32]
//
//------------------------------------------------------------------
DEFINE_FUNCTION CHAR[32] fnEncryptToMD5 (CHAR pcStringToEncrypt[])
STACK_VAR
  INTEGER ii
  md5_state_t state
  CHAR digest[16]
  CHAR strOutput[32]
{
// clear buffer
  for(ii = 1; ii <= 16; ii++)
    digest[ii] = 0

// initialize encryption algorithm
  md5_init(state)

// process input string
  md5_append(state, pcStringToEncrypt, LENGTH_STRING(pcStringToEncrypt))

// complete processing of string
  md5_finish(state, digest)

// Testing
  for(ii = 1; ii <= 16; ii++)
    strOutput = "strOutput,FORMAT('%02x',digest[ii])"

// Return the key
  RETURN(strOutput)
}


//------------------------------------------------------------------
// Name: md5_init()
//
// Purpose: initialize MD5 encryption algorithm
//
// Parameters: parms - state parameter array
//
// Return: none
//
//------------------------------------------------------------------
DEFINE_FUNCTION INTEGER md5_init(md5_state_t parms)
STACK_VAR
  INTEGER ii
{
  parms.count[1] = 0
  parms.count[2] = 0

// Load magic inititialization constants.
  parms.abcd[1] = $67452301
  parms.abcd[2] = $efcdab89
  parms.abcd[3] = $98badcfe
  parms.abcd[4] = $10325476

//  parms.buf = ""
//  for(ii = 1; ii <= 64; ii++)
//    parms.buf[ii] = 0
  parms.buf = "0,0,0,0,0,0,0,0,
               0,0,0,0,0,0,0,0,
               0,0,0,0,0,0,0,0,
               0,0,0,0,0,0,0,0,
               0,0,0,0,0,0,0,0,
               0,0,0,0,0,0,0,0,
               0,0,0,0,0,0,0,0,
               0,0,0,0,0,0,0,0"
}


//------------------------------------------------------------------
// Name:md5_append()
//
// Purpose: process partial string (64 characters) for MD5 encryption
//
// Parameters: parms - state parameter array
//             data - character string to encrypt
//             nbytes - length of string to encrypt
//
// Return: none
//
//------------------------------------------------------------------
DEFINE_FUNCTION md5_append(md5_state_t parms, CHAR data[], INTEGER nBytes)
STACK_VAR
  INTEGER p_idx
  INTEGER left
  INTEGER offset
  LONG nBits
  INTEGER copy
  INTEGER ii
  CHAR strOutput[500]
{
  p_idx = 0;
  left = nBytes
  offset = TYPE_CAST( (parms.count[1] >> 3) & 63 )
  nBits = nBytes << 3

  if (nBytes <= 0)
    return;

// Update the message length
  parms.count[2] = parms.count[2] + (nBytes >> 29)
  parms.count[1] = parms.count[1] + nBits
  if (parms.count[1] < nBits)
    parms.count[2]++

// Process an initial partial block.
  if(offset)
  {
    if((offset + nBytes) > 64)
      copy = 64 - offset
    else
      copy = nBytes

    parms.buf = "LEFT_STRING(parms.buf,offset),MID_STRING(data,p_idx+1,copy)"

    if ((offset + copy) < 64)
      return;

    p_idx = p_idx + copy

    left = left - copy

    md5_process(parms, parms.buf);
  }

//    /* Process full blocks. */
  for (ii = 1; left >= 64; left = left - 64, ii++)
  {
    md5_process(parms, "RIGHT_STRING(data,LENGTH_STRING(data)-p_idx)");
    p_idx = p_idx + 64
  }

//    /* Process a final partial block. */
  if (left)
  {
    parms.buf = RIGHT_STRING(data,LENGTH_STRING(data)-p_idx)
    SET_LENGTH_STRING(parms.buf,left)
  }
}


//------------------------------------------------------------------
// Name: md5_finish()
//
// Purpose: complete encryption of input string
//
// Parameters: parms - state parameter array
//             digest - output storage for encrypted codes
//
// Return: encoded (base64) character
//
//------------------------------------------------------------------
DEFINE_FUNCTION INTEGER md5_finish(md5_state_t parms, CHAR digest[])
STACK_VAR
  CHAR pad[64]
  INTEGER I
  INTEGER N
  CHAR data[8]
  INTEGER ii
  CHAR strOutput[500];
{
  pad = "$80,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
           0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0"

// Save the length before padding.
  SET_LENGTH_STRING(DATA,8)

  for (N = 1,i = 0; i <  8; i++,N++)
    data[N] = TYPE_CAST(  (parms.count[(i >> 2) + 1] >> ((i & 3) << 3))  )

// Pad to 56 bytes mod 64.
  md5_append(parms, pad, TYPE_CAST(  ((55 - (parms.count[1] >> 3)) & 63) + 1  )  )

// Append the length.
  md5_append(parms, data, 8)

// transfer encrypted code
  for (N = 1,i = 0; i < 16; i++,N++)
    digest[N] = TYPE_CAST(  (parms.abcd[(i >> 2) + 1] >> ((i & 3) << 3))  )
}


//------------------------------------------------------------------
// Name: md5_process()
//
// Purpose: main encryption processing routine
//
// Parameters: parms - state parameters for encryption
//             data - string to be processed (up to 64 characters)
//
// Return: none
//
//------------------------------------------------------------------
DEFINE_FUNCTION INTEGER md5_process(md5_state_t parms, CHAR data[])
STACK_VAR
  LONG A
  LONG B
  LONG C
  LONG D
  LONG T
  INTEGER I
  LONG X[16]
  LONG data3[4]
{
  a = parms.abcd[1]
  b = parms.abcd[2]
  c = parms.abcd[3]
  d = parms.abcd[4]

(********************************************************
     * On big-endian machines, we must arrange the bytes in the right
     * order.  COLDFIRE IS A BIG-ENDIAN MACHINE !!!
*********************************************************)
  for (i = 1; i <=16; i++)
  {
    data3[1] = data[((i - 1) * 4) + 1]
    data3[2] = data[((i - 1) * 4) + 2]
    data3[3] = data[((i - 1) * 4) + 3]
    data3[4] = data[((i - 1) * 4) + 4]
    X[i] = data3[1] + (data3[2] << 8) + (data3[3] << 16) + (data3[4] << 24)
  }


// Round 1.
    FF(a, b, c, d,  0,  7,  T1, X, t);
    FF(d, a, b, c,  1, 12,  T2, X, t);
    FF(c, d, a, b,  2, 17,  T3, X, t);
    FF(b, c, d, a,  3, 22,  T4, X, t);
    FF(a, b, c, d,  4,  7,  T5, X, t);
    FF(d, a, b, c,  5, 12,  T6, X, t);
    FF(c, d, a, b,  6, 17,  T7, X, t);
    FF(b, c, d, a,  7, 22,  T8, X, t);
    FF(a, b, c, d,  8,  7,  T9, X, t);
    FF(d, a, b, c,  9, 12, T10, X, t);
    FF(c, d, a, b, 10, 17, T11, X, t);
    FF(b, c, d, a, 11, 22, T12, X, t);
    FF(a, b, c, d, 12,  7, T13, X, t);
    FF(d, a, b, c, 13, 12, T14, X, t);
    FF(c, d, a, b, 14, 17, T15, X, t);
    FF(b, c, d, a, 15, 22, T16, X, t);

// Round 2.
    GG(a, b, c, d,  1,  5, T17, X, t);
    GG(d, a, b, c,  6,  9, T18, X, t);
    GG(c, d, a, b, 11, 14, T19, X, t);
    GG(b, c, d, a,  0, 20, T20, X, t);
    GG(a, b, c, d,  5,  5, T21, X, t);
    GG(d, a, b, c, 10,  9, T22, X, t);
    GG(c, d, a, b, 15, 14, T23, X, t);
    GG(b, c, d, a,  4, 20, T24, X, t);
    GG(a, b, c, d,  9,  5, T25, X, t);
    GG(d, a, b, c, 14,  9, T26, X, t);
    GG(c, d, a, b,  3, 14, T27, X, t);
    GG(b, c, d, a,  8, 20, T28, X, t);
    GG(a, b, c, d, 13,  5, T29, X, t);
    GG(d, a, b, c,  2,  9, T30, X, t);
    GG(c, d, a, b,  7, 14, T31, X, t);
    GG(b, c, d, a, 12, 20, T32, X, t);

// Round 3.
    HH(a, b, c, d,  5,  4, T33, X, t);
    HH(d, a, b, c,  8, 11, T34, X, t);
    HH(c, d, a, b, 11, 16, T35, X, t);
    HH(b, c, d, a, 14, 23, T36, X, t);
    HH(a, b, c, d,  1,  4, T37, X, t);
    HH(d, a, b, c,  4, 11, T38, X, t);
    HH(c, d, a, b,  7, 16, T39, X, t);
    HH(b, c, d, a, 10, 23, T40, X, t);
    HH(a, b, c, d, 13,  4, T41, X, t);
    HH(d, a, b, c,  0, 11, T42, X, t);
    HH(c, d, a, b,  3, 16, T43, X, t);
    HH(b, c, d, a,  6, 23, T44, X, t);
    HH(a, b, c, d,  9,  4, T45, X, t);
    HH(d, a, b, c, 12, 11, T46, X, t);
    HH(c, d, a, b, 15, 16, T47, X, t);
    HH(b, c, d, a,  2, 23, T48, X, t);

// Round 4.
    II(a, b, c, d,  0,  6, T49, X, t);
    II(d, a, b, c,  7, 10, T50, X, t);
    II(c, d, a, b, 14, 15, T51, X, t);
    II(b, c, d, a,  5, 21, T52, X, t);
    II(a, b, c, d, 12,  6, T53, X, t);
    II(d, a, b, c,  3, 10, T54, X, t);
    II(c, d, a, b, 10, 15, T55, X, t);
    II(b, c, d, a,  1, 21, T56, X, t);
    II(a, b, c, d,  8,  6, T57, X, t);
    II(d, a, b, c, 15, 10, T58, X, t);
    II(c, d, a, b,  6, 15, T59, X, t);
    II(b, c, d, a, 13, 21, T60, X, t);
    II(a, b, c, d,  4,  6, T61, X, t);
    II(d, a, b, c, 11, 10, T62, X, t);
    II(c, d, a, b,  2, 15, T63, X, t);
    II(b, c, d, a,  9, 21, T64, X, t);

// Then perform the following additions. (That is increment each
// of the four registers by the value it had before this block
// was started.
    parms.abcd[1] = parms.abcd[1] + a
    parms.abcd[2] = parms.abcd[2] + b
    parms.abcd[3] = parms.abcd[3] + c
    parms.abcd[4] = parms.abcd[4] + d
}


//------------------------------------------------------------------
// F, G, H, and I are basic MD5 functions.
//------------------------------------------------------------------
DEFINE_FUNCTION LONG F(LONG x,LONG  y,LONG  z) { RETURN (((x) & (y)) | (~(x) & (z))) }
DEFINE_FUNCTION LONG G(LONG x,LONG  y,LONG  z) { RETURN (((x) & (z)) | ((y) & ~(z))) }
DEFINE_FUNCTION LONG H(LONG x,LONG  y,LONG  z) { RETURN ((x) ^ (y) ^ (z))            }
DEFINE_FUNCTION LONG I(LONG x,LONG  y,LONG  z) { RETURN ((y) ^ ((x) | ~(z)))         }


//------------------------------------------------------------------
// Rotates x left n bits.
//------------------------------------------------------------------
DEFINE_FUNCTION LONG ROTATE_LEFT(LONG x, LONG n)
{
  RETURN (((x) << (n)) | ((x) >> (32 - (n))))
}

//------------------------------------------------------------------
// FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4.
// Rotation is separate from addition to prevent recomputation.
//------------------------------------------------------------------
DEFINE_FUNCTION LONG FF(LONG a,LONG  b,LONG  c,LONG  d,LONG  k,LONG  s,LONG  Ti, LONG X[16], LONG t)
{
  k++
  t = a + F(b,c,d) + X[k] + Ti
  a = ROTATE_LEFT(t, s) + b
}

DEFINE_FUNCTION LONG GG(LONG a,LONG  b,LONG  c,LONG  d,LONG  k,LONG  s,LONG  Ti, LONG X[16], LONG t)
{
  k++
  t = a + G(b,c,d) + X[k] + Ti
  a = ROTATE_LEFT(t, s) + b
}

DEFINE_FUNCTION LONG HH(LONG a,LONG  b,LONG  c,LONG  d,LONG  k,LONG  s,LONG  Ti, LONG X[16], LONG t)
{
  k++
  t = a + H(b,c,d) + X[k] + Ti
  a = ROTATE_LEFT(t, s) + b
}

DEFINE_FUNCTION LONG II(LONG a,LONG  b,LONG  c,LONG  d,LONG  k,LONG  s,LONG  Ti, LONG X[16], LONG t)
{
  k++
  t = a + I(b,c,d) + X[k] + Ti
  a = ROTATE_LEFT(t, s) + b
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GOES BELOW                    *)
(***********************************************************)
DEFINE_EVENT

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

