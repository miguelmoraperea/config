"""Reformat file names."""
import argparse
import subprocess
import os

CWD = os.getcwd()
IS_DRY_RUN = False
IS_TO_LOWER = False
IS_RECURSIVE = False


class Rename:

    def run(self, name):
        tmp = name.lower() if IS_TO_LOWER else name
        return tmp.replace(' ', '_')


def main():
    global IS_DRY_RUN
    global IS_TO_LOWER
    global IS_RECURSIVE

    parser = argparse.ArgumentParser(description='Reformat file names')
    parser.add_argument('targets', nargs='+', help='Targets to rename')
    parser.add_argument('-d', '--dry-run', action='store_true',
                        help='Only show what it would do.')
    parser.add_argument('-r', '--recursive', action='store_true',
                        help='Apply reformatting recursively')
    parser.add_argument('-l', '--lower', action='store_true',
                        help='Change to all lower case')

    args = parser.parse_args()

    IS_DRY_RUN = args.dry_run
    IS_TO_LOWER = args.lower
    IS_RECURSIVE = args.recursive

    process(args.targets)


def process(targets):
    rename = Rename()
    rename_targets = {}

    if IS_DRY_RUN:
        print('DRY-RUN', end='\n\n')

    for target in targets:
        if IS_RECURSIVE:
            rename_targets.update(recurse(target))
        else:
            rename_targets[target] = rename.run(target)

    for old_name, new_name in rename_targets.items():
        move_file(old_name, new_name)


def recurse(root):
    rename = Rename()
    result = {}

    for root, _, files in os.walk(os.path.join(CWD, root)):
        for file in files:
            result[os.path.join(root, file)] = os.path.join(root, rename.run(file))

    return result

def move_file(target, new_name):
    if not IS_DRY_RUN:
        move(target, new_name)
    print_message(target, new_name)


def move(target, new_name):
    src = os.path.join(CWD, target.replace(' ', '\ '))
    dest = os.path.join(CWD, new_name)
    cmd = f'mv {src} {dest}'
    subprocess.call(cmd, shell=True)


def print_message(old_name, new_name):
    word = '-->'
    if IS_DRY_RUN:
        word = '~~>'
    print(f'{os.path.basename(old_name):<50} {word:} {os.path.basename(new_name)}')


if __name__ == '__main__':
    main()
