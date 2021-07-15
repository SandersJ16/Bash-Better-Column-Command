#!/usr/bin/env bash

screen_width=`tput cols` #current width of terminal	
original_IFS=IFS #Record original IFS value
IFS=$'\n' #Change IFS to newline so loops will iterate at newline only and not other whitespace

ccolumn()
{
	local min_spaces=2 #minimum number of spaces between file names
	local number_of_display_items=0

	local declare colored=() #list of all strings still with color codes
	local declare colorless=() #list of strings without color codes

	local declare row_sizes=()
	local declare max_lengths=()

	local print_colors=true
	local print_rows_first=false
	local ignore_empty_lines=true

	local options="" #Get all -options supplied
	local rows

	setOptions "$@"
	setColorArrays
	local number_of_display_items=${#colorless[@]}
	
	#if Input given
	if [ $number_of_display_items != 0 ]; then
		
		local items_list
		if [ $print_rows_first = true ]; then
			printRowsFirst
		else
			printColumnsFirst
		fi
	fi

}

getOptions()
{
	for option_string in "$@"; do
		if [[ "$option_string" =~ -.* ]] ; then
			#if invalid option
			local option=`echo "$option_string" | sed s/-//`
			if [[ $option == *[^$accepted_options]* ]]; then
				echo "-$option is invalid option"
				exit 1
			else
				options=$options$option 
			fi
		fi
	done
}

setOptions()
{
	local accepted_options="ixe"
	getOptions "$@"
	
	if [[ $options == *i* ]]; then
		print_colors=false
	fi

	if [[ $options == *x* ]]; then
		print_rows_first=true
	fi

	if [[ $options == *e* ]]; then
		ignore_empty_lines=false
	fi
}

setColorArrays()
{
	#Assign input to arrays
	while read -t 1 file; do #Read Times out after 1 second if no input
		colored=("${colored[@]}" "$file")
		
		local color_removed=$(removeColor "$file")
		#color_removed=`echo "$file" | sed -r 's/\[[^mK]*(m|K)//g'` #Removes All linux Color Codes from String
		colorless=("${colorless[@]}" "$color_removed")
	done
}

removeColor()
{
	echo "$1" | sed -E 's/\[[^mK]*(m|K)//g' #Removes All linux Color Codes from String
}

setRowSizesToZero()
{
	#Initalize row_sizes to zero for each value
	for ((i = 0; i < $rows - 1; ++i)); do
		row_sizes[$i]=0
	done
}

getMaxLengthInRange()
{
	local max_len=0
	local start=$1
	local end=$2
	local increment_amount=$3
	#echo $start
	#echo $end
	#echo $increment_amount
	#Find max item length for the first column
	for ((i = $start; i < $end; i += $increment_amount)); do
		if [ $i -lt $number_of_display_items ]; then
			local len=${#colorless[$i]}
			if [ $len -gt $max_len ]; then
				max_len=$len
			fi
		fi
	done
	max_len=$((max_len + min_spaces)) #add minimum distance between words
	echo $max_len
}

testIfFilesFit()
{
	local __files_did_fit=$1
	local fit=true
	#Test to see if files will fit
	for ((column_position_index = 0; column_position_index < $rows; ++column_position_index)); do
		local list_index=$((column_start_index + column_position_index))
		if [ $list_index -lt $number_of_display_items ]; then
			local len=${#colorless[$list_index]}
			local spaces=$((max_len - len))
			len=$((len + spaces))
			row_sizes[$column_position_index]=$((row_sizes[column_position_index] + len))
			
			if [ ${row_sizes[$column_position_index]} -gt $screen_width ]; then
				fit=false
				break
			fi
		fi
	done
	eval $__files_did_fit="'$fit'"
}

setItemListForOutput()
{
	#If -i option selected then don't print colors (use colorless files)
	if [ "$print_colors" = false ]; then
		items_list=("${colorless[@]}")
	else
		items_list=("${colored[@]}")
	fi
}

dislayColumnsFirst()
{
	for ((column_start_index = 0; column_start_index < $rows; ++column_start_index)); do #For every row
		for ((column_position_index = 0; column_position_index < ${#max_lengths[@]}; ++column_position_index)); do #for every column
			item=$(( column_start_index + rows * column_position_index)) #Iteration through every rowth item ex. if row==7 then for the first loop fil_num will equal 0, 7, 14, etc  
			if [ $item -lt $number_of_display_items ]; then
				echo -ne "${items_list[$item]}"
				local length="${#colorless[$item]}"
				local max_column_length="${max_lengths[$column_position_index]}"
				local spaces=$((max_column_length - length))
				
				#Fill with appropriate spaces
				for ((i = 0; i < $spaces; ++i)); do
					echo -ne " "
				done
			fi
		done 
		echo "" #Start new line
	done
}

fitItemsForColumnFirstPrinting()
{
	rows=1
	local row_amount_fits_screen=false
	
	while [ "$row_amount_fits_screen" != true ]; do
		
		setRowSizesToZero
		
		#For every rowth element
		for ((column_start_index = 0; column_start_index < $number_of_display_items; column_start_index += $rows)); do 
			
			local max_len=$(getMaxLengthInRange $column_start_index $((rows + column_start_index)) 1)
			
			local column=$((column_start_index / rows))
			max_lengths[$column]=$max_len
			
			
			testIfFilesFit row_amount_fits_screen
			
			if [ $row_amount_fits_screen = false ]; then #if files didnt' fit
				rows=$((rows + 1))
				break
			fi
		done
	done
}

fitItemsForRowFirstPrinting()
{
	local column_amount_fits_screen=false
	columns=number_of_display_items
	
	while [ "$column_amount_fits_screen" != true ]; do
		for ((column_start_index = 0; column_start_index < $columns; ++column_start_index)); do
			max_lengths[$column_start_index]=$(getMaxLengthInRange $column_start_index $number_of_display_items $columns)
		done
		
		local max_row_length=0
		for ((column_start_index = 0; column_start_index < $columns; ++column_start_index)); do
			max_row_length=$((max_row_length + max_lengths[column_start_index] + min_spaces))
		done
		if [ $max_row_length -gt $screen_width ]; then
			columns=$((columns - 1))
		else
			column_amount_fits_screen=true
		fi
	done
}

displayRowsFirst()
{
	for ((items = 0; items < $number_of_display_items; ++items)); do
		
		local column_position_index=$((items % columns))
		if [ $column_position_index = 0 ] && [ $items != 0 ]; then
			echo ""
		fi
		echo -ne "${items_list[$items]}"
		local length="${#colorless[$items]}"
		local max_column_length="${max_lengths[$column_position_index]}"
		local spaces=$((max_column_length - length))
		#Fill with appropriate spaces
		for ((i = 0; i < $spaces; ++i)); do
			echo -ne " "
		done
	done
	echo ""
}

printRowsFirst()
{
	fitItemsForRowFirstPrinting
	setItemListForOutput
	displayRowsFirst
}

printColumnsFirst()
{
	fitItemsForColumnFirstPrinting
	setItemListForOutput
	dislayColumnsFirst
}
	
ccolumn "$@"
#reset IFS
IFS="$original_IFS"

