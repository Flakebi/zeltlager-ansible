set fish_greeting
set fish_color_escape 8700af
set fish_color_history_current 8700af
set fish_color_match 8700af
set fish_color_operator 8700af
set fish_color_param 0087d7
set fish_color_jump 0087d7
set fish_color_command 5f87ff
set fish_color_comment 4070c0
set fish_color_cwd 00875f
set fish_color_quote brown
set fish_color_error cc2266
set fish_emoji_width 2

# Aliases
if command -v nvim > /dev/null
	alias vi nvim
end
complete -c mysync --wraps rsync
alias myssync 'mysync --rsync-path "sudo rsync"'
alias ll 'ls -Ahl'
alias la 'ls -ahl'
alias lolcat 'lolcat -f -t' # true color
alias rg 'rg -S' # smart-case
alias sc systemctl
alias ssc 'sudo systemctl'
alias scu 'systemctl --user'
alias jo 'journalctl'
alias jou 'journalctl --user'

alias gitb 'git branch'

# Include local config
if test -e "$HOME/.config/fish/localconfig.fish"
	source "$HOME/.config/fish/localconfig.fish"
end

if command -v exa > /dev/null
	alias ls 'exa --icons'
	alias ll 'exa -blg'
	alias la 'exa -blaag'
end

# Useful git functions
function gitl -d 'Print oneline log of the last n commits'
	git log --oneline '--format=%C(auto)%h% ar%Cblue% aN%C(auto)%d% s' --decorate -$argv[1] $argv[2..-1]
end

function gitclean -d 'Radically clean a git repository'
	git reflog expire --expire=now --all
	git gc --prune=now
	git gc --aggressive --prune=now
	git repack -Ad
	git prune
end

function gitr -d 'Reverse log from a given commit'
	git log --reverse --ancestry-path $argv^..HEAD
end

