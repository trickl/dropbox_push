# dropbox_push

Simple script to automate pushing files onto drop box (one-way) for archival. 
-----------------------------------------------------------------------------

usage: dropbox_push.sh --from [from_dir] --to [dropbox_dir] --sync [sync_dir] --runfile [run_file]


(The sync directory can be the same as the from directory, if the from directory is writable. It CANNOT Be the dropbox directory).

WARNING: While this script should be harmless (it doesn't delete files, only excludes directories in Dropbox from syncing) - use at your own risk. 
I recommend reading the script first to understand what it does. Here is an overview.

It works on a folder by folder basis.
For each folder in the source directory, it looks for a corresponding folder in the target directory (under Dropbox).

--run_file 
   The script only runs while this file exists. The contents of this file does not matter. If the file does not eixst, it sleeps for sixty seconds then rechecks for the file existence.

WHEN RUNNING
------------
If the folder does not exist in dropbox, or the folder does exist and isn't marked as "uploaded" then it should be synchronized.
   * The folder is removed from the Dropbox folder exclusion list (if it was in it).
   * The folder is created if necessary.
   * The contents from the --from subdirectory are copied over.
   * The script waits for dropbox to complete syncing.
   * Once complete, the folder is added to the Dropbox folder exclusion list. Note this removes if from the local file system, but not Dropbox. It also still exists in the --from location.
   * The directory is marked as "uploaded".

The script continues until no folders are left.

KEEPING TRACK
-------------
The sync directory can be the same as the source directory, or a completely different tree (if the source is read only)
Note it cannot be the target directory withinDropbox, because the target directory is removed from the local file system when it is excluded
The sync directory just keeps track of which folders have been uploaded already, by placing a ".uploaded" file in the corresponding relative directory.

TRIGGERING
----------
The script is designed to work in conjunction with other scripts that can create / delete the run file.

Example usages:
   Create/Delete the run file when a memory card is inserted/removed in the system => automatically push the contents of the card onto dropbox.
   Create/Delete the run file when the screensaver is activated / deactivated => only synchronizes files when the system is otherwise "idle".

