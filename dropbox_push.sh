#!/bin/bash
# This script should perform a one-way synchronisation with Dropbox

# Output every command to console (for debugging)
set -x

# Any subsequent commands which fail will cause the shell script to exit immediately
set -e

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -f|--from)
    FROM_DIR="$2"
    shift # past argument
    ;;
    -t|--to)
    TO_DIR="$2"
    shift # past argument
    ;;
    -s|--sync)
    SYNC_DIR="$2"
    shift # past argument
    ;;
    -r|--runfile)
    RUN_FILE="$2"
    shift # past argument
    ;;
    *)
    # unknown option
    echo "Usage: $0 --from [source_directory] --to [dropbox_directory] --sync [sync_directory]"
    exit
    ;;
esac
shift # past argument or value
done

# Validate arguments are sensible
if [[ ! -d $FROM_DIR ]] 
then
   echo --from $FROM_DIR does not exist
   exit
fi

if [[ ! -d $TO_DIR ]] 
then
   echo --to $TO_DIR does not exist
   exit
fi

if [[ ! -d $SYNC_DIR ]] 
then
   echo --sync $SYNC_DIR does not exist
   exit
fi

# Convert to absolute directories
FROM_DIR="$( cd "$FROM_DIR" && pwd )"
TO_DIR="$( cd $TO_DIR && pwd )"
SYNC_DIR="$( cd "$SYNC_DIR" && pwd )"

echo Syncing Dropbox...
echo From "${FROM_DIR}"
echo To   "${TO_DIR}"

function wait_for_dropbox() {
  until `dropbox status| grep -q "Up to date"`; do
    sleep 1
  done
}

pushd ${FROM_DIR} > /dev/null || { echo "Failed to change directory to ${FROM_DIR}" 1>&2; exit; }

while [ ! -z "${RUN_FILE}" ]
do
      # Process all folders in reverse depth order. See http://stackoverflow.com/questions/11703979/sort-files-by-depth-bash
      for FROM_SUB_DIR in `find . -mindepth 1 -type d ! \( -empty -o -iwholename '*.git*' -o -iwholename '*@eaDir*' \) -print | perl -n -e '$x = $_; $x =~ tr%/%%cd; print length($x), " $_";' | sort -k 1,1 -r | sed 's/^[0-9][0-9]* //'`
      do
         while [ ! -f $RUN_FILE -o -z $FROM_SUB_DIR ]
         do 
            sleep 60
         done 

         # TODO order the processing according to age of folder?
         TO_SUB_DIR=`echo ${TO_DIR}/${FROM_SUB_DIR}`
         SYNC_SUB_DIR=`echo ${SYNC_DIR}/${FROM_SUB_DIR}`
         echo -n "Synchronising ${FROM_SUB_DIR}... "

         [[ -d ${SYNC_SUB_DIR} ]] || mkdir -p ${SYNC_SUB_DIR}

         if [[ ! -f ${SYNC_SUB_DIR}/.uploaded ]]
         then
            # Allow synchronisation (allows users to manually remove the marker flag to force a resync).
            [[ -d ${TO_SUB_DIR} ]]  || dropbox exclude remove ${TO_SUB_DIR} | grep "excluded" || mkdir -p ${TO_SUB_DIR}

            # Wait for dropbox
            wait_for_dropbox
         
            # Copy files
            pushd ${FROM_SUB_DIR} > /dev/null || { echo "Failed to change directory to ${FROM_SUB_DIR}" 1>&2; exit; }

            # If the directory is not empty copy all the files over
            [[ $( ls -A . )$ ]] &&  find . -mindepth 1 -maxdepth 1 -type f -exec rsync -a -v -q --ignore-existing --timeout 600 {} ${TO_SUB_DIR}/{} \;

            # Wait for dropbox
            wait_for_dropbox

            # Stop synchronisation
            dropbox exclude add ${TO_SUB_DIR} | grep "excluded" && touch ${SYNC_SUB_DIR}/.uploaded

            popd > /dev/null

         fi

         echo "completed."
      done

      echo "Everything is synchronized. Sleeping for five minutes."
      sleep 300
done

popd > /dev/null

