#!/bin/bash

# Some of the code was borrowed from the NGINX docker image 
# https://github.com/nginxinc/docker-nginx/blob/master/mainline/debian/20-envsubst-on-templates.sh

set -e

ME=$(basename "$0")


templater._fail(){
    echo "$@"
    exit 1
}

templater.envsubst() {
    local template_path="/dev/stdin" suffix=".tpl" output_path="/dev/stdout" filter="" inter_num=1 force backup
    local timestamp="$(date +%s)"
    local help=$(cat <<EOF
    Replaces variables (all or by filter \"${filter}\") in \"template_path/*${suffix}\" files and saves them into files of the same name in the output directory.
        [-e "env_var|env_var2"] - Set variables filter enveroment"
        [-o "output_path"]- Set output directory or file for parsed files. The directory must be empty or non-existent. If a file is specified, it must exist and be empty  If not set then return to STDOUT
        [-t "template_path"] - Set templates directory or template file. If not set then read from STDIN 
        [-i number ] - Default-1. Sets the number of interactions. Repeatedly replaces variables in files 
        [-f] - Force.  If a backup is not made, the files will be replaced.  (Warn - copying will be done instead of moving)
        [-b] - Backup. If the directory exists and is not empty, will be renamed to {name_fir}{timestamp}.old . If the file exists and is not empty, it will be renamed {name_file}{timestamp}.old
    Template file sufix (extension) - ${suffix}
    Designation of variables in  template file - \${variable}
EOF
)
    while getopts "e:o:t:i:hfb" options; do
        case "${options}" in
            h)
                echo -e "$help";
                return 0
            ;;
            e)
                filter="${OPTARG}"
            ;;
            t)
                template_path="${OPTARG%/}"
            ;;
            o)
                output_path="${OPTARG%/}"
            ;;
            i)
                inter_num="${OPTARG}"
            ;;
            f) force="yes"
            ;;
            b)
               backup="yes" 
            ;;
        esac
    done

    local tmp_dir template defined_envs relative_path output_path subdir random_name random_output_path random_template_path output_path_file file_name is_file
    defined_envs=$(printf '${%s} ' $(awk "END { for (name in ENVIRON) { print ( name ~ /${filter}/ ) ? name : \"\" } }" < /dev/null ))
    if [[ -e "$output_path" && ! -w "$output_path" ]]; then
        templater._fail "$ME: ERROR: $template_path exists, but $output_path is not writable"
    fi
    #random_name="$(cat /dev/urandom | tr -dc A-Z-a-z-0-9 | head -n 8 -c 8)"
    tmp_dir=$(mktemp -d)
    random_output_path="$tmp_dir/output"
    random_template_path="$tmp_dir/output_tpl"
    mkdir -p "${random_output_path}"
    mkdir -p "${random_template_path}" 
    c=1
    while [ $c -le $inter_num ]
    do
        if [ -d "$template_path" ]
        then
            find "$template_path" -follow -type f -name "*$suffix" -print | while read -r template; do
                relative_path="${template#"$template_path/"}"
                output_path_file="$random_output_path/${relative_path%"$suffix"}"
                subdir=$(dirname "$relative_path")
                # create a subdirectory where the template file exists
                mkdir -p "$random_output_path/$subdir"
                envsubst "$defined_envs" < "$template" > "$output_path_file"
            done
        elif [[ -f "$template_path" || -L "$template_path"  ]]
        then
            template="$template_path"
            file_name="$(basename ${template})"
            output_path_file="$random_output_path/${file_name%"$suffix"}"
            envsubst "$defined_envs" < "$template" > "$output_path_file"
        fi
        rm -r "$random_template_path"
        mv "$random_output_path" "$random_template_path"
        template_path="$random_template_path"
        suffix=""
        c=$((c+1))
    done

    if [[ -f "$output_path" && -s "$output_path"  || -d "$output_path" &&  ! -z "$(ls -A $output_path)"  ]]
    then
        if [ "$backup" == "yes" ]
        then
            mv "$output_path" "$output_path.$timestamp.old"   
        elif [ "$force" != "yes" ]
        then   
            templater._fail "Directory or file '$output_path' is exists"
        fi
    fi

    if [[ -f "$output_path" || -L  "$output_path" && ! -d "$output_path" || ! -e "$output_path" && -f "$output_path.$timestamp.old" ]]
    then
        # if a file is meant, then we work as with a file
        find "$random_template_path" -type f  -exec cat {} + >>"$output_path";
    elif [[ -d "$output_path" && ! -z "$(ls -A "$output_path")" ]]
    then
        #if the directory is not empty, then we transfer all files with replacement
        #find "$random_template_path"  -mindepth 1 -maxdepth 1 -exec mv --backup=numbered -f -t  "$output_path" {} +;
        find "$random_template_path"  -mindepth 1 -maxdepth 1 -exec cp -r -f -t "$output_path" {} +;
    else
        #if the directory is empty, then delete it to simply rename the directory
        rm -f "$output_path"
        mv  "$random_template_path" "$output_path"
    fi
    rm -r "$tmp_dir"
}

templater(){
    "templater.$@"
}

if [ -z "$is_packed" ]
then
   templater "$@"
fi
