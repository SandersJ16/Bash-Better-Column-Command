# Bash-Better-Column-Command
bash column command that can deal with colors

The reason this script was created is that the built in column command in the bash terminal can't deal with color codes. If you were to run 'ls | grep --color=always "hello" | column' it would not give the output in nice columns since it includes the color codes in its space calculations even though they are not going to show. This script will make nice columns of output whether or not there are color codes included.

Right now only 3 options are available

-i will not print colors even if they are passed
-x will print rows first (default is columns first)
-e will ignore empty lines

To install simply download the ccolumn.bash. I run it as an alias with ccolumn which can be done by typing the following in your ~/.bash_aliases file:

alias ccolumn='/file/path/ccolumn.bash' (where /file/path is obviously the path to where you downloaded the file)

Or alternatively you can make it make a terminal command by adding it to your path:

cp ccolumn.bash ccolumn (You can change ccolumn to whatever you want the command name to be)
chmod +x ccolumn
sudo mv ccolumn /usr/bin

After this you should be able to call the script from your terminal with 'ccolumn'.
