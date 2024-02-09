# TODO: Convert this to fish
# /usr/bin/vmtoolsd -n vmusr & > /dev/null 2>&1

if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_user_key_bindings
    fish_vi_key_bindings
    bind -M insert \cf accept-autosuggestion
    bind \cf accept-autosuggestion
end

# You can override some default options with config.fish:
#
#  set -g theme_short_path yes
#  set -g theme_stash_indicator yes
#  set -g theme_ignore_ssh_awareness yes

function fish_prompt
  set -l last_command_status $status
  set -l cwd

  if test "$theme_short_path" = 'yes'
    set cwd (basename (prompt_pwd))
  else
    set cwd (prompt_pwd)
  end

  set -l fish     "⋊>"
  set -l ahead    "↑"
  set -l behind   "↓"
  set -l diverged "⥄"
  set -l dirty    "⨯"
  set -l stash    "≡"
  set -l none     "◦"

  set -l normal_color     (set_color normal)
  set -l success_color    (set_color cyan)
  set -l error_color      (set_color $fish_color_error 2> /dev/null; or set_color red --bold)
  set -l directory_color  (set_color $fish_color_quote 2> /dev/null; or set_color brown)
  set -l repository_color (set_color $fish_color_cwd 2> /dev/null; or set_color green)

  set -l prompt_string $fish

  if test "$theme_ignore_ssh_awareness" != 'yes' -a -n "$SSH_CLIENT$SSH_TTY"
    set prompt_string "$fish "(whoami)"@"(hostname -s)" $fish"
  end

  if test $last_command_status -eq 0
    echo -n -s $success_color $prompt_string $normal_color
  else
    echo -n -s $error_color $prompt_string ' ' $last_command_status $normal_color
  end

  if git_is_repo
    if test "$theme_short_path" = 'yes'
      set root_folder (command git rev-parse --show-toplevel 2> /dev/null)
      set parent_root_folder (dirname $root_folder)
      set cwd (echo $PWD | sed -e "s|$parent_root_folder/||")
    end

    echo -n -s " " $directory_color $cwd $normal_color
    echo -n -s " on " $repository_color (git_branch_name) $normal_color " "


    set -l list
    if test "$theme_stash_indicator" = yes; and git_is_stashed
      set list $list $stash
    end
    if git_is_touched
      set list $list $dirty
    end
    echo -n $list

    if test -z "$list"
      echo -n -s (git_ahead $ahead $behind $diverged $none)
    end
  else
    echo -n -s " " $directory_color $cwd $normal_color
  end

  echo -n -s " "
end



# Perforce Aliases
function p4_unshelve --description 'Unshelve a changelist'
    p4 unshelve -f -s $argv[1] -c $argv[1]
end

function p4_shelve --description 'Shelve a changelist and delete files for add from the workspace'
    p4 shelve -f -c $argv[1]
    p4 revert -w -c $argv[1] //...
end

function p4_revert --description 'Revert a changelist and delete files for add from the workspace'
    p4 revert -w //...
end


# Add to path
fish_add_path ~/Desktop/git/config/common/scripts
# fish_add_path ~/apps/nvim-linux64/bin
fish_add_path ~/apps/p4v-2023.2.2446649/bin
fish_add_path ~/apps/pdiff
fish_add_path ~/.cargo/bin
fish_add_path ~/apps/apache-maven-3.9.3/bin
fish_add_path ~/apps/gradle-8.3/bin
# fish_add_path ~/apps/zulu8.36.0.2-sa-jdk8.0.202-linux_x64/bin


# Enviroment variables
# set -x JAVA_HOME /usr/lib/jvm/zulu-8-amd64
set -x M2_HOME /home/mmora/apps/apache-maven-2.2.1
# set -x JAVA_HOME /usr/lib/jvm/java-19-openjdk-amd64
# set -x JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64
# set -x JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
set -x JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
set -x M2_HOME /home/mmora/apps/apache-maven-3.9.3

function im
  . ~/Desktop/nvim_venv/bin/activate.fish && nvim $argv
end
