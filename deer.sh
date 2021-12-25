#!/bin/bash

if [[ "$#" == "0" || ("$#" == "1" && ("$1" == "help" || "$1" == "-h")) ]]; then
	echo "
Usage:	deer [OPTIONS]

Lightweight deploy manager to create, run and manage executable tarballs for any software

Options:
     
  <repo>           	    Download, extract, make executable and run the repo
  <repo> to <dir>  	    Download, extract, make executable and run the repo to the specified <dir>
  pull <repo>               Get a fresh artifact from the cloud and then download, extract, make executable and run the repo
  help, -h     	            Show this help info
  ls, -l   	            List all the available/downloaded deer files on the local machine
  ps     	            List downloaded repo's and display which processes are currently running
  update, upgrade           Update deer to the latest version
  safemode                  Display whether safemode is on or off
      	                    Safemode only allows you to download and execute repo's made with your own deer id. When safemode is on, deer id must be set. 
                            To download and execute any public repo, turn safemode off: deer safemode off
  id                        Display the currently set deer id (given on the deer cloud: https://deercore.org)
                            Deer id is mainly needed to push repo's to the deer cloud, but also to read and execute repo's when safemode is on. Set deer id: deer id <myDeerId>
  uninstall                 Uninstall deer
  herd <repo>               Deploy multiple deer files structured by a herd file
  herd -f <herdFile.herd>   Deploy multiple deer files given by the herd file on the local machine
  push <repo>               Pack all the files in the current directory and push it to the deer cloud. Make sure to either specify a run.sh file or a <repo>.herd file
  clean                     Delete all downloaded repo's on the local machine
  rm <repo>                 Delete the specified repo from the local machine
  logs <repo>               Print all the logs of the repo
  logs -f <repo>            Tail and follow the new logs of the repo
  start <repo>              Download, extract, make executable and run the repo
  restart <repo>            First stop the running repo instance, then start it again
  stop <repo>               Stop the running repo instance
  add <file> <repo>:<path>  Add <file> to a repo on path <path>
  version, -v               Print version information
  create <path>             Create a deer repo, this will automatically copy your binaries from <path>
  build <path>              Build/update a deer repo, this will automatically copy your binaries from <path>

Examples: 
  
  * Create repo from directory <dir>:
       cd <dir>
       deer push <dir>

  * Create repo from deer (have your binaries ready in <dir>/<path>):
       cd <dir>
       deer create <path>

  * Run repo:
       deer <repo>

  * Download and run repo to <anotherDir>:
       deer <repo> to <anotherDir>

  * Deploy multiple deer files in a herd from a file:
       deer herd -f <myHerd.herd>
"
	exit 2
fi

VERSION="1.2.25"

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

deerId=""
if [ -f "$HOME/.deer/deerId.conf" ]; then
	read -r deerId < "$HOME/.deer/deerId.conf"
fi

if [[ "$1" == "update" || "$1" == "upgrade" ]]; then
	cd /tmp
	sudo wget -q "https://deercore.org/install.tar.gz" -O deer.tar.gz
	sudo tar -xf deer.tar.gz
	sudo rm -f deer.tar.gz
	
	vc=$(grep "$VERSION" deer.sh -c)
	if [ "$vc" -eq 1 ]; then
		echo "Latest version is already installed"
		exit 0
	fi
	sudo chmod +x run.sh
	sudo bash run.sh $USER
	#sudo rm run.sh
	echo "Successfully upgraded deer"
	exit 0
fi

if [[ "$1" == "version" || "$1" == "-v" ]]; then
	echo "Deer version: $VERSION"
	exit 0
fi

if [[ "$1" == "ps" ]]; then
	repos=$(ls -1 "$HOME/.deer" -I "*.conf" | grep -v herd)
	for repo in $repos; do 
		pidc=$(ps -ef | grep "run.$repo" -c)
		if [[ $pidc == "1" ]]; then
			echo "$repo ${red}stopped${reset}"
		else
			echo "$repo ${green}running${reset}"
		fi
	done
	exit 0
fi

if [[ "$1" == "ls" || "$1" == "-l" ]]; then
	ls -1 "$HOME/.deer" -I "*.conf"
	exit 0
fi

if [[ "$1" == "safemode" ]]; then

	#check if arguments, otherwise show current value
	if [[ "$#" == "1" ]]; then
		if [ ! -f "$HOME/.deer/safemode.conf" ]; then
			bash -c "echo 'on' > $HOME/.deer/safemode.conf"
		fi
		read -r safeMode < "$HOME/.deer/safemode.conf"
		echo "Safemode is $safeMode"
		exit 0
	fi

	#check if values is only on or off
	if [[ "$2" != "off" && "$2" != "on" ]]; then
		echo "Safemode can only be set to 'off' or 'on'"
		exit 2
	fi

	#check if deer data dir exists
	if [ ! -d "$HOME/.deer" ]; then
		mkdir "$HOME/.deer"
	fi

	bash -c "echo '$2' > $HOME/.deer/safemode.conf"
	exit 0
fi

if [[ "$1" == "herd" && (("$#" == "3" && "$2" == "-f") || ("$#" == "2")) ]]; then
	herdFile="$3"
	if [[ "$#" == "2" ]]; then
		if ! deer "$2"
		then
			echo "Herd file does not exist"
			exit 2
		fi
		herdFile="$HOME/.deer/$2/$2.herd"
	fi

	finishOffEnvDeer() {
		deerName=$1
		deerRepo=$2
		if [[ "$deerName" != "" ]]; then
			if [[ "$deerRepo" == "$deerName" ]]; then
				deer "$deerRepo" &
			else
				if [ ! -d "$HOME/.deer/$deerName" ]; then
					mkdir -p "$HOME/.deer/$deerName"
				fi
				mv tmp.prop "$HOME/.deer/$deerName"
				deer "$deerRepo" --config "$deerName"
				deer "$deerName" &
			fi
		fi
	}

	echo "Reading herd file"
	deerRepo=""
	deerName=""
	servicesBegun=false
	bash -c "echo '' > tmp.prop"
	while IFS= read -r line
	do
		if [[ "$servicesBegun" == false && "$line" == *"services"* ]]; then
			servicesBegun=true
		fi
		if [[ "$servicesBegun" == true && "$line" != *"services"* && "$line" != *"+"* && "$line" == *"-"* ]]; then

			#finish off previous deer and run it
			finishOffEnvDeer $deerName $deerRepo

			repoLine=$(echo "$line" | xargs | cut -c 2- | cut -d ":" -f1)
			deerName=$(echo "$repoLine" | cut -d "/" -f1 | xargs)
			deerRepo=$(echo "$repoLine" | cut -d "/" -f2 | xargs)
		fi
		if [[ "$servicesBegun" == true && "$line" == *"+"* && "$deerName" != "" ]]; then
			propLine=$(echo "$line" | cut -d '+' -f2)
			propArg=$(echo "$propLine" | cut -d ':' -f1 | xargs)
			propVal=$(echo "$propLine" | cut -d ':' -f2 | xargs)
			bash -c "echo '$propArg=$propVal' >> tmp.prop"
		fi
	done < "$herdFile"

	#finish off previous deer and run it
	finishOffEnvDeer $deerName $deerRepo

	exit 0

fi

if [[ "$1" == "uninstall" ]]; then
	echo "Uninstalling deer $VERSION"
	sudo rm -f /usr/lib/deer.sh
	sudo rm -f /usr/bin/deer.sh
	sudo rm -f /usr/bin/deer
	sudo service deerd stop
	sudo systemctl disable deerd
	sudo rm -f /etc/systemd/system/deerd.service
	sudo rm -f /srv/deerd/deerDaemon.sh
	sudo rmdir /srv/deerd

	cd
	if [ -d ".deer" ]; then
		cd ".deer"
		rm -rf *
		cd ..
		rmdir ".deer"
	fi
	echo "Deer is successfully uninstalled"
	exit 0
fi

#clean deer data dir
if [[ "$1" == "clean" ]]; then
	mem="0 bytes"
	if [ -d "$HOME/.deer" ]; then
		cd "$HOME/.deer"
		mem=$(du -sh | cut -d '.' -f1)
		mv *.conf ../.
		rm -rf *
		mv "../deerId.conf" "../safemode.conf" .
	fi
	echo "Recovered space: $mem"
	exit 0
fi

#remove <repo>: deer rm <repo>
if [[ "$1" == "rm" ]]; then
	if [[ ! "$#" == "2" ]]; then
		echo "No repo specified to remove. To list all downloaded repo's, run: deer ls"
		exit 2
	fi
	if [ -d "$HOME/.deer/$2" ]; then
		cd "$HOME/.deer/$2"
		rm -rf *
		cd ..
		rmdir "$2"
	fi
	echo "Removed $2"
	exit 0
fi

#deer id
if [[ "$1" == "id" ]]; then

	#set deer id
	if [ "$#" -eq 2 ]; then
		if [ ! -d "$HOME/.deer" ]; then
			mkdir "$HOME/.deer"
		fi
		bash -c "echo $2 > $HOME/.deer/deerId.conf"
	fi

	#show deer id
	#check if id exists
	if [ ! -f "$HOME/.deer/deerId.conf" ]; then
		echo "No deer id has been set. Run: deer id <myDeerId>"
		exit 2
	fi

	read -r deerId < "$HOME/.deer/deerId.conf"
	echo "Deer id: $deerId"
	exit 0
fi

if [[ "$1" == "push" ]]; then
	dirname=$(pwd)
	result="${dirname%"${dirname##*[!/]}"}" # extglob-free multi-trailing-/ trim
	dir="${result##*/}"      
	if [[ "$#" -eq 2 ]]; then
		dir="$2"
	fi
	echo "Pushing $dir to the deer cloud"
	if [[ ! -f "deer.yml" && ! -f "$dir.herd" ]]; then
		echo "No runnable deer file and/or herd file found. Add deer.yml to make an executable deer file or $dir.herd to compile a herd of deer files."
		exit 2
	fi
	if [ ! -f "$HOME/.deer/deerId.conf" ]; then
		echo "No deer id has been set. Run: deer id <myDeerId>"
		exit 2
	fi
	moved=false
	if [ -f "deer.yml" ]; then
		bash -c "echo '#!/bin/bash' > run.$dir.sh"
		bash -c "echo 'if [[ \"\$#\" -eq 2 && \"\$1\" == \"-c\" ]]; then conf=\"config=\$2\"; else conf=\"\"; fi' >> run.$dir.sh"
		prerunBegun=false
		runBegun=false
		while IFS= read -r line
		do
			if [[ "$line" != *"#"* ]]; then
				if [[ "$runBegun" == true && "$line" == *"-"* ]]; then
					#add runnable command line
					line=$(echo "$line" | xargs | cut -c 2-)
					if [[ "$line" == *"java"* ]]; then
						bash -c "echo 'if [[ \"\$conf\" != \"\" ]]; then conf=\"--spring.config.location=\$2\"; fi' >> run.$dir.sh"
						bash -c "echo '$line \"\$conf\" &' >> run.$dir.sh"
					else
						bash -c "echo '$line \"\$conf\" &' >> run.$dir.sh"
					fi
					bash -c "echo 'echo \$! >> running.pid' >> run.$dir.sh"
				fi
				if [[ "$prerunBegun" == true && "$line" == *"-"* ]]; then
					#add prerun step
					line=$(echo "$line" | xargs | cut -c 2-)
					bash -c "echo '$line' >> prerun.$dir.sh"
				fi
				if [[ "$runBegun" == false && "$line" == "run:"* ]]; then
					runBegun=true
					prerunBegun=false
				fi
				if [[ "$prerunBegun" == false && "$line" == "prerun:"* ]]; then
					prerunBegun=true
					runBegun=false
					bash -c "echo '#!/bin/bash' > prerun.$dir.sh"
				fi
			fi
		done < "deer.yml"
		bash -c "echo 'while true; do sleep 10; done' >> run.$dir.sh"
		moved=true
	fi
	tar --exclude="$dir.tar.gz" -czf "$dir.tar.gz" *
	read -r deerId < "$HOME/.deer/deerId.conf"

	#split file in chunks of 100MB for upload
	mkdir tmp
	mv "$dir.tar.gz" tmp/.
	cd tmp
	checksum=$(md5sum "$dir.tar.gz" | cut -d ' ' -f1)
	split -l 500000 "$dir.tar.gz"
	rm -f "$dir.tar.gz"
	order=0
	for chunk in *; do
		uploadResponse=$(curl -L -F "deerified=@$chunk" -F "deerId=$deerId" -F "repoName=$dir.tar.gz" -F "order=$order" -F "runnable=$moved" -F "checksum=$checksum" https://deercore.org/upload.php)
		echo "$uploadResponse" | cut -d ':' -f2 | cut -d '"' -f2
		order=$((order+1))
	done
	rm -rf *
	cd ..
	rmdir tmp
	if [[ "$moved" == true ]]; then
		rm -f "run.$dir.sh"
		[ -f "prerun.$dir.sh" ] && rm -f "prerun.$dir.sh"
	fi
	exit 0
fi

if [[ "$1" == "stop" && "$#" -gt 1 ]]; then
	for var in "$@"
	do
		if [[ "$var" != "stop" ]]; then
			cd "$HOME/.deer/$var"
			[ -f running.pid ] && kill -9 `cat running.pid` 2> /dev/null
			[ -f running.pid ] && rm -f running.pid
			kill -9 $(pgrep -f "run.$var") 2> /dev/null
		fi
	done
	exit 0
fi

if [[ "$1" == "add" && "$#" == "3" ]]; then
	IFS=':' read -ra dest <<< "$3"
	dir="${dest[0]}"
	path="${dest[1]}"
	cp "$2"	"$HOME/.deer/$dir/$path"
	exit 0
fi

if [[ "$1" == "logs" && ( "$#" == "2" || "$#" == "3" ) ]]; then
	follow=false
	dir=$2
	if [[ "$#" == "3" && "$2" == "-f" ]]; then
		dir=$3
		follow=true
	fi
	if [ -f "$HOME/.deer/$dir/deerLog.log" ]; then
		if [ "$follow" == true ]; then
			tail -f "$HOME/.deer/$dir/deerLog.log"
		else
			cat "$HOME/.deer/$dir/deerLog.log"
		fi
	fi
	exit 0
fi

if [[ "$1" == "search" && "$#" == "2" ]]; then
	hostname=$(hostname)
	resp=$(curl -s -L "https://deercore.org/api.php?action=search&hostname=$hostname&deerId=$deerId&repos=$2")
	echo $resp | cut -d ':' -f2 | cut -d '"' -f2 | sed 's/\\n/\n /g' | sed 's/\\//g'
	exit 0
fi

# create or build/update a deer repo
if [[ ("$1" == "create" || "$1" == "build" ) && "$#" -gt 1 ]]; then
	if [[ "$1" == "create" ]]; then
		echo "Creating deer space"
		mkdir deer
	fi
	cd deer
	binaries=$(find "../$2/" -maxdepth 1 -type f | grep -v \.original)
    cp "../$2/$binaries" .
	if [[ "$1" == "create" ]]; then
		echo "# Example of a deer run file. This will run any jar file present in the repo
run:
	- java -jar *" > deer.yml
		echo "Deer repo created in ./deer, next steps:"
		echo " * edit deer.yml" 
		echo " * push your repo: deer push <myRepo>"
		exit 0
	fi
	echo "Deer repo built in ./deer"
	exit 0
fi

if [[ ( "$#" == "1" ) && ( "$1" == "push" || "$1" == "herd" || "$1" == "pull" || "$1" == "stop" || "$1" == "restart" || "$1" == "logs" || "$1" == "add" || "$1" == "search" || "$1" == "create" ) ]]; then
	echo "No decent repo mentioned"
	exit 0
fi

#do actual DEER stuff

created=false
norun=false
repo=$1
#check if repo needs to be freshly downloaded: deer pull <repo>
if [[ "$1" == "pull" && "$#" == "2" ]]; then
	created=true
	repo=$2
fi

if [[ "$1" == "start" && "$#" == "2" ]]; then
	repo=$2
fi

if [[ "$1" == "restart" && "$#" -eq 2 ]]; then
	cd "$HOME/.deer/$2"
	kill -9 `cat running.pid` 2> /dev/null
	[ -f running.pid ] && rm -f running.pid
	kill -9 $(pgrep -f "run.$2") 2> /dev/null
	repo=$2
fi

#check if pattern: deer <repo> to <dir>
if [[ "$#" -eq 3 && "$2" == "to" ]]; then
	echo "[$repo] Pulling repo to dir $3"
	#check if dir exists
	if [ ! -d "$3" ]; then
		echo "[$repo] Creating dir $3"
		mkdir "$3"
		created=true
	fi
	cd "$3"
	norun=true
else
	#"check if deer dir exists"
	cd
	if [ ! -d ".deer" ]; then
		mkdir ".deer"
	fi
	cd ".deer"
	#check if repo dir exists
	if [ ! -d "$repo" ]; then
		mkdir "$repo"
		created=true
	fi
	cd "$repo"
fi

#check if pattern: deer <repo> --config <repoClone>
if [[ "$#" -eq 3 && "$2" == "--config" ]]; then
	norun=true
#	cd "$HOME/.deer/$3"
	mv "$HOME/.deer/$3/tmp.prop" "$HOME/.deer/$3/application.properties"
	echo "cd ../$repo" > "$HOME/.deer/$3/run.$3.sh"
	echo "bash run.$repo.sh -c $HOME/.deer/$3/application.properties" >> "$HOME/.deer/$3/run.$3.sh"
fi

if [ "$created" = true ]; then

	#check if safemode is on
	safeModeParam=""
	if [ ! -f "$HOME/.deer/safemode.conf" ]; then
		bash -c "echo 'on' > $HOME/.deer/safemode.conf"
	fi
	read -r safeMode < "$HOME/.deer/safemode.conf"

	if [[ ! "$safeMode" == "off" ]]; then
		#echo "Safemode is $safeMode"
		#is deerid set?
		if [ ! -f "$HOME/.deer/deerId.conf" ]; then
			echo "Safemode is on so no other public repo's can be run. But no deer id has been set. Run: deer id <myDeerId> or turn safemode off: deer safemode off"
			exit 2
		fi
		read -r deerId < "$HOME/.deer/deerId.conf"
		safeModeParam="safeMode=$deerId"
	fi

	#finally get the repo and execute
	echo "[$repo] Pulling $repo from the deer cloud"
	wget -q "https://deercore.org?run=$repo&$safeModeParam" -O deer.tar.gz -o /dev/null
	if tar -xf deer.tar.gz 2>/dev/null
	then
		rm -f deer.tar.gz
		if [ -f "prerun.$repo.sh" ]; then
			#run prerun setup file
			echo "[$repo] Running prerun steps"
			chmod +x "prerun.$repo.sh"
			bash "prerun.$repo.sh"
		fi
		if [[ "$norun" == false && -f "run.$repo.sh" ]]; then
			chmod +x "run.$repo.sh"
			pidc=$(ps -ef | grep "run.$repo" -c)
			if [[ $pidc == "1" ]]; then
				echo "[$repo] ${green}Starting deer${reset}"
				nohup bash "run.$repo.sh" > deerLog.log 2> deerLog.log &
			else
				echo "[$repo] Already running"
			fi
		fi
	else
		cloudResp=$(cat deer.tar.gz | cut -d ':' -f2 | cut -d '"' -f2 | sed 's/\\n/\n /g' | sed 's/\\//g')
		echo "[$repo] Deer cloud: $cloudResp"
		rm -rf *
		cd ..
		rmdir "$repo"
		extraInfo=""
		if [[ "$safeMode" == "on" ]]; then
			extraInfo="Try setting safemode off"
		fi
		echo "[$repo] ${red}Invalid or non-existent deer file. ${reset}$extraInfo"
		exit 2
	fi
else
	if [[ "$norun" == false && -f "run.$repo.sh" ]]; then
		pidc=$(ps -ef | grep "run.$repo" -c)
		if [[ $pidc == "1" ]]; then
			echo "[$repo] ${green}Starting deer${reset}"
			nohup bash "run.$repo.sh" > deerLog.log 2> deerLog.log &
		else
			echo "[$repo] Already running"
		fi
	fi
fi
exit 0
