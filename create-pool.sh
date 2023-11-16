#!/bin/bash

increment_hex() {
	local input_hex="$1"
	local hex

	if [[ "$input_hex" == 0x* ]]; then
		hex="${input_hex#0x}"
	else
		hex="$input_hex"
	fi
  # Use Python for hexadecimal to decimal conversion and increment
  decimal=$(python3 -c "print(int('0x$hex', 16) + 1)")

  # Convert the decimal value back to hexadecimal using Python
  hex=$(python3 -c "print(hex($decimal))")

  # Print the incremented hexadecimal value
  echo "$hex"
}

show_help() {
  echo "Usage: bash create-pools.sh [OPTIONS]"
  echo "Automate pool creation with specified settings."

  echo "Options:"
  echo "  --leb NUMBER    Set the leb value (default: 8, must be 8 or 16)."
  echo "  --amount NUMBER Specify the amount of pools to create (required)."
  echo "  --prefix HEX    Set the hexadecimal prefix value for minipools (without 0x, default: empty)."
  echo "  --salt HEX      Set the initial salt value for prefix matching (without 0x, default: empty)."
  echo "  --help          Display this help message and exit."

  exit 0
}
# ARG_AMOUNT=$#
# echo $ARG_AMOUNT
PREFIX=
AMOUNT=0
LEB=8
SALT=
# Parse command-line options and arguments
while [ $# -gt 0 ]; do
	case "$1" in
		--leb)
			LEB=$2
			if [[ $LEB != 8 && $LEB != 16 ]]; then
				echo "Error: leb must be either 8 or 16."
				exit 1
			fi
			shift 2
			;;
		--pool-amount)
			AMOUNT=$2
			shift 2
			;;
		--salt)
			SALT=$2
			if ! [[ $SALT =~ ^[0-9A-Fa-f]{1,}$ ]] ; then
				echo "Error: salt is not hex"
				exit 1
			fi
			shift 2
			;;
		--prefix)
			PREFIX=$2
			if ! [[ $PREFIX =~ ^[0-9A-Fa-f]{1,}$ ]] ; then
				echo "Error: prefix is not hex"
				exit 1
			fi
			shift 2
			;;
		--help)
			show_help
			exit 1
			;;
		*)
			echo "Invalid option: $1. Use --help for usage information." >&2
			exit 1
			;;
	esac
done

if [ $AMOUNT -lt 0 ]; then
	echo "Error: Pool amount must be specified or superior to 0."
	exit 1
fi

i=0
SALT="0x"$SALT
while [ $i -ne $AMOUNT ]
do
	if [ -z "$PREFIX" ]
	then
		rocketpool n d -a $LEB -y
	else
		if [ -z "$SALT" ]
		then
			echo "Error: Salt empty when prefix was provided"
			exit 1
		else
			SALT=$(rocketpool minipool find-vanity-address -p 0xbee -a 8 -s "$SALT" | sed -n '3 p' | cut -d " " -f 6)
			echo "Prefix of $PREFIX with salt $SALT"
			rocketpool n d -a $LEB -y --salt $SALT
			SALT=$(increment_hex "$SALT")
		fi
	fi
	i=$(($i+1))
done
