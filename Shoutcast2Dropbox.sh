#!/bin/sh
VERSION=0.1
#Path to dropbox uploader script. Change this to the correct/absolute path according to how you installed Shoutcast2Dropbox and Dropbox Uploader
DROPBOX_UPLOADER="./Dropbox-Uploader/dropbox_uploader.sh"

#Usage
if [ "$#" != 3 ]; then
  echo "Shoutcast2Dropbox Playlist Maker v$VERSION - Shantanu Goel\n"
  echo "https://github.com/shantanugoel/Shoutcast2Dropbox\n"
  echo "Usage: $0 <Input File for station lists> <Cumulative Duration to record in seconds> <Output Directory path>\n"
  echo "Input file should have 1 station url per line\n"
  exit 1
fi

#Arguments
input_file=$1                #script argument 1
total_duration_in_seconds=$2 #script argument 2
output_dir=$3                #script argument 3

#Other variables
num_stations=`wc -l $input_file | cut -f1 -d' '`
duration_per_station=$(($total_duration_in_seconds / $num_stations))

#script starts

#Delete existing songs from last run
#Still playing a little safe and deleting mp3/aac files instead of everything. If your station broadcasts in another format, add that here
$DROPBOX_UPLOADER -q delete $output_dir/*.aac
$DROPBOX_UPLOADER -q delete $output_dir/*.mp3
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
ls $output_dir
$DROPBOX_UPLOADER -q -s upload $output_dir .
