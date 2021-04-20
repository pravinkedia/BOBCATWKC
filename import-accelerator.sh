#!/bin/bash

############################################################################################################################################################
# Copyright IBM Corp. 2020
# All Rights Reserved
#############################################################################################################################################################


# Handling default and command line arguments 

TIMESTAMP=`date "+%Y-%m-%d--%H:%M:%S"`
logtime=$TIMESTAMP

echo "$TIMESTAMP">>logfile.log-$logtime

echo 
# Handling user input flags

for arg in "$@"
do
	case $arg in
                -h|--hostname)
                        CPD_HOST="$2"
                        shift
			shift
                        ;;
                -u|--username)
                        username="$2"
                        shift
			shift
                        ;;
                -p|--password)
                        password="$2"
                        shift
			shift
                        ;;
                -n|--name)
                        analytics_project="$2"
                        shift	
			shift
                        ;;
		-d|--directory)
			folder="$2"
			shift
			shift
			;;
		-f|--file)
                        tarfile="$2"
                        shift
                        shift
                        ;;
		-v|--version)
			echo
			echo "INFO : Accelerator Import script version 1.0"
			shift
			exit 0
			;;
		--help) 
			echo
			echo "Cloud Pak for Data - Industry Accelerator Import"
			echo 
			echo
			echo "Usage: ./import-acclerator.sh [flags]"
			echo
			echo 
			echo "Flags :"
			echo
			echo "       -d, --directory :   User input of directory extracted from tar.gz file"
			echo "       -f, --file      :   User input of accelerator tar.gz file"
			echo "       -h, --hostname  :   User input of Cloud Pak for Data cluster host URL"
			echo "       -u, --username  :   User input of Cloud Pak for Data username"
			echo "       -p, --password  :   User input of Cloud Pak for Data password"
			echo "       -n, --name      :   User input of name for analytics project"
			echo "       -v, --version   :   Specifies the version of script"
			echo "           --help      :   Help for accelerator import process"
			echo
			echo "These arguments are optional and can be declared in any order."
			echo
			echo "INFO : To run script without parameters. "
			echo
			echo "Example syntax Bash Users : ./import-accelerator.sh "
			echo "Example syntax Windows Users : bash -c ./import-accelerator.sh "
			echo
			echo "INFO : To run script with parameters. [ With extracted accelerator folder content from tar.gz file ]"
			echo
			echo "Example syntax Bash Users : ./import-accelerator.sh -d accelerator-folder-name -h https://CP4D-hostname:port -u username -p password -n name-of-project"
                        echo "Example syntax Windows Users : bash -c ./import-accelerator.sh -d accelerator-folder-name -h https://CP4D-hostname:port -u username -p password -n name-of-project"
			echo
			echo "INFO : To run script with parameters. [ With Tar.gz file ]"
			echo
			echo "Example syntax Bash Users : ./import-accelerator.sh -f accelerator-file-name.tar.gz -h https://CP4D-hostname:port -u username -p password -n name-of-project"
			echo "Example syntax Windows Users : bash -c ./import-accelerator.sh -f accelerator-file-name.tar.gz -h https://CP4D-hostname:port -u username -p password -n name-of-project"
			shift
			exit 0
			;;
		$1)
			echo "ERROR : Invalid parameter(s). User --help argument to get assistance on usage of the parameter(s)."
			exit 0
			shift
			;;
	esac
done

echo
echo "INFO : Starting script..." > output.txt
cat output.txt
echo "$TIMESTAMP">>logfile.log-$logtime
echo >> logfile.log-$logtime
cat output.txt >> logfile.log-$logtime

############################################################################################################################################################

# Config section & argument checks

# cpd cluster check

while [[ -z "$CPD_HOST" ]]
do 
   	# Read Variables from User
	echo "INFO : Script parameter Cloud Pak for Data Hostname required. " 
	echo "INFO : Run ./import-accelerator.sh --help for further help."
   	echo "Enter Cloud Pak for Data Cluster Hostname in the example format : https://<hostname:port> "
	echo
 	read -t300 -p 'Cloud Pak for Data HOSTNAME : ' CPD_HOST
	if [ $? -gt 300 ]
        then
                echo
                echo No input entered by user. Aborting import...> output.txt
		cat output.txt
		echo "$TIMESTAMP">>logfile.log-$logtime
		echo >> logfile.log-$logtime
		cat output.txt >> logfile.log-$logtime
                exit 0
        fi

done

