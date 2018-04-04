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

# Aliases
if command -v nvim > /dev/null
	alias vi nvim
end
alias pls sudo
complete -c pls -d "Command to run" -x -a "(__fish_complete_subcommand_root -u -g)"
alias ll 'ls -Ahl'
alias la 'ls -ahl'
alias lolcat 'lolcat -f -t'
alias sc systemctl
alias scu 'systemctl --user'

alias git 'git -c color.ui=always'

# Include local config
if test -e "$HOME/.config/fish/localconfig.fish"
	source "$HOME/.config/fish/localconfig.fish"
end

# Useful git functions
function gitl --description 'Print oneline log of the last n commits'
	# Without pager
	git log --oneline --first-parent -$argv | cat
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

function mydisown
	# Double fork
	fish -c "$argv &"
end
complete -c mydisown -d "Command to run" -x -a "(__fish_complete_subcommand -u -g)"

function create -d 'Create and edit an executable file' -a name
	echo "#!/usr/bin/env bash" > "$name"
	chmod +x "$name"
	vi "$name"
end

function time -d 'Wrapper for bash time'
	bash -c "time $argv"
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

function get_color -d 'Compute a color based on a string'
	printf '%s' "$argv" | md5sum | cut -c1-6
end

function format_time -d 'Adaptively format the given time in ms' -a millis
	if test "$millis" -lt 1000 # Milliseconds
		printf '%dms' "$millis"
	else if test "$millis" -lt 60000 # Seconds
		printf '%d.%02ds' (math "$millis" / 1000) (math "$millis" / 10 \% 100)
	else
		set total_seconds (math $millis / 1000)
		set seconds (math $total_seconds \% 60)
		set minutes (math \($total_seconds / 60\) \% 60)
		set hours (math \($total_seconds / 3600\) \% 24)
		set days (math $total_seconds / 86400)
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
	printf '%s' "$path" | awk '{
		start = 1;
		end = split($0, ar, "/");
		if (end > 3)
			start = end - 2;
		for (i = start; i <= end; i++) {
			if (i != end)
				printf("%s/", substr(ar[i], 1, 1))
			else
				printf("%s", ar[i])
		}
	}'
end

function prepare_prompt -d 'Compute the colors and values used in the prompt'
	set -l prompt_stripped_name (hostname | cut -d . -f 1)

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

	# Overwrite colors
	switch $prompt_stripped_name
		case Majestix
			set prompt_hostname 333333
	end

	set -l prompt_hostname_complement (complement_color $prompt_hostname)
	set -l prompt_username_complement (complement_color $prompt_username)

	# Prepare the prompt
	set -g prompt_part ''
	# Hostname
	set prompt_part "$prompt_part"(set_color -b $prompt_hostname; set_color $prompt_hostname_complement)"$prompt_stripped_name"(set_color $prompt_hostname)
	# Username
	#set prompt_part "$prompt_part"(set_color -b $prompt_username)\ue0b0(set_color $prompt_username_complement; whoami)(set_color $prompt_username)
	set prompt_part "$prompt_part"(set_color -b $prompt_username)(set_color $prompt_username_complement; whoami)(set_color $prompt_username)
	# Start of working directory
	#set prompt_part "$prompt_part"(set_color -b $prompt_path)\ue0b0(set_color ffffff)
	set prompt_part "$prompt_part"(set_color -b $prompt_path)(set_color ffffff)
end

# Cache colors
prepare_prompt

function fish_prompt -d 'Write out the prompt'
	# Powerline chars: E0B0-E0B3
	set -l s $status

	# Prepared part
	printf '%s' "$prompt_part"
	set -l len 13
	math "$COLUMNS/2" | read -l max_len

	# Current working directory
	shortpath (prompt_pwd) | read -l cwd
	printf '%s' "$cwd"
	math $len+(echo "$cwd" | wc -m) | read -l len

	# Print git information
	__informative_git_prompt | read -l git_info
	math (echo "$git_info" | wc -m)-40 | read -l str_len
	if test "$str_len" -gt 0
		math "$len+$str_len" | read -l new_len
		if test "$new_len" -lt "$max_len"
			printf '%s' "$git_info"
			set len "$new_len"
		end
	else
		__informative_git_prompt
	end

	set_color $prompt_path
	set -l last_color $prompt_path

	# Print current time
	# Reset bold
	set_color normal
	set_color -b $prompt_time
	set_color ffffff
	date '+%d.%b %H:%M:%S' | read -l time_str
	echo "$time_str" | wc -m | read -l str_len
	math "$len+$str_len" | read -l new_len
	if test "$new_len" -lt "$max_len"
		printf '%s' "$time_str"
		set len "$new_len"
		set_color $prompt_time
		set last_color $prompt_time
	end

	# Insert a new section if we want to print the duration or the exit status
	set -l duration $CMD_DURATION
	if test "$duration" -ge 100; or test $s -ne 0
		#printf '%s\ue0b0%s' \
		printf '%s%s' \
			(set_color -b $prompt_end) (set_color aaaaaa)
		set last_color $prompt_end
		# Write time of the last command if it took a bit longer
		if test "$duration" -ge 100
			format_time "$duration"
		end
		# Print return value of previous command
		set_color cc2266
		# Or $fish_color_error
		if test $s -ne 0
			printf '%s' $s
		end
	end

	# End
	# set_color -b normal doesn't work, it also resets the foreground color
	printf '%s\ue0b0%s' \
		(set_color normal; set_color $last_color) (set_color normal)
end

#function fish_right_prompt -d 'Write out the right prompt'
#end
