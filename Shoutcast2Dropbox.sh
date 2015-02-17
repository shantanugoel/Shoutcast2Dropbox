#!/bin/sh
VERSION=0.1
#Path to dropbox uploader script. Change this to the correct/absolute path according to how you installed Shoutcast2Dropbox and Dropbox Uploader
DROPBOX_UPLOADER="./Dropbox-Uploader/dropbox_uploader.sh"

#Usage
if [ "$#" != 3 ] && [ "$#" != 4 ]; then
  echo "Shoutcast2Dropbox Playlist Maker v$VERSION - Shantanu Goel\n"
  echo "https://github.com/shantanugoel/Shoutcast2Dropbox\n"
  echo "Usage: $0 <Input File for station lists> <Cumulative Duration to record in seconds> <Output Directory path> [OPTIONS]\n"
  echo "Input file should have 1 station url per line\n"
  echo "Options:"
  echo "-m -> Move, not delete. This option will move previous run songs to a folder named \"old\" in Dropbox instead of deleting them. Local files are still deleted\n"
  exit 1
fi

#Arguments
input_file=$1                #script argument 1
total_duration_in_seconds=$2 #script argument 2
output_dir=$3                #script argument 3
option=$4                    #script argument 4

#Other variables
num_stations=`wc -l $input_file | cut -f1 -d' '`
duration_per_station=$(($total_duration_in_seconds / $num_stations))

#script starts

if [ "$option" = "-m" ]; then
  #Move existing songs to another folder on dropbox. Locally they are still deleted
  #Dropbox path is relative from sandbox root
  $DROPBOX_UPLOADER -q move `basename $output_dir` old
else
  #Delete existing songs from last run
  #Dropbox path is relative from sandbox root
  $DROPBOX_UPLOADER -q delete `basename $output_dir`
fi
#Still playing a little safe and deleting mp3/aac files instead of everything. If your station broadcasts in another format, add that here
rm -f $output_dir/*.aac
rm -f $output_dir/*.mp3

#Start station recording
#Each station gets captured simultaneously in a background job
while read station
do
  (streamripper $station -s -l $duration_per_station -d $output_dir --quiet) &
done < $input_file

#Wait for all jobs to complete
wait

#Delete the incomplete songs
rm -rf $output_dir/incomplete

#Upload the new songs
$DROPBOX_UPLOADER -q -s upload $output_dir /
