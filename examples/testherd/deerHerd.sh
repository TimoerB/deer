
finishOffEnvDeer() {
	deerName=$1
	deerRepo=$2
	if [[ "$deerName" != "" ]]; then
		if [ ! -d "$deerName" ]; then
			mkdir "$deerName"
		fi
		mv tmp.prop "$deerName"
		#deer "$deerRepo" --config "$deerName"
		echo ":O Starting another one. Finishing previous one..."
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

		echo "got $propLine, $propArg, $propVal"

		bash -c "echo '$propArg=$propVal' >> tmp.prop"
	fi

	echo "[deerRepo] $deerRepo, [deerName] $deerName, [servicesBegun] $servicesBegun"
done < "test.herd"

#finish off previous deer and run it
finishOffEnvDeer $deerName $deerRepo

exit 0

