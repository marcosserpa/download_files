
# Introduction
This script has as goal make easy to download a collection of audio files (.wav) liste as links from the web site [Spanish Audio Dictionary](http://www.elearnspanishlanguage.com/pronunciation/audiodictionary.html) (soon, the script will be more general, permitting other web sites downloads).

Thanks for [Tobias Preuus] (https://github.com/johnjohndoe) by the inspiration and base code.

# Use
To use this, simply get inside the script folder and run

	ruby download-files.rb sources.txt

The sources.txt file is the file where the sources of the files are saved. But, at the end, sources.txt has only the audio of the words that starts with the z letter, 'cause each letter iteration erases the saved sources from previous iteration.