if [[ $CPD_HOST != https://* ]]
then
	CPD_HOST=https://$CPD_HOST
fi

if [[ $CPD_HOST == */ ]] 
then
 	CPD_HOST=${CPD_HOST%?}
fi

# Cluster Sanity Check 
if curl -k --output /dev/null --silent --head --fail "$CPD_HOST"; then
	echo 
else
	echo "ERROR : URL does not exist/Failure in reaching the site! "> output.txt
	cat output.txt
	echo "$TIMESTAMP">>logfile.log-$logtime
	echo >> logfile.log-$logtime
	cat output.txt >> logfile.log-$logtime

 	exit 1
fi

# endpoint & headers for authentication

declare -a authURL="${CPD_HOST}/icp4d-api/v1/authorize"

declare -a curlArgs1=('-H' "Content-Type: application/json" \
        '-H' "cache-control: no-cache")

# CREDENTIALS check

###########################################################################################################################################################

while [[ -z "$username" ]]
do 
	echo "INFO : Script parameter Username required. "
	echo "INFO : Run ./import-accelerator.sh --help for further help."
	read -t300 -p 'Enter USERNAME : ' username
	if [ $? -gt 300 ]
        then
                echo
                echo No input entered by user. Aborting import...> output.txt
		cat output.txt
		echo "$TIMESTAMP">>logfile.log-$logtime
		echo >> logfile.log-$logtime
		cat output.txt >> logfile.log-$logtime
                exit 0
        fi

done
echo
while [[ -z "$password" ]]
do
	echo "INFO : Script parameter Password required. "
	echo "INFO : Run ./import-accelerator.sh --help for further help."
        read -t300 -sp 'Enter PASSWORD : ' password
	if [ $? -gt 300 ]
        then
                echo
                echo No input entered by user. Aborting import...> output.txt
                cat output.txt
                echo "$TIMESTAMP">>logfile.log-$logtime
                echo >> logfile.log-$logtime
                cat output.txt >> logfile.log-$logtime
                exit 0
        fi

done

credentials='{"username":"'$username'","password":"'$password'"}'

HTTP_CODE=$(curl -s --write-out "%{http_code}\n" -k -X POST "${curlArgs1[@]}" \
                -d "$credentials" \
                 ${authURL} \
		--output output.txt) 

echo "$TIMESTAMP">>logfile.log-$logtime

echo
if [[ $HTTP_CODE == 200 ]]
then
	echo "INFO : [1] Authentication completed and successful."> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime

else
       	echo ERROR : Please check your username/password. Please also check your Cloud Pak for Data Hostname...> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime
	exit 1
	rm -rf output.txt
fi

# Authentication and User permissions check

###########################################################################################################################################################

if [[ $HTTP_CODE == 200 ]]
then
	echo 
  	json=$(curl -s -k "$authURL" \
            -X POST "${curlArgs1[@]}" \
            -d "$credentials") \
   		&& token=$(echo $json | sed "s/{.*\"token\":\"\([^\"]*\).*}/\1/g") \


  	echo
	echo "INFO : Checking for user permissions..."> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime

  	echo

  	user_permissions=$(curl -s -k -X GET -H "Authorization: Bearer $token" \
        	-H "cache-control: no-cache" "${CPD_HOST}/icp4d-api/v1/users/$username")
	#echo $user_permissions
	#exit 1 
 	if echo $user_permissions | grep -q  -e "Administrator" -e "Data Steward" -e "Data Engineer" -e "Data Quality Analyst" -e "zen_administrator_role" -e "wkc_data_steward_role" -e "wkc_data_scientist_role" -e "zen_data_engineer_role" 
  	then
   		echo INFO : User has necessary privileges for both Project and Glossary import.> output.txt
                cat output.txt
                echo "$TIMESTAMP">>logfile.log-$logtime
                echo >> logfile.log-$logtime
                cat output.txt >> logfile.log-$logtime

  	else
   		echo WARNING : Administrator, Data Steward, Data Engineer or Data Quality Analyst user permissions needed.
   		read -t300 -p 'User does not have permissions for managing Watson Knowledge catalog, Do you wish to continue with import? (Enter y/n) : ' ch
		if [ $? -gt 300 ]
        	then
                	echo
                	echo No input entered by user. Aborting import...> output.txt
	                cat output.txt
        	        echo "$TIMESTAMP">>logfile.log-$logtime
                	echo >> logfile.log-$logtime
                	cat output.txt >> logfile.log-$logtime
                	exit 0
        	fi


   		if [[ $ch == 'y' || $ch == 'Y' ]]
   		then
    			import_without_glossary=1
   		elif [[ $ch == 'n' || $ch == 'N' ]]
   		then 
			echo INFO : Stopping import process...> output.txt
                	cat output.txt
        	        echo "$TIMESTAMP">>logfile.log-$logtime
	                echo >> logfile.log-$logtime
	                cat output.txt >> logfile.log-$logtime
    			rm -rf output.txt
    			exit 1
   		else
			echo "ERROR : Invalid Input."> output.txt
	                cat output.txt
        	        echo "$TIMESTAMP">>logfile.log-$logtime
                	echo >> logfile.log-$logtime
	                cat output.txt >> logfile.log-$logtime
    			rm -rf output.txt
    			exit 1
   		fi
  	fi
else 
	echo "ERROR : Import process aborted. "> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime
fi

# tarfile or folder existance check
######################################################################################################################################################
echo
if [[ ! -z "$folder" && ! -z "$tarfile" ]]
then
	echo "ERROR : Please enter only either 1 among the 2 script parameters."> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime
	echo "INFO : Option 1 : The extracted accelerator content directory. [Use flag -d]"
	echo "       OR"
	echo "INFO : Option 2 : The downloaded accelerator tar.gz file in case script was downloaded externally via community page. [User flag -f] "
	echo "INFO : Run ./import-accelerator.sh --help for further help."
	rm -rf output.txt
	exit 1
fi

######################################################################################################################################################
echo
if [[ -z "$folder" && -z "$tarfile" ]]
then 
	echo "INFO : If you have already extracted the content of the tar.gz file, enter "1". Otherwise, enter "2"."
	echo "INFO : Run ./import-accelerator.sh --help for further help."
	echo
	read -t300 -p 'Enter choice : ' import_choice 

	if [[ $? -gt 300 || -z "$import_choice" ]]
        then
                        echo
                        echo No input entered by user. Aborting import...> output.txt
        	        cat output.txt
	                echo "$TIMESTAMP">>logfile.log-$logtime
                	echo >> logfile.log-$logtime
        	        cat output.txt >> logfile.log-$logtime
			rm -rf output.txt
                        exit 0
        fi 
	
fi


######################################################################################################################################################
echo
if [[ -z "$folder" && $import_choice == 2 ]]
then
	script_inclusive_accelerator=0
	
elif [[ -z "$folder" && $import_choice == 1 ]]
then
	script_inclusive_accelerator=1
	
	echo "INFO : Script parameter extracted accelerator folder required. "
        echo "INFO : Run ./import-accelerator.sh --help for further help."
        echo "Example syntax : accelerator-folder-name"
	echo
	read -t300 -p 'Please provide the extracted folder name : ' folder
                if [ $? -gt 300 ]
                then
                        echo
                        echo No input entered by user. Aborting import...> output.txt
	                cat output.txt
	                echo "$TIMESTAMP">>logfile.log-$logtime
        	        echo >> logfile.log-$logtime
                	cat output.txt >> logfile.log-$logtime
			rm -rf output.txt
                        exit 0
                fi

	if [[ -z "$folder" || ! -d "$PWD/$folder" ]]
	then 
		echo
		echo "ERROR : Extracted accelerator content folder not found. "> output.txt
                cat output.txt
                echo "$TIMESTAMP">>logfile.log-$logtime
                echo >> logfile.log-$logtime
                cat output.txt >> logfile.log-$logtime
		rm -rf output.txt
		exit 1
	fi
	current_path=$PWD
	accelerator_name=${folder%-industry-accelerator}

elif [[ ! -z "$folder" ]]
then 
	script_inclusive_accelerator=1

        current_path=$PWD
        accelerator_name=${folder%-industry-accelerator}

else 
	script_inclusive_accelerator=0

fi
###########################################################################################################################################################

if [[ $script_inclusive_accelerator == 1 &&  ! -d "$PWD/$folder" ]]
then
		echo
                echo "ERROR : Extracted accelerator content folder not found. "> output.txt
                cat output.txt
                echo "$TIMESTAMP">>logfile.log-$logtime
                echo >> logfile.log-$logtime
                cat output.txt >> logfile.log-$logtime
                rm -rf output.txt
                exit 1
fi

###########################################################################################################################################################
if [[ $script_inclusive_accelerator == 0  ]]
then
	current_path=$PWD
	echo 

	while [[ -z "$tarfile" ]]
	do
        	echo "INFO : Script parameter Tar.gz file required. "
		echo "INFO : Run ./import-accelerator.sh --help for further help."
		echo "Example syntax : accelerator-file-name.tar.gz."
		echo
		read -t300 -p 'Please provide the downloaded filename : ' tarfile
		if [ $? -gt 300 ]
		then
			echo
			echo No input entered by user. Aborting import...> output.txt
	                cat output.txt
                	echo "$TIMESTAMP">>logfile.log-$logtime
        	        echo >> logfile.log-$logtime
	                cat output.txt >> logfile.log-$logtime
			rm -rf output.txt
			exit 0	
		fi	
	done


	# Tar file check and extraction of content. 
	echo

	if ! tar -zxvf "$tarfile"
	then
        	echo "ERROR : Invalid file"> output.txt
                cat output.txt
                echo "$TIMESTAMP">>logfile.log-$logtime
                echo >> logfile.log-$logtime
                cat output.txt >> logfile.log-$logtime
		rm -rf output.txt
        	exit 1
	else
		echo
		echo "INFO : Extracted accelerator artefacts... "> output.txt
                cat output.txt
                echo "$TIMESTAMP">>logfile.log-$logtime
                echo >> logfile.log-$logtime
                cat output.txt >> logfile.log-$logtime
	fi


	accelerator=${tarfile%-industry-accelerator.tar.gz}

	accelerator_name=`echo "$accelerator" | rev | cut -d"/" -f1  | rev`
fi

echo "$TIMESTAMP">>logfile.log-$logtime
echo >> logfile.log-$logtime
echo " Accelerator being imported : $accelerator_name" >> logfile.log-$logtime
project_zipfile="$current_path/$accelerator_name-industry-accelerator/$accelerator_name-analytics-project.zip"


if [[ -z "$project_zipfile" ]]
then 
	echo "INFO : Please ensure that the script and tar.gz file are in the same directory and try again."> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime
	rm -rf output.txt
	exit 1
fi
	

if [[ ! -f $project_zipfile ]]
then
       	skip_Project_Import=1
        echo
       	echo "INFO : Glossary only accelerator."> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime

else
       	skip_Project_Import=0
	echo "INFO : Accelerator contains analytics project with business glossary."> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime
fi


###########################################################################################################################################################

# Provide Name for project and if zip file is present

echo
if [[ $skip_Project_Import == 0 ]]
then
	echo "INFO : Starting accelerator import process..."> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime

	
	if [[ -z "$analytics_project" ]]
 	then
  		echo "INFO : Script parameter project name required. Do you want to provide a name for the analytics project ?"
		echo "INFO : Run ./import-accelerator.sh --help for further help."
  		read -t 30 -p 'Enter [Y/y] to provide a name or simply press enter to skip and a new name will be generated: ' choice
		
  		echo
  		if [[ $choice == y || $choice == Y ]]
 		then
   			read -t 300 -p 'ANALYTICS PROJECT NAME : ' project
   			analytics_project=$project
  		else
   			analytics_project=$accelerator_name
  		fi
 	fi
	
	if [[ ${#analytics_project} -gt 95 ]]
	then 
		echo "WARNING : Project name too large."
		analytics_project=`echo ${analytics_project:0:95}`
		echo "Project name has been trimmed down to $analytics_project"> output.txt
	        cat output.txt
        	echo "$TIMESTAMP">>logfile.log-$logtime
	        echo >> logfile.log-$logtime
        	cat output.txt >> logfile.log-$logtime
	fi 
 	
	# analytics project metadata
 	METADATA='metadata={
  		"name": "'${analytics_project}'",
  		"description": "Industry Accelerator.",
  		"generator": "IndAcc-Projects",
  		"public": false,
  		"tags": [
    			"string"
  			],
  		"storage": {
    			"type": "assetfiles",
    			"guid": "d0e410a0-b358-42fc-b402-dba83316413b"
   			}
 		}'


 	if [[ -z "${METADATA}" ]]; then
    		echo " ERROR : Metadata generation failed."> output.txt
        	cat output.txt
	        echo "$TIMESTAMP">>logfile.log-$logtime
        	echo >> logfile.log-$logtime
	        cat output.txt >> logfile.log-$logtime
    		rm -rf output.txt
    		exit 1
 	else 
		echo  INFO : Metadata created for project.
 	fi

 	declare -a metadata="${METADATA}"


	
 	# endpoint and headers for analytics project import
 	if [ $HTTP_CODE == 200 ]
 	then
  		declare -a curlArgs2=('-H' "Authorization: Bearer $token" \
 			'-H' "content-type:multipart/form-data")

  		echo INFO : Importing the analytics project...> output.txt
        	cat output.txt
	        echo "$TIMESTAMP">>logfile.log-$logtime
        	echo >> logfile.log-$logtime
	        cat output.txt >> logfile.log-$logtime


  		http_proj=$(curl -s --write-out "%{http_code}\n" -X POST -k \
    			"${CPD_HOST}/transactional/v2/projects" \
    			"${curlArgs2[@]}" \
    			-F file=@$current_path/$accelerator_name-industry-accelerator/$accelerator_name-analytics-project.zip \
    			-F "$metadata" \
    				--output output.txt )
    		echo "$TIMESTAMP">>logfile.log-$logtime
		cat output.txt>>logfile.log-$logtime	
	
  		if [[ $http_proj == 202 ]]
  		then
			echo
			echo INFO : Importing Project Artefacts...
			trans_id=$(cat output.txt | sed "s/{.*\"id\":\"\([^\"]*\).*}/\1/g")	
        
 	 	elif [[ $http_proj == 400 ]]
  		then 
			echo
   			echo WARNING : Project with entered/default name exists. $http_proj

   			while [[ $http_proj == 400 ]]
   			do 	
				current_version=$analytics_project
				n=${current_version##*[!0-9]}; p=${current_version%%$n}
				analytics_project=$p$((n+1))
				METADATA='metadata={
  					"name": "'${analytics_project}'",
			  		"description": "Industry Accelerator.",
  					"generator": "IndAcc-Projects",
  					"public": false,
					"tags": [
    						"string"
  						],
					"storage": {
				    		"type": "assetfiles",
				    		"guid": "d0e410a0-b358-42fc-b402-dba83316413b"
				 	 	}
					}'
				declare -a metadata="${METADATA}"

				http_proj=$(curl -s --write-out "%{http_code}\n" -X POST -k \
	  				"${CPD_HOST}/transactional/v2/projects" \
	  				"${curlArgs2[@]}" \
	  				-F file=@$current_path/$accelerator_name-industry-accelerator/$accelerator_name-analytics-project.zip \
	  				-F "$metadata" \
   	     					--output output.txt )
				echo "$TIMESTAMP">>logfile.log-$logtime
        			cat output.txt>>logfile.log-$logtime
				
				trans_id=$(cat output.txt | sed "s/{.*\"id\":\"\([^\"]*\).*}/\1/g")	
	   		done  
   			echo INFO : Project with updated name created.> output.txt
		        cat output.txt
		        echo "$TIMESTAMP">>logfile.log-$logtime
		        echo >> logfile.log-$logtime
		        cat output.txt >> logfile.log-$logtime

	
  		else 
   			echo ERROR : Aborting Import... $http_proj Failure.> output.txt
   			cat output.txt
			echo "$TIMESTAMP">>logfile.log-$logtime
			echo >> logfile.log-$logtime
 	  		cat output.txt>>logfile.log-$logtime
   			rm -rf output.txt
   			exit 1
  		fi 

 	else
  		echo ERROR : Process Aborted ! Incorrect Details/Cluster Unreachable. $HTTP_CODE > output.txt
  		cat output.txt
		echo "$TIMESTAMP">>logfile.log-$logtime
		echo >> logfile.log-$logtime
 		cat output.txt>>logfile.log-$logtime
  		rm -rf output.txt
  		exit 1
 	fi
	
	echo
 	echo "INFO : [2] Analytics project imported..."> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime

	echo 

 	if [[ $import_without_glossary == 1 ]]
 	then
  		rm -rf output.txt
 		echo
  		echo IMPORTED INDUSTRY ACCELERATOR ANALYTICS PROJECT DETAILS
		echo Cluster Hostname : $CPD_HOST
  		echo Project Name : $analytics_project
  		echo Cloud Pak for Data user : $username
 		echo
  		echo INFO : Please visit the Cloud Pak for Data cluster to access all the artefacts. View "logfile.log-$logtime" to view the import process log.
  		exit 1 
   
 	fi 
fi

###########################################################################################################################################################

# WKC Glossary Import 

echo INFO : Importing the $accelerator_name accelerator category...> output.txt
cat output.txt
echo "$TIMESTAMP">>logfile.log-$logtime
echo >> logfile.log-$logtime
cat output.txt >> logfile.log-$logtime


http_cat=$(curl -s --write-out "%{http_code}\n" -X POST "${CPD_HOST}/v3/governance_artifact_types/all/import?merge_option=all" \
	-H "accept: application/json" \
	-H "Authorization: Bearer $token" \
  	-H "content-type: multipart/form-data" \
  	-F "file=@\"./$accelerator_name-industry-accelerator/$accelerator_name-glossary-categories.csv\";type=text/csv;charset=windows-1250" -k \
  		--output output.txt)
echo "$TIMESTAMP">>logfile.log-$logtime
cat output.txt>>logfile.log-$logtime

if [[ $http_cat == 200 ]]
then
	echo

 	if cat output.txt | grep -q "Line skipped, insufficient permission to modify category {0}"
	then 	
		echo "ERROR : Line skipped, Pre-existing category present. Insufficient permissions to modify existing category."> output.txt
        	cat output.txt
	        echo "$TIMESTAMP">>logfile.log-$logtime
	        echo >> logfile.log-$logtime
       		cat output.txt >> logfile.log-$logtime
		echo "INFO : Aborting category and glossary import."
		abort_glossary_import=1
	else 
		abort_glossary_import=0
		echo "INFO : [3] Category imported."> output.txt
	        cat output.txt
        	echo "$TIMESTAMP">>logfile.log-$logtime
	        echo >> logfile.log-$logtime
        	cat output.txt >> logfile.log-$logtime
	fi
	
elif [[ $http_cat == 401 ]] 
then
 	echo ERROR : The current User is Unauthorized and does not have user permissions to manage Watson Knowledge Catalog.. $http_cat > output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime
 	rm -rf output.txt
 	exit 1
else
 	echo ERROR : Category Import Failed. $http_cat > output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime
 	rm -rf output.txt
 	exit 1
fi

if [[ $abort_glossary_import == 0 ]]
then 

	echo
	echo INFO : Importing the $accelerator_name accelerator business terms...> output.txt
        cat output.txt
        echo "$TIMESTAMP">>logfile.log-$logtime
        echo >> logfile.log-$logtime
        cat output.txt >> logfile.log-$logtime


	http_term=$(curl -s --write-out "%{http_code}\n" -X POST "${CPD_HOST}/v3/governance_artifact_types/glossary_term/import?merge_option=all" \
		-H "accept: application/json" \
	  	-H "Authorization: Bearer $token" \
  		-H "content-type: multipart/form-data" \
	  	-F "file=@\"./$accelerator_name-industry-accelerator/$accelerator_name-glossary-terms.csv\";type=text/csv;charset=windows-1250" -k \
  			--output output.txt)
	echo "$TIMESTAMP">>logfile.log-$logtime
	cat output.txt>>logfile.log-$logtime

	if [[ $http_term == 200 ]]
	then
		echo 
	 	echo "INFO : [4] Business glossary terms imported."> output.txt
	        cat output.txt
        	echo "$TIMESTAMP">>logfile.log-$logtime
	        echo >> logfile.log-$logtime
        	cat output.txt >> logfile.log-$logtime

	elif [[ $http_term == 401 ]]
	then
 		echo ERROR : The current User is Unauthorized and does not have user permissions to manage Watson Knowledge Catalog. $http_term > output.txt
	        cat output.txt
        	echo "$TIMESTAMP">>logfile.log-$logtime
	        echo >> logfile.log-$logtime
      		cat output.txt >> logfile.log-$logtime
 		rm -rf output.txt
	 	exit 1
	else
 		echo ERROR : Glossary Terms Import Failed. $http_term > output.txt
        	cat output.txt
	        echo "$TIMESTAMP">>logfile.log-$logtime
        	echo >> logfile.log-$logtime
	        cat output.txt >> logfile.log-$logtime
 		rm -rf output.txt
	 	exit 1 
	fi
fi
echo
echo IMPORTED INDUSTRY ACCELERATOR DETAILS
echo Cluster Hostname : $CPD_HOST
if [[ $skip_Project_Import == 0 ]]
then
	echo Project Name : $analytics_project
fi
#echo Transaction ID : $trans_id
echo Cloud Pak for Data user : $username
if [[ $abort_glossary_import == 0 ]]
then
	echo Category and the glossary of business terms import completed through Watson Knowledge Catalog.
fi
echo
rm -rf output.txt

echo INFO : Please visit the Cloud Pak for Data cluster to access all the artefacts. View "logfile.log-$logtime" to view the import process log.
