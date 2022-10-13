# pylint: disable=missing-module-docstring, missing-class-docstring, missing-function-docstring

import os
import unittest
import subprocess
import shutil
from random import randint
import hashlib
from checksumdir import dirhash

from pathlib import Path

PWD = os.path.dirname(os.path.realpath(__file__))
TEST_DIR = os.path.join(PWD, 'test')


def _create_file(file_name):
    file_path = os.path.join(TEST_DIR, file_name)
    Path(file_path).touch()
    _add_random_content_to_file(file_path)
    return _hashfile(file_path)


def _add_random_content_to_file(file_path):
    with open(file_path, 'w') as file:
        file.write(str(randint(0, 10000)))


def _hashfile(file):
    buf_size = 65536
    sha256 = hashlib.sha256()
    with open(file, 'rb') as file:
        while True:
            data = file.read(buf_size)
            if not data:
                break
            sha256.update(data)
    return sha256.hexdigest()


def _hashdir(directory):
    return dirhash(directory, 'sha256')


def _create_dir(dir_name):
    Path(os.path.join(TEST_DIR, dir_name)).mkdir()


def _remove_file(file_path):
    Path(file_path).unlink()


def _remove_dir(dir_path):
    shutil.rmtree(dir_path, ignore_errors=True)


def _remove_dir_and_files(root_dir):
    shutil.rmtree(os.path.join(TEST_DIR, root_dir), ignore_errors=True)


def _create_test_dir():
    _remove_dir(TEST_DIR)
    Path(TEST_DIR).mkdir()


class TestRenameFile(unittest.TestCase):

    _test_file_name = 'TEST FILE'

    def setUp(self):
        _create_test_dir()
        os.chdir(TEST_DIR)
        self._expected_hash = _create_file(self._test_file_name)

    def tearDown(self):
        _remove_dir(TEST_DIR)

    def test_rename_file_remove_spaces(self):
        expected_name = self._test_file_name.replace(' ', '_')
        expected_path = os.path.join(TEST_DIR, expected_name)
        subprocess.run(['frmt', f'{self._test_file_name}'],
                       check=True, stdout=subprocess.DEVNULL)

        self.assertEqual(True, os.path.exists(expected_path))
        self.assertEqual(self._expected_hash, _hashfile(expected_path))
        _remove_file(expected_path)

    def test_rename_file_convert_to_lowercase(self):
        expected_name = self._test_file_name.replace(' ', '_').lower()
        expected_path = os.path.join(TEST_DIR, expected_name)
        subprocess.run(
            ['frmt', '-l', f'{self._test_file_name}'], check=True, stdout=subprocess.DEVNULL)

        self.assertEqual(True, os.path.exists(expected_path))
        self.assertEqual(self._expected_hash, _hashfile(expected_path))
        _remove_file(expected_path)

    def test_dry_run_does_not_modify_the_file(self):
        expected_name = self._test_file_name.replace(' ', '_')
        original_path = os.path.join(TEST_DIR, self._test_file_name)
        expected_path = os.path.join(TEST_DIR, expected_name)
        subprocess.run(
            ['frmt', '-d', f'{self._test_file_name}'], check=True, stdout=subprocess.DEVNULL)

        self.assertEqual(True, os.path.exists(original_path))
        self.assertEqual(False, os.path.exists(expected_path))
        self.assertEqual(self._expected_hash, _hashfile(original_path))
        _remove_file(original_path)


class TestRenameDirectory(unittest.TestCase):

    _test_dir_name = 'TEST DIR'

    def setUp(self):
        _create_test_dir()
        os.chdir(TEST_DIR)
        _create_dir(self._test_dir_name)

    def tearDown(self):
        _remove_dir(TEST_DIR)

    def test_rename_directory_remove_spaces(self):
        expected_name = self._test_dir_name.replace(' ', '_')
        expected_path = os.path.join(TEST_DIR, expected_name)
        subprocess.run(['frmt', f'{self._test_dir_name}'],
                       check=True, stdout=subprocess.DEVNULL)
        self.assertEqual(True, os.path.exists(expected_path))
        _remove_dir(expected_path)

    def test_rename_directory_covert_to_lowercase(self):
        expected_name = self._test_dir_name.replace(' ', '_').lower()
        expected_path = os.path.join(TEST_DIR, expected_name)
        subprocess.run(
            ['frmt', '-l', f'{self._test_dir_name}'], check=True, stdout=subprocess.DEVNULL)
        self.assertEqual(True, os.path.exists(expected_path))
        _remove_dir(expected_path)

    def test_dry_run_does_not_modify_the_dir(self):
        expected_name = self._test_dir_name.replace(' ', '_')
        original_path = os.path.join(TEST_DIR, self._test_dir_name)
        expected_path = os.path.join(TEST_DIR, expected_name)
        subprocess.run(
            ['frmt', '-d', f'{self._test_dir_name}'], check=True, stdout=subprocess.DEVNULL)
        self.assertEqual(True, os.path.exists(original_path))
        self.assertEqual(False, os.path.exists(expected_path))
        _remove_dir(original_path)


class TestRenameRecursiveFiles(unittest.TestCase):

    _tree = {
        'TEST DIR 1': {
            'TEST FILE 1': None,
            'TEST DIR 2': {
                'TEST FILE 2': None,
                'TEST DIR 3': {
                    'TEST FILE 3': None,
                }
            }
        }
    }

    def setUp(self):
        _create_test_dir()
        os.chdir(TEST_DIR)
        self._create_test_tree()

    def tearDown(self):
        _remove_dir(TEST_DIR)

    def _create_test_tree(self):
        self._create_dirs_and_files_from_tree(TEST_DIR, self._tree)

    def _create_dirs_and_files_from_tree(self, root_pwd, tree_dict):
        for key, val in tree_dict.items():
            full_path = os.path.join(root_pwd, key)
            if isinstance(val, dict):
                Path(full_path).mkdir()
                self._create_dirs_and_files_from_tree(full_path, val)
            else:
                Path(full_path).touch()

    def _assert_trees_are_equal(self, expected_tree, root_dir):
        for key, val in expected_tree.items():
            new_key = key.replace(' ', '_')
            new_path = os.path.join(root_dir, new_key)
            self.assertEqual(True, os.path.exists(new_path))

            if isinstance(key, dict):
                self._assert_trees_are_equal(val, new_path)

    def test_recursive(self):
        expected_tree = {
            'TEST_DIR_1': {
                'TEST_FILE_1': None,
                'TEST_DIR_2': {
                    'TEST_FILE_2': None,
                    'TEST_DIR_3': {
                        'TEST_FILE_3': None,
                    }
                }
            }
        }
        hash_tree_before = _hashdir(TEST_DIR)
        subprocess.run(['frmt', '-r', 'TEST DIR 1'],
                       check=True, stdout=subprocess.DEVNULL)
        self._assert_trees_are_equal(expected_tree, TEST_DIR)
        self.assertEqual(hash_tree_before, _hashdir(TEST_DIR))
        _remove_dir_and_files('TEST_DIR_1')


if __name__ == '__main__':
    unittest.main()
