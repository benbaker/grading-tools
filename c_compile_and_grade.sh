#!/bin/sh
# ------------------------------------------------------------------------------
# Quickly compile and run code for grading.
# ------------------------------------------------------------------------------

usage()
{
echo "\033[33m\ncs_grade!\033[0m"
echo "\033[30mA tool for quickly grading entry level computer science class assignments."
echo "example: $0 -c 'g++ -fast' -t './mul 2 3' hw1/abc123\033[0m"  

cat << EOF

usage:   $0 [options] <target>

 OPTIONS:
   -h      Shows this helpful message.
   -c      Compile directions [ default: gcc    ]
   -t      Target directory   [ default ./ ]
   -r      Run command        [ default ./a.out ]

EOF
}

FROM_DIR="$(pwd)";
LATEST="";


TARGET=
COMPILE=
TEST_CMD=
VERBOSE=
while getopts â€œh:t:c:g:vâ€ OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         t)
             TARGET=$OPTARG
             echo "Targeting: $OPTARG"
             ;;
         c)
             COMPILE=$OPTARG
             echo "Compiling with: $OPTARG"
             ;;
         g)
             TEST_CMD=$OPTARG
             echo "Testing with: $OPTARG"
             ;;
         ?)
             # usage
             ;;
     esac
done

# ------------------------------------------------------------------------------
# Navigate to a space, compile the things, run a test, and return.
# ------------------------------------------------------------------------------

main(){
  gothere
  situate
  compile
  runtest
  goback
}

gothere(){
  FROM_DIR="$(pwd)"
  cd $TARGET
}

situate(){
  LATEST=$(findnew)
  echo "Grading: $green$TARGET"
  echo $dim$line1$none
  echo "From:    $dim$FROM_DIR$none"
  echo "Compile: $dim$COMPILE$none"
  echo "Test:    $dim$TEST_CMD$none"
  echo "\nLatest submission: \033[33m$LATEST\033[0m"
}

findnew(){
  LATEST=$(ls *.c | sort -t _ -k 2 | tail -1)
  echo $LATEST
}

goback(){
  cd $FROM_DIR
}

# ------------------------------------------------------------------------------
# Compile code with specified compile command
# ------------------------------------------------------------------------------

compile(){
  echo "$red"
  echo "Compiling..."
  echo $line1$none
  $COMPILE $LATEST
  echo $red$line1 $none
}

# ------------------------------------------------------------------------------
# Try to run_test a.out
# ------------------------------------------------------------------------------

runtest(){
  echo "$blue"
  echo "Testing..."
  echo $line1 $none
  $TEST_CMD 
  echo $blue$line2$none
}

# ------------------------------------------------------------------------------
# Show a menu and get some user input
# ------------------------------------------------------------------------------

showMenu(){
  title="Grading Menu"
  prompt="View their code?"
  options=("Y" "Yes" "yes")

  echo "$title"
  PS3="$prompt "
  select opt in "${options[@]}" "Quit"; do 
    case "$REPLY" in

    1 ) echo "You picked $opt which is option $REPLY";;

    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;
    esac
  done
}


# ------------------------------------------------------------------------------
# Walk a director and do something to each thing in there.
# ------------------------------------------------------------------------------

each() {
    for dir in */; do
       $1 $dir
    done
}

# ------------------------------------------------------------------------------
# Get the latest submission as defined by version
# Like this: *****_v1*****.c, *****_v2*****.c
# ------------------------------------------------------------------------------

LATEST(){
  ls *.c | sort -t _ -k 2 | tail -1
}

# ------------------------------------------------------------------------------
# Print the usage menu
# ------------------------------------------------------------------------------

help(){
  usage
}

# ------------------------------------------------------------------------------
# Various aesthetic tools and utilities
# ------------------------------------------------------------------------------

red="\033[31m"
yellow="\033[32m"
green="\033[33m"
blue="\033[34m"
dim="\033[30m"
none="\033[0m"

line1="--------------------------------------------------------------------------------"
line2="--------------------------------------------------------------------------------"

hr(){
  echo "--------------------------------------------------------------------------------"
}
br(){
  echo "\n"
}

clear
br

# ------------------------------------------------------------------------------
# Args checker and dispatcher
# ------------------------------------------------------------------------------

if [ ! $1 ]; then
  help;
else main $@
fi





# COLORS

# Black        0;30     Dark Gray     1;30
# Blue         0;34     Light Blue    1;34
# Green        0;32     Light Green   1;32
# Cyan         0;36     Light Cyan    1;36
# Red          0;31     Light Red     1;31
# Purple       0;35     Light Purple  1;35
# Brown/Orange 0;33     Yellow        1;33
# Light Gray   0;37     White         1;37


