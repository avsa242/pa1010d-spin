{
    --------------------------------------------
    Filename: navigation.gps.pa1010d.spin
    Author: Jesse Burt
    Description: Driver for the PA1010D GPS module (I2C)
    Copyright (c) 2023
    Started Jun 26, 2023
    Updated Jun 27, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR          = core#SLAVE_ADDR
    SLAVE_RD          = core#SLAVE_ADDR|1

    DEF_SCL           = 28
    DEF_SDA           = 29
    DEF_HZ            = 100_000
    I2C_MAX_FREQ      = core#I2C_MAX_FREQ

VAR

    byte _sentence[nmea0183.SENTNC_MAX_LEN]
    byte _RESET

OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef PA1010D_I2C_BC
    i2c :       "com.i2c.nocog"                 ' BC I2C engine
#else
    i2c :       "com.i2c"                       ' PASM I2C engine
#endif
    core:       "core.con.pa1010d.spin"         ' hw-specific low-level const's
    time:       "time"                          ' basic timing functions
    nmea0183:   "protocol.navigation.nmea0183"

PUB null()
' This is not a top-level object

PUB start(): status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, -1)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, RESET_PIN): status
' Start using custom IO pins and I2C bus frequency
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            _RESET := RESET_PIN
            time.usleep(1_000)                  ' wait for device startup
            if ( i2c.present(SLAVE_WR) )
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB stop()
' Stop the driver
    i2c.deinit()
    bytefill(@_sentence, 0, nmea0183.SENTNC_MAX_LEN)
    _RESET := -1                                ' protect against reset() being called after
                                                '   stop() is called

PUB defaults()
' Set factory defaults

PUB read_sentence(): o | byte i2c_buff[nmea0183.SENTNC_MAX_LEN], i
' Read a sentence from the GPS module
'   Returns: length of sentence read (not including start token or trailing newline)
    repeat until ( sentence_start_found() )

    { read a full-length sentence worth of data (actual sentence may be shorter) }
    bytefill(@i2c_buff, 0, nmea0183.SENTNC_MAX_LEN)
    i2c.rdblock_lsbf(@i2c_buff, nmea0183.SENTNC_MAX_LEN, i2c.NAK)
    i2c.stop()

    { now process it to copy out only the actual sentence }
    o := 0                                      ' init pointers
    i := 0
    bytefill(@_sentence, 0, nmea0183.SENTNC_MAX_LEN)
    repeat
        _sentence[o++] := i2c_buff[i]
    until ( i2c_buff[i++] == $0a )              ' keep reading until newline found
    _sentence[--o] := 0                         ' backtrack and clear the LF, CR
    _sentence[--o] := 0

PUB reset()
' Reset the device
    if ( lookdown(_RESET: 0..31) )
        outa[_RESET] := 0
        dira[_RESET] := 1
        outa[_RESET] := 1

PUB sentence_ptr(): p
' Get the address of the sentence data buffer
    return @_sentence

PRI sentence_start_found(): s | ch
' Find the start of sentence marker
    i2c.start()
    i2c.write(SLAVE_RD)
    s := 0
    repeat                                      ' look for start of sentence ("$")
        ch := i2c.read(i2c.ACK)
        if ( (ch == $0a) or (ch == $ff) )
            { need to start over if we found one of these chars while looking for '$',
                otherwise the module will stop responding }
            i2c.stop()
            return false
    until ( ch == "$" )
    return true


DAT
{
Copyright 2023 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

