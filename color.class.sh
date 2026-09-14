#!/bin/bash
# ======================================================================
#
# COLORS
#
# a few shell functions for colored output
# 
# ----------------------------------------------------------------------
# License: GPL 3.0
# Source: <https://github.com/axelhahn/bash_colorfunctions>
# Docs: <https://www.axel-hahn.de/docs/bash_colorfunctions/>
# ----------------------------------------------------------------------
# 2023-08-09  ahahn  0.1  initial lines
# 2023-08-09  ahahn  0.2  hide output of regex test with grep
# 2023-08-13  ahahn  0.3  introduce of color presets with foreground and background
# 2023-08-13  ahahn  0.4  list presets, debug, count of colors
# 2023-08-13  ahahn  0.5  support of RGB hex code
# 2023-08-14  ahahn  0.6  fix setting fg and bg as RGB hex code
# 2023-08-14  ahahn  0.7  remove color.ansi; respect NO_COLOR=1
# 2023-08-16  ahahn  0.8  add function color.preset
# 2026-05-29  ahahn  0.9  fix error message on wrong preset
# ======================================================================

_VERSION=0.9
typeset -i COLOR_DEBUG; COLOR_DEBUG=0

# ----------------------------------------------------------------------
# CONSTANTS
# ----------------------------------------------------------------------

declare -A BGCOLOR_CODE
declare -A COLOR_CODE

# background colors
BGCOLOR_CODE[black]="40"
BGCOLOR_CODE[red]="41"
BGCOLOR_CODE[green]="42"
BGCOLOR_CODE[brown]="43"
BGCOLOR_CODE[blue]="44"
BGCOLOR_CODE[purple]="45"
BGCOLOR_CODE[cyan]="46"
BGCOLOR_CODE[lightgray]="47"
BGCOLOR_CODE[darkgray]="1;40"
BGCOLOR_CODE[lightred]="1;41"
BGCOLOR_CODE[lightgreen]="1;42"
BGCOLOR_CODE[yellow]="1;43"
BGCOLOR_CODE[lightblue]="1;44"
BGCOLOR_CODE[lightpurple]="1;45"
BGCOLOR_CODE[lightcyan]="1;46"
BGCOLOR_CODE[white]="1;47"

# foreground colors
COLOR_CODE[black]="30"
COLOR_CODE[red]="31"
COLOR_CODE[green]="32"
COLOR_CODE[brown]="33"
COLOR_CODE[blue]="34"
COLOR_CODE[purple]="35"
COLOR_CODE[cyan]="36"
COLOR_CODE[lightgray]="37"
COLOR_CODE[darkgray]="1;30"
COLOR_CODE[lightred]="1;31"
COLOR_CODE[lightgreen]="1;32"
COLOR_CODE[yellow]="1;33"
COLOR_CODE[lightblue]="1;34"
COLOR_CODE[lightpurple]="1;35"
COLOR_CODE[lightcyan]="1;36"
COLOR_CODE[white]="1;37"

# custom presets as array of foreground and background color
#
#              +--- the label is part of the variable
#              |
#              v
# COLOR_PRESET_error=("white" "red")
# COLOR_PRESET_ok=("white" "green")

# ----------------------------------------------------------------------
# PRIVATE FUNCTIONS
# ----------------------------------------------------------------------

# write debug output - if debugging is enabled
# Its output is written to STDERR
# param  string  text to show
function color.__wd(){
    test "$COLOR_DEBUG" = "1" && >&2 echo "DEBUG: $*"
}

# test, if given value is a known color name
# param  string  colorname to test
function color.__iscolorname(){
    test -n "${COLOR_CODE[$1]}" && return 0
    return 1
}

# test, if given value is a value 0..7
# param  string  color to test
function color.__iscolorcode(){
    test "$1" = "0" && return 0
    test "$1" = "1" && return 0
    test "$1" = "2" && return 0
    test "$1" = "3" && return 0
    test "$1" = "4" && return 0
    test "$1" = "5" && return 0
    test "$1" = "6" && return 0
    test "$1" = "7" && return 0
    return 1
}

# test, if given value is an ansi code
# param  string  color to test
function color.__iscolorvalue(){
    if grep -E "^([01];|)[34][0-7]$" >/dev/null <<< "$1" ; then
        return 0
    fi
    return 1
}

# test, if given value is an rgb hexcode eg. #80a0f0
# param  string  color to test
function color.__isrgbhex(){
    if grep -iE "^#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$" >/dev/null <<< "$1" ; then
        return 0
    fi
    return 1
}

