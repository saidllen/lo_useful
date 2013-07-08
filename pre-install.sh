#!/bin/bash

###
### README
###
### Script.....: pre-install.sh
### Description: Prepare linux systems Debian or RedHat based for the
###              LibreOffice compilation process. Options for dependencies
###              install and clone the source (standard), or just dependencies
###              install.

### LICENSE
### This program is free software: you can redistribute it and/or modify
### it under the terms of the GNU General Public License as published by
### the Free Software Foundation.
###
### This program is distributed in the hope that it will be useful,
### but WITHOUT ANY WARRANTY; without even the implied warranty of
### MERCHANTABILITY of FITNESS FOR A PARTICULAR PURPOSE. See the
### GNU General Public License for more details.
### http://www.gnu.org/licenses

###
### Authors
### - Marcos Paulo de Souza ..(marcos.souza.org [at] gmail.com)
### - Ricardo Montania .......(ricardo.montania [at] gmail.com)
### Testers
### - Marcos Paulo de Souza ..(marcos.souza.org [at] gmail.com)
### - Jose Guilherme Vanz ....(guilherme.sft [at] gmail.com)
###

usageSyntax()
{
    echo " "
    echo "Usage:"
    echo " "
    echo "bash pre-install.sh [option]"
    echo " "

    echo "Options:"
    echo " "
    echo " --dir [/some/folder/]    - Dep install and clone in /some/folder/"
    echo "                          - If no dir was informed, whill be installed" 
    echo "                            the deps and git clone in $HOME/libo/ folder"
    echo " --no-clone               - Only dep install, don't clone"
    echo " --ccache                 - Install ccache. It speeds up recompilation by"
    echo "                            caching previous compilations and detecting when"
    echo "                            the same compilation is being done again"
    echo " --help                   - Show this help message"
    echo " "
}

gitClone()
{
    if $noclone; then
        exit
    fi
	
    if [ "$clonedir" == "" ]; then
        cd $HOME
        git clone git://anongit.freedesktop.org/libreoffice/core libo && echo " " && "Success!"
        exit
    fi

    # Uses the directory informed.
    if [ -d "$clonedir" ]; then
        cd "$clonedir"
        git clone git://anongit.freedesktop.org/libreoffice/core libo && echo " " && "Success!"
        exit
    else
        # If not exists, try create.
        mkdir -p $clonedir
        if [ -d "$clonedir" ]; then
            cd "$clonedir"
            git clone git://anongit.freedesktop.org/libreoffice/core libo && echo " " && "Success!"
            exit
        else
            echo "Unable to create '$clonedir' folder"
            exit
        fi
    fi
}

debianInstall()
{
    echo "Dep install for Debian/Ubuntu"
    echo " "
    sudo apt-get update

    if $inccache; then
        sudo apt-get install ccache
    fi

    sudo apt-get build-dep libreoffice -y
    sudo apt-get install git-core libgnomeui-dev gawk junit4 doxygen libgstreamer0.10-dev -y
}

fedoraInstall()
{
    echo "Dep install for Fedora"
    echo " "
    sudo yum update
	
    if $inccache; then
        sudo yum install ccache
    fi

    sudo yum-builddep libreoffice -y
    sudo yum install git libgnomeui-devel gawk junit doxygen perl-Archive-Zip Cython python-devel -y
}

suseInstall()
{
    echo " "
    echo "1. 11.4"
    echo "2. 12.1"
    echo "3. 12.2"
    echo "4. 12.3"
    echo " "
    read -p "Select your SUSE version: " version

    case $version in
        1) vername="11.4";;
        2) vername="12.1";;
        3) vername="12.2";;
        4) vername="12.3";;
        *) echo "Sorry, invalid option!"; exit;;
    esac

    echo " "
    echo "1. 32 bits"
    echo "2. 64 bits"
    echo " "
    read -p "Select your system type: " systype

    case $systype in
        1) sysname="32 bits";;
        2) sysname="64 bits";;
        *) echo "Sorry, invalid option!"; exit;;
    esac
    
    echo " "
    echo "Dep install for openSUSE" $vername $sysname
    echo "If you receive a question to answer [yes or no], please, read carrefully."
    echo "Maybe root's password will be asked more than once."
    echo " "	

    sudo zypper refresh
    sudo zypper update
    sudo zypper in java-1_7_0-openjdk-devel # gcj is installed by default but it does not work reasonably.
    
    if $inccache; then
        sudo zypper in ccache
    fi

    if [$systype == 1]; then
        sudo zypper in krb5-devel-32bits
    else
        sudo zypper in krb5-devel
    fi	
	
    sudo zypper mr --enable "openSUSE-$vername-Source" # Enable te repo to download the source.
    sudo zypper si -d libreoffice # For OpenSUSE 11.4+ (was OpenOffice_org-bootstrap)
    sudo zypper in git libgnomeui-devel gawk junit doxygen
}

showDestination()
{
    if [ "$clonedir" == "" ]; then
        echo "Path (absolute) for the folder where will be cloned the libo repository: '$HOME'"; echo " "
    elif [ "$clonedir" == "--no-clone" ]; then
        echo "Chosen option for don't clone!"; echo " "
    else
        echo "Path (absolute) for the folder where will be cloned the libo repository: '$clonedir'"; echo " "
    fi
}

distroChoice()
{
    echo "1. Debian/Ubuntu"
    echo "2. Fedora"
    echo "3. openSUSE"
    echo "4. Other linux"
    echo " "

    read -p "Choice your distro: " distro

    case $distro in
        1) debianInstall;;
        2) fedoraInstall;;
        3) suseInstall;;
        4) echo "Please, follow the instructions in \"http://www.libreoffice.org/developers-2\" to configure you system or contact us."; exit;;
        *) echo "Sorry, invalid option!"; exit;;
    esac
}

cloneSyntaxError()
{
    echo "Syntax error. Cannot use --no-clone and --dir together."
    usageSyntax
    exit
}

inccache=false
noclone=false
clonedir=""

###
### Check input parameters.
###
while [ $# -ne 0 ]
do
    case $1 in
        "--help") usageSyntax; exit;;
        "--ccache") inccache=true;;
        "--no-clone")
            if [ "$clonedir" != "" ]; then
                cloneSyntaxError
            fi 
            noclone=true;;
        "--dir")		
            if $noclone; then
                cloneSyntaxError
            fi

            # Get dir name.
            shift
            clonedir=$1

            dr=${clonedir:0:1}
            # Need a name before the next parameter.
            if [ "$dr" == "-" ]; then
                echo "Syntax error. Invalid directory \"$clonedir\"."; exit
            fi
            ;;
        *) echo "Syntax error. Invalid parameter \"$1\"."; usageSyntax; exit;;
    esac
    # Next parameter.
    shift
done

clear
echo "Script for dependencies installation to compile LibreOffice."
showDestination;
distroChoice;
gitClone;
