script_share_space_path=$(dirname $(readlink -f "$0"))

a=5
#declare -A arr=([one]=1)

#declare -g -p a arr
line=$(echo -e "declare -Af -d -z arr=([one]="1")"|sed  -r 's/^declare (-.+ )+//')


