#!/bin/bash
#
# Handle setup of bash shell for users
#
# Call like:
#
# bash /home/mph0043_lab/software/config_bash.sh
# logout
#

user=$(whoami)
groupdir=/home/shared/mph0043_lab

# make a backup of system .bashrc
if [ ! -f "$HOME/.bashrc.bak" ]
then
    cp $HOME/.bashrc $HOME/.bashrc.bak
fi

# add group modules and environment vars to bashrc
cat << EOF >> $HOME/.bashrc
module load git
module use $groupdir/software/modulefiles

export GROUP=$groupdir
export SCRATCH=/scratch/$user
shopt | grep -q '^direxpand\b' && shopt -s direxpand
EOF

# copy vimrc for user
cp $groupdir/software/config/.vimrc $HOME/

# make the scratch directory
mkdir -p /scratch/$user

echo "Log out and back in for these changes to take effect."