# convert rgb hex code eg. #80a0f0 to 3 decimal values
# output us a string with space separated values for red, green, blue
# param  string  color as "#RRGGBB" to convert
function color.__getrgb(){
    local _r
    local _g
    local _b
    if color.__isrgbhex "$1"; then
        _r=$( cut -c 2,3 <<< "$1" )
        _g=$( cut -c 4,5 <<< "$1" )
        _b=$( cut -c 6,7 <<< "$1" )
        echo "$((16#$_r)) $((16#$_g)) $((16#$_b))"
    fi
}

# test, if given value is a color that can be one of
# - colorname
# - value 0..7
# - ansi code
# param  string  color to test
function color.__isacolor(){
    if color.__iscolorname "$1"; then return 0; fi
    if color.__iscolorcode "$1"; then return 0; fi
    if color.__iscolorvalue "$1"; then return 0; fi
    if color.__isrgbhex "$1"; then return 0; fi
    color.__wd "$FUNCNAME is acolor: $1 --> No"
    return 1
}

# test, if given value is an existing preset
# param  string  color to test
function color.__isapreset(){
    local _colorset
    eval "_colorset=\$COLOR_PRESET_${1}" 
    test -n "$_colorset" && return 0
    return 1
}

# respect NO_COLOR=1
# return 1 if colors are allowed to be used.
function color.__usecolor(){
    test "$NO_COLOR" = "1" && return 1
    return 0
}

# set foreground or background
# param  string  color as
#                - basic color 0..7 OR 
#                - color name eg. "black" OR 
#                - a valid color value eg. "1;30" OR 
#                - a hex code eg. "#10404f"
# param  integer what to set; '3' for for foreground or '4' for background colors
function color.__fgorbg(){
    local _color="$1"
    local _prefix="$2"
    color.__wd "$FUNCNAME $1 $2"
    if color.__iscolorname "${_color}"; then
        color.__wd "yep, ${_color} is a color name."
        test "$_prefix" = "3" && color.set "${COLOR_CODE[${_color}]}"
        test "$_prefix" = "4" && color.set "${BGCOLOR_CODE[${_color}]}"
    else
        if color.__iscolorcode "${_color}"; then
            color.__wd "yep, ${_color} is a color code."
        else
            if color.__iscolorvalue "${_color}"; then
                color.__wd "yep, ${_color} is a color value."
                color.set "${_color}"
            else
                if color.__isrgbhex "${_color}"; then
                    local _r
                    local _g
                    local _b
                    read -r _r _g _b <<< $( color.__getrgb "${_color}" )
                    color.set "${_prefix}8;2;$_r;$_g;$_b"
                else
                    >&2 echo "ERROR: color '${_color}' is not a name nor a value between 0..7 nor a valid color value nor RGB."
                fi
            fi
        fi
    fi
}

# ----------------------------------------------------------------------
# FUNCTIONS :: helpers
# ----------------------------------------------------------------------

# get count of colors in the current terminal
function color.count(){
    tput colors
}

# enable debug flag
function color.debugon(){
    COLOR_DEBUG=1
    color.__wd "$FUNCNAME - debugging is enabled now"
}

# disable debug flag
function color.debugoff(){
    color.__wd "$FUNCNAME - disabling debugging now"
    COLOR_DEBUG=0
}

# show debugging status
function color.debugstatus(){
    echo -n "INFO: color.debug - debugging is "
    if [ $COLOR_DEBUG -eq 0 ]; then
        echo "DISABLED"
    else
        echo "ENABLED"
    fi
}

