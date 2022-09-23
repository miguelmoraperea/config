"""Reformat file names."""
import argparse
import subprocess
import os

CWD = os.getcwd()
IS_DRY_RUN = False
IS_TO_LOWER = False
IS_RECURSIVE = False
IS_FILE_ONLY = False


class Rename:

    def run(self, name):
        tmp = name.lower() if IS_TO_LOWER else name
        return tmp.replace(' ', '_')


def main():
    global IS_DRY_RUN
    global IS_TO_LOWER
    global IS_RECURSIVE
    global IS_FILE_ONLY

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

    args = parser.parse_args()

    IS_DRY_RUN = args.dry_run
    IS_TO_LOWER = args.lower
    IS_RECURSIVE = args.recursive
    IS_FILE_ONLY = args.files

    process(args.targets)


def process(targets):
    rename_dict = {}

    if IS_DRY_RUN:
        print('DRY-RUN', end='\n\n')

    rename_dict = find_elements_to_rename(targets)
    rename_cnt = 0

    for old_name, new_name in rename_dict.items():
        rename_cnt += move_file(old_name, new_name)

    if rename_cnt == 0:
        print('Not items found that need formatting.')


def find_elements_to_rename(targets):
    rename = Rename()
    result = {}

    for target in targets:
        if IS_RECURSIVE:
            result[target] = rename.run(target)
            for root, dirs, files in os.walk(os.path.join(CWD, target)):
                nodes = files + dirs
                for node in nodes:
                    full_path = os.path.join(root, node)
                    if IS_FILE_ONLY and os.path.isdir(full_path):
                        continue
                    result[full_path] = os.path.join(root, rename.run(node))
        else:
            if IS_FILE_ONLY and os.path.isdir(target):
                continue
            result[target] = rename.run(target)

    return result


def move_file(target, new_name):
    src = os.path.join(CWD, target)
    dest = os.path.join(CWD, new_name)
    scaped_chars = str.maketrans({"(": r"\(", ")": r"\)", " ": r"\ "})
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