function csc -d 'Compile a C# file' -a file
	set -l sdk_path (dirname (readlink -e /run/current-system/sw/bin/dotnet))/sdk/3.0.100
	set -l libs
	for lib in $sdk_path/Microsoft/Microsoft.NET.Build.Extensions/net461/lib/*.dll
		set -a libs -r:$lib
	end
	for lib in $sdk_path/*.dll
		set -a libs -r:$lib
	end
	dotnet $sdk_path/Roslyn/bincore/csc.dll -optimize+ $libs $file
end

function create -d 'Create and edit an executable file' -a name
	echo "#!/usr/bin/env bash" > $name
	chmod +x $name
	vi $name
end

function detach -w 'env' -d 'Run and close terminal'
	env $argv & disown; exit
end

# Args: 1. number of chars, 2. output
function bread -d 'Wrapper for bash read'
	bash -c "read -n '$argv[1]' -p '$argv[2..-1]' result; echo \$result"
end

# Example: if ask 'Do you want to do that?'; echo 'now doing it'; end
function ask -d 'Ask a question and request y or something else' -a description
	bread 1 "$description [y|n]: " | read result
	echo
	test "$result" = 'y'
end

function rasync
	mysync -n $argv
	if ask "Move $argv[1..-2] to $argv[-1]?"
		mysync $argv
	end
end

function strwidth -d 'Get the width of a string'
	string length (string replace -ra '\e\[[^m]*m' '' $argv[1])
end

function get_color -d 'Compute a color based on a string'
	printf '%s' "$argv" | md5sum | cut -c1-6
end

function format_time -d 'Adaptively format the given time in ms' -a millis
	if test "$millis" -lt 1000 # Milliseconds
		printf '%dms' "$millis"
	else if test "$millis" -lt 60000 # Seconds
		printf '%d.%02ds' (math "floor($millis / 1000)") (math "floor($millis / 10 % 100)")
	else
		set total_seconds (math "floor($millis / 1000)")
		set seconds (math "floor($total_seconds % 60)")
		set minutes (math "floor($total_seconds / 60) % 60")
		set hours (math "floor($total_seconds / 3600) % 24")
		set days (math "floor($total_seconds / 86400)")
		if test "$total_seconds" -lt 3600 # Minutes
			printf '%02d:%02d' "$minutes" "$seconds"
		else if test "$total_seconds" -lt 86400 # Hours
			printf '%02d:%02d:%02d' "$hours" "$minutes" "$seconds"
		else # Days
			printf '%dd %02d:%02d:%02d' "$days" "$hours" "$minutes" "$seconds"
		end
	end
end

function complement_color -d 'Compute the complement of a rgb hex color' -a rgb
	#set -l prompt_debug 1
	if test -n "$prompt_debug"
		printf 'Input:      %s\n' "$rgb" > /dev/tty
		bash -c "printf %06x \$((0xffffff ^ 0x$rgb))" | read result
		printf 'Old output: %s\n' "$result" > /dev/tty
	end
	#ComplementColor.py "$rgb" | read result
	python3 -c '
#!/usr/bin/env python3
import colorsys
import sys

def complement(rgb):
	hls = list(colorsys.rgb_to_hls(*map(lambda c: int(c, 16) / 0xff, (rgb[0:2], rgb[2:4], rgb[4:6]))))

	#print("HLS: " + str(tuple(hls)))
	# Create the complement of the color
	# Change color
	hls[0] = (hls[0] + 0.5) % 1
	# Switch lightness (black/white)
	hls[1] = 1 - hls[1]
	# Maximum saturation (color)
	hls[2] = 1

	rgb = colorsys.hls_to_rgb(*hls)
	return "{:02x}{:02x}{:02x}".format(*map(lambda x: int(x * 255), rgb))

def main():
	comp = complement(sys.argv[1])
	print(comp)

if __name__ == "__main__":
	main()
	' "$rgb" | read result

	if test -n "$prompt_debug"
		printf 'Output:     %s\n' "$result" > /dev/tty
	end
	printf '%s' "$result"
end

function shortpath -d 'Shorten a path' -a path
	printf '%s' "$path" | awk "{
		start = 1;
		end = split(\$0, ar, \"/\");
		if (end > 3)
			start = end - 2;
		for (i = start; i <= end; i++) {
			if (i != end)
				printf(\"%s$prompt_thin_right_arrow\", substr(ar[i], 1, 1))
			else
				printf(\"%s\", ar[i])
		}
	}"
end

function prepare_prompt -d 'Compute the colors and values used in the prompt'
	set -l prompt_stripped_name (hostname | cut -d . -f 1)

	# Powerline chars: E0B0-E0B3
	set -g prompt_right_arrow \ue0b0
	#set -g prompt_thin_right_arrow (set_color aaaaaa)\ue0b5(set_color ffffff)
	set -g prompt_thin_right_arrow /

	# Colors
	# Hostname
	set -l prompt_hostname (get_color "$prompt_stripped_name")
	# Username
	set -l prompt_username (get_color (whoami))
	# Path
	set -g prompt_path 0066bb
	# Time
	set -g prompt_time 2288cc
	# End color
	set -g prompt_end 444444
	set -g prompt_vcs_branch 178c58
	set -g prompt_vcs_status 459ea2

	# Overwrite colors
	switch $prompt_stripped_name
		case Majestix
			set prompt_hostname 333333
		case majestix
			set prompt_hostname 333333
	end

	set -l prompt_hostname_complement (complement_color $prompt_hostname)
	set -l prompt_username_complement (complement_color $prompt_username)

	# Prepare the prompt
	set -g prompt_part ''
	# Hostname
	set prompt_part "$prompt_part"(set_color -b $prompt_hostname; set_color $prompt_hostname_complement)"$prompt_stripped_name"(set_color $prompt_hostname)
	# Username
	set prompt_part "$prompt_part"(set_color -b $prompt_username)(set_color $prompt_username_complement; whoami)(set_color $prompt_username)
	# Start of working directory
	set prompt_part "$prompt_part"(set_color -b $prompt_path)(set_color ffffff)
end

function vcs_prompt_set_vars --description 'Set variables for vcs prompt'
	set -g __fish_git_prompt_show_informative_status 1
	set -g __fish_git_prompt_hide_untrackedfiles 1
	set -g vcs_reset_color (set_color reset)(set_color brwhite -b $prompt_vcs_branch)

	set -g __fish_git_prompt_color_branch 911cb1 --bold
	set -g __fish_git_prompt_showupstream "informative"
	set -g __fish_git_prompt_char_upstream_ahead $vcs_reset_color(set_color green --bold)"↑"$vcs_reset_color
	set -g __fish_git_prompt_char_upstream_behind $vcs_reset_color(set_color green --bold)"↓"$vcs_reset_color

	set -g __fish_git_prompt_char_stagedstate (set_color ddd224)"●"
	set -g __fish_git_prompt_char_dirtystate (set_color 2538dd)"+"
	set -g __fish_git_prompt_char_untrackedfiles (set_color black)"…"
	set -g __fish_git_prompt_char_conflictedstate (set_color red)"✖"
	set -g __fish_git_prompt_char_cleanstate (set_color green --bold)"✔"
	set -g __fish_git_prompt_char_stateseparator (set_color -b $prompt_vcs_status $prompt_vcs_branch)$prompt_right_arrow
	set -g __fish_git_prompt_prefix "a"
	set -g __fish_git_prompt_suffix "a"

	set -g __fish_git_prompt_color_suffix brwhite
end

# Cache colors
prepare_prompt
vcs_prompt_set_vars

function fish_prompt -d 'Write out the prompt'
	set -l s $status
	set -l duration $CMD_DURATION

	# Prepared part
	printf '%s' "$prompt_part"
	set -l len 13
	math "floor($COLUMNS / 2)" | read -l max_len

	# Current working directory
	shortpath (prompt_pwd) | read -l cwd
	printf '%s' $cwd
	math $len+(strwidth $cwd)-20 | read -l len

	set -l last_color $prompt_path
	set -l draw_arrow ""

	# Print git information
	fish_vcs_prompt | sed 's/[ ()]//g' | read -l git_info
	strwidth $git_info | read -l str_len
	if test -z $str_len
		set str_len 0
	end
	if test $str_len -gt 5
		set git_info (set_color -b $prompt_vcs_branch $last_color)$prompt_right_arrow$git_info
		printf '%s' $git_info
		set len (math $len + $str_len)
		set draw_arrow true
		set last_color $prompt_vcs_status
	end

	# Print current time
	date '+%d.%b %H:%M:%S' | read -l time_str
	set -l str_len (strwidth $time_str)
	math $len + $str_len | read -l new_len
	if test $new_len -lt $max_len
		set_color -b $prompt_time
		if test true = $draw_arrow
			set_color $prompt_vcs_status
			printf '%s' $prompt_right_arrow
			set draw_arrow ""
		end
		set_color ffffff
		printf '%s' $time_str
		set len $new_len
		set last_color $prompt_time
	end

	# Insert a new section if we want to print the duration or the exit status
	if test $duration -ge 100; or test $s -ne 0
		set_color -b $prompt_end
		if test true = $draw_arrow
			set_color $prompt_vcs_status
			printf '%s' $prompt_right_arrow
		end
		set_color aaaaaa
		# Write time of the last command if it took a bit longer
		if test $duration -ge 100
			format_time $duration
		end
		# Print return value of previous command
		set_color $fish_color_error
		if test $s -ne 0
			printf '%s' $s
		end
		set last_color $prompt_end
	end

	# End
	# set_color -b normal doesn't work, it also resets the foreground color
	printf "%s$prompt_right_arrow%s" \
		(set_color -b normal $last_color) (set_color normal)
end

#function fish_right_prompt -d 'Write out the right prompt'
#end
