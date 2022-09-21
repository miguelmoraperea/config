import unittest

from format import Rename


class TestRename(unittest.TestCase):

    def test_rename_to_lowercase(self):
        rename = Rename()
        self.assertEqual('some_file_name', rename.run('SOME_FILE_NAME'))
        self.assertEqual('some_file_name', rename.run('Some File Name'))

    def test_substitute_spaces_to_underscore(self):
        rename = Rename()
        self.assertEqual('some_file_name', rename.run('some file name'))


if __name__ == '__main__':
    unittest.main()