# show help
function color.help(){
    local _self; _self='[path]/color.class.sh'
    color.reset
    local _debug=$COLOR_DEBUG
    COLOR_DEBUG=0

    echo "_______________________________________________________________________________"
    echo
    color.echo "red"      "   ###   ###  #      ###  ####"
    color.echo "yellow"   "  #     #   # #     #   # #   #"
    color.echo "white"    "  #     #   # #     #   # ####"
    color.echo "yellow"   "  #     #   # #     #   # #  #"
    color.echo "red"      "   ###   ###  #####  ###  #   #"
    echo "_________________________________________________________________________/ v$_VERSION"
    echo

    sed "s#^    ##g" << EOH
    HELP:
      'color' is a class like component to simplify the handling of ansi colors and keeps
      the color settings readable. A set NO_COLOR=1 will be respected.

      Author: Axel Hahn
      License: GNU GPL 3.0
      Source: <https://github.com/axelhahn/bash_colorfunctions>
      Docs: <https://www.axel-hahn.de/docs/bash_colorfunctions/>


    FUNCTIONS:

      ---------- Information:

      color.help       this help
      color.list       show a table with valid color names
      color.presets    show a table with defined custom presets

      color.count      get count of colors in the current terminal

      color.debugon    enable debugging
      color.debugoff   disable debugging
      color.debugstatus  show debugstatus

      ---------- Colored output:

      color.bg COLOR (COLOR2)
                       set a background color; a 2nd parameter is optional to set
                       a foreground color too
      color.fg COLOR (COLOR2)
                       set a foreground color; a 2nd parameter is optional to set
                       a background color too
      color.preset PRESET
                       Apply the color set of foreground and background of a given 
                       preset name.
      color.echo COLOR|PRESET (COLOR2) TEXT
                       write a colored text with carriage return and reset colors
                       The 1st param must be a COLOR(code/ name) for the 
                       foreground or a label of a preset.
                       The 2nd CAN be a color for the background, but can be 
                       skipped.
                       Everything behind is text for the output.
      color.print COLOR|PRESET (COLOR2) TEXT
                       see color.echo - the same but without carriage return.
      color.reset      reset colors
      color.set RAWCOLOR (RAWCOLOR2 (... RAWCOLOR_N))
                       set ansi colors; it can handle multiple color values


      ---------- Other:

      color.blink      start blinking text
      color.bold       start bold text
      color.invert     start inverted text
      color.underline  start underline text

    VALUES:
      COLOR            a color; it can be...
                       - a color keyword, eg black, blue, red, ... for all
                         known values run 'color.list'
                       - a value 0..7 to set basic colors 30..37 (or 40..47)
                       - an ansi color value eg. "30" or "1;42"
                       - RGB hexcode with '#' as prefix followed by 2 digit 
                         hexcode for red, green and blue eg. "#10404f" 
                         (like css rgb color codes)
      PRESET           Name of a custom preset; see DEFINE PRESETS below.
      RAWCOLOR         an ansi color value eg. "30" (black foreground) or 
                       "1;42" (lightgreen background)


    DEFINE PRESETS:
      A shortcut for a combination of foreground + background color. The label
      is part of a bash variable with the prefix 'COLOR_PRESET_'.
      The value is a bash array with 2 colors for foreground and background. 
      See the value description for COLOR above.

      SYNTAX:
      COLOR_PRESET_<LABEL>=(<FOREGROUND> <BACKGROUND>)

      To see all defined presets use 'color.presets'


    EXAMPLES:
      First you need to source the file $_self.
      . $_self

      (1)
      Show output of the command 'ls -l' in blue
        color.fg "blue"
        ls -l
        color.reset

      (2)
      show a red error message
        color.echo "red" "ERROR: Something went wrong."

      (3)
      Use a custom preset:
        COLOR_PRESET_error=("white" "red")
        color.echo "error" "ERROR: Something went wrong."

      This defines a preset named "error". "white" is a colorname
      for the foreground color, "red" ist the background.

EOH

    if [ -n "$NO_COLOR" ]; then
        echo -n "INFO: NO_COLOR=$NO_COLOR was set. The coloring functionality is "
        if ! color.__usecolor; then
            echo "DISBALED."
        else
            echo "ENABLED (must be 1 to disable)."
        fi
        echo
    else
        echo "INFO: NO_COLOR will be respected - but it is not set."
    fi

    COLOR_DEBUG=$_debug
}

# a little helper: show colors and the color codes
function color.list(){
    color.reset
    local _debug=$COLOR_DEBUG
    COLOR_DEBUG=0

    echo
    echo "List of colors:"
    echo

    echo "--------------------------------------------------"
    echo "color          | foreground         | background"
    echo "--------------------------------------------------"
    for i in "${!COLOR_CODE[@]}"
    do
        printf "%-15s %4s " $i ${COLOR_CODE[$i]} 
        color.set "${COLOR_CODE[$i]}"
        color.set "40"
        printf " Test "

        color.set "1;47"
        color.set "${COLOR_CODE[$i]}"
        printf " Test "
        color.reset

        printf "   %5s " ${BGCOLOR_CODE[$i]} 
        color.set ${BGCOLOR_CODE[$i]}
        printf " Test "
        color.reset
        echo

    done | sort
    color.reset
    echo "--------------------------------------------------"
    echo
    COLOR_DEBUG=$_debug
}

