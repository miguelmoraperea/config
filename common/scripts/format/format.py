"""Reformat file names."""
import argparse
import subprocess
import os
from collections import OrderedDict

CWD = os.getcwd()
IS_DRY_RUN = False
IS_TO_LOWER = False
IS_RECURSIVE = False
IS_FILE_ONLY = False
EXCLUDE_DIRS = []
SUBSTITUTE = None


class Rename:

    def run(self, name):
        tmp = name.lower() if IS_TO_LOWER else name
        tmp2 = tmp.replace(' ', '_')
        old = new = ''
        if SUBSTITUTE:
            old, new = SUBSTITUTE[0].split('/', maxsplit=1)
        return tmp2.replace(old, new) if SUBSTITUTE else tmp2


def main():
    global IS_DRY_RUN
    global IS_TO_LOWER
    global IS_RECURSIVE
    global IS_FILE_ONLY
    global EXCLUDE_DIRS
    global SUBSTITUTE

    parser = argparse.ArgumentParser(description='Reformat file names')
    parser.add_argument('targets', nargs='+', help='Targets to rename')
    parser.add_argument('-d', '--dry-run', action='store_true',
                        help='Only show what it would do.')
    parser.add_argument('-r', '--recursive', action='store_true',
                        help='Apply reformatting recursively')
    parser.add_argument('-l', '--lower', action='store_true',
                        help='Change to all lower case')
    parser.add_argument('-f', '--files', action='store_true',
                        help='Change files only, ignore dirs')
    parser.add_argument('-e', '--exclude_dirs', nargs=1, default=[],
                        help='Exclude the directories that match')
    parser.add_argument('-s', '--substitute', nargs=1,
                        help='Substitute with matching sequence')

    args = parser.parse_args()

    IS_DRY_RUN = args.dry_run
    IS_TO_LOWER = args.lower
    IS_RECURSIVE = args.recursive
    IS_FILE_ONLY = args.files
    EXCLUDE_DIRS = args.exclude_dirs
    SUBSTITUTE = args.substitute

    process(args.targets)


def process(targets):
    rename_cnt = 0
    renamed_targets = targets

    if IS_DRY_RUN:
        print('DRY-RUN', end='\n\n')

    if not IS_FILE_ONLY:
        # Rename dirs
        rename_dict, renamed_targets = find_dirs_to_rename(targets)
        for old_name, new_name in sorted(rename_dict.items(), reverse=True):
            rename_cnt += move_file(old_name, new_name)
        rename_dict.clear()

    # Rename files
    if IS_DRY_RUN:
        # Use originial targets
        renamed_targets = targets
    rename_dict = find_files_to_rename(renamed_targets)
    for old_name, new_name in sorted(rename_dict.items(), reverse=True):
        rename_cnt += move_file(old_name, new_name)

    if rename_cnt == 0:
        print('Not items found that need formatting.')


def find_dirs_to_rename(targets):
    rename = Rename()
    result = OrderedDict()
    renamed_targets = []

    for target in targets:
        if target in EXCLUDE_DIRS:
            continue
        if IS_RECURSIVE:
            for root, dirs, _ in os.walk(os.path.join(CWD, target)):
                dirs[:] = [dir for dir in dirs if dir not in EXCLUDE_DIRS]
                for dir in dirs:
                    full_path = os.path.join(root, dir)
                    result[full_path] = os.path.join(root, rename.run(dir))
        if os.path.isdir(target) and target not in EXCLUDE_DIRS:
            renamed_target = rename.run(target)
            result[target] = renamed_target
            renamed_targets.append(renamed_target)
        else:
            renamed_targets.append(target)

    return result, renamed_targets


def find_files_to_rename(targets):
    rename = Rename()
    result = OrderedDict()

    for target in targets:
        if target in EXCLUDE_DIRS:
            continue
        if IS_RECURSIVE:
            if os.path.isfile(target):
                result[target] = rename.run(target)
            for root, dirs, files in os.walk(os.path.join(CWD, target)):
                dirs[:] = [dir for dir in dirs if dir not in EXCLUDE_DIRS]
                for file in files:
                    full_path = os.path.join(root, file)
                    result[full_path] = os.path.join(root, rename.run(file))
        else:
            result[target] = os.path.join(rename.run(target))

    return result


def move_file(target, new_name):
    src = os.path.join(CWD, target)
    dest = os.path.join(CWD, new_name)
    scaped_chars = str.maketrans(
        {"(": r"\(", ")": r"\)", " ": r"\ ", "'": r"\'", "&": r"\&"})
    scaped_src = src.translate(scaped_chars)
    scaped_dest = dest.translate(scaped_chars)
    if src == dest:
        return 0
    if not IS_DRY_RUN:
        move(scaped_src, scaped_dest)
    print_message(target, new_name)
    return 1


def move(src, dest):
    cmd = f'mv {src} {dest}'
    subprocess.call(cmd, shell=True)


def print_message(old_path, new_path):
    word = '-->'
    if IS_DRY_RUN:
        word = '~~>'
    old_name = os.path.basename(old_path)
    new_name = os.path.basename(new_path)
    print(f'{old_name:<50} {word:} {new_name}')


if __name__ == '__main__':
    main()
