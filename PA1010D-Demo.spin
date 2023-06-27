{
    --------------------------------------------
    Filename: PA1010D-Demo.spin
    Author: Jesse Burt
    Description: Demo of the PA1010D GPS module driver (I2C)
        * Raw sentence output
    Copyright (c) 2023
    Started Jun 26, 2023
    Updated Jun 27, 2023
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED         = cfg#LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000
    RESET_PIN   = -1                            ' optional
' --

OBJ

    cfg:        "boardcfg.flip"
    ser:        "com.serial.terminal.ansi"
    time:       "time"
    nmea0183:   "protocol.navigation.nmea0183"
    gps:        "navigation.gps.pa1010d"

PUB main() | l

    setup()
    repeat
        l := gps.read_sentence()
        if ( nmea0183.checksum() == nmea0183.gen_checksum() )
            { if the checksum is good, display the sentence }
            ser.printf2(@"%d: %s\n\r", l, gps.sentence_ptr())

PUB setup()

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( gps.startx(SCL_PIN, SDA_PIN, I2C_FREQ, RESET_PIN) )
        ser.strln(@"PA1010D driver started")
    else
        ser.strln(@"PA1010D driver failed to start - halting")
        repeat

    { point the nmea0183 object to the location of the sentence }
    nmea0183.ptr_sentence( gps.sentence_ptr() )

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