# little helper: sow defined presets and its preview
function color.presets(){
    local _label
    local _value
    local _colorvar
    local _fg
    local _bg

    color.reset
    local _debug=$COLOR_DEBUG
    COLOR_DEBUG=0

    if ! set | grep "^COLOR_PRESET_.*=(" >/dev/null; then
        echo "INFO: No preset was defined yet."
        echo "To set one define shell variables with an array of 2 colors:"
        echo "  COLOR_PRESET_<LABEL>=(<FOREGROUND> <BACKGROUND>)"
        echo "For more help call 'color.help' or see the docs."
    else
        echo
        echo "List of presets:"
        echo
        echo "---------------------------------------------------------------------"
        echo "label      | foreground   | background   | example"
        echo "---------------------------------------------------------------------"

        set | grep "^COLOR_PRESET_.*=(" | while read -r line
        do
            _label=$( cut -f 1 -d '=' <<< "$line" | cut -f 3- -d '_')
            _example=$( color.print "$_label" "example for peset '$_label'" )
            _colorvar="COLOR_PRESET_${_label}" 
            eval "_fg=\${$_colorvar[0]}"
            eval "_bg=\${$_colorvar[1]}"

            printf "%-10s | %-12s | %-12s | %-50s\n"  "$_label" "${_fg}" "${_bg}" "$_example"
        done
        echo "---------------------------------------------------------------------"
        echo
    fi
    COLOR_DEBUG=$_debug
}
# ----------------------------------------------------------------------
# FUNCTIONS :: set color
# ----------------------------------------------------------------------

# set background color
# param  string  backround color 0..7 OR color name eg "black" or a valid color value eg "1;30"
# param  string  optional: foreground color
function color.bg(){
    color.__wd "$FUNCNAME $1"
    color.__fgorbg "$1" 4
    test -n "$2" && color.fg "$2"
}

# get a color of a preset
# param  string   name of preset
# param  integer  array index; 0= foreground; 1= background
function color.__getpresetcolor(){
    local _label=$1
    local _index=$2
    local _colorvar
    _colorvar="COLOR_PRESET_${_label}" 
    eval "echo \${$_colorvar[$_index]}"
}

# set foreground color
# param  string  foreground color 0..7 OR color name eg "black" or a valid color value eg "1;30"
# param  string  optional: background color
function color.fg(){
    color.__wd "$FUNCNAME $1"
    color.__fgorbg "$1" 3
    test -n "$2" && color.bg "$2"
}


# set colors of a preset
# param  string  label of a preet
function color.preset(){
    if color.__isapreset "$1"; then
        local _colorvar
        local _colfg=$( color.__getpresetcolor "$1" 0)
        local _colbg=$( color.__getpresetcolor "$1" 1)
        color.reset
        test -n "$_colfg" && color.__fgorbg "$_colfg" 3
        test -n "$_colbg" && color.__fgorbg "$_colbg" 4
    else
        >&2 echo "ERROR: this value is not a valid preset: $1. See 'color.presets' to see current presets."
    fi
}

# ----------------------------------------------------------------------

# reset all colors to terminal default
function color.reset(){
    color.__wd "$FUNCNAME"
    color.set "0"
}

# start bold text
function color.bold(){
    color.__wd "$FUNCNAME"
    color.set "1"
}

# start underline text
function color.underline(){
    color.__wd "$FUNCNAME"
    color.set "4"
}

# start blinking text
function color.blink(){
    color.__wd "$FUNCNAME"
    color.set "5"
}

# start inverted text
function color.invert(){
    color.__wd "$FUNCNAME"
    color.set "7"
}

# ----------------------------------------------------------------------

# write ansicode to set color combination
# param  string  color 1 as ansi value
# param  string  color N as ansi value
function color.set(){
    local _out=
    if color.__usecolor; then
        for mycolor in $*
        do
            color.__wd "$FUNCNAME: processing color value '${mycolor}'"
            _out+="${mycolor}"
        done
        color.__wd "$FUNCNAME: output is '\e[${_out}m'"
        printf "\e[${_out}m"
    else
        color.__wd "$FUNCNAME: skipping - coloring is disabled."
    fi
}

# ----------------------------------------------------------------------
# FUNCTIONS :: print
# ----------------------------------------------------------------------

# show a colored text WITH carriage return
# param  string  foreground color as code / name / value
# param  string  optional: background color as code / name / value
# param  string  text to print
function color.echo(){
    color.__wd "$FUNCNAME $*"
    local _param1="$1"
    local _param2="$2"
    shift 1
    shift 1
    color.print "$_param1" "$_param2" "$*"
    echo
}

# show a colored text without carriage return
# param  string  foreground color as code / name / value or preset
# param  string  optional: background color as code / name / value
# param  string  text to print
function color.print(){
    color.__wd "$FUNCNAME $*"
    if color.__isacolor "$1"; then
        if color.__isacolor "$2"; then
            color.fg "$1" "$2"
            shift 1
            shift 1
        else
            color.fg "$1"
            shift 1
        fi
    elif color.__isapreset "$1"; then
        color.preset "$1"
        shift 1
    else
        >&2 echo -n "ERROR: Wrong color values detected. Command was: color.print $*"
    fi
    echo -n "$*"
    color.reset
}

# ======================================================================
