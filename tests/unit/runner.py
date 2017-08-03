import unittest
import imp
import os
import sys

class TestCloudRunner(unittest.TestCase):

    def tearDown(self):
        pass

    def test_available_machine_numbers_with_empty_machine_list(self):
        own_stack_runner = imp.load_source('own_stack_runner',
                os.path.join(os.path.dirname(sys.argv[0]), '../../saltstack/salt/_runners/own_stack.py'))
        nums = own_stack_runner.av_name_numbers('web-', 5, [])
        self.assertListEqual([1, 2, 3, 4, 5], nums)

    def test_available_machine_numbers_with_in_between_numbers(self):
        own_stack_runner = imp.load_source('own_stack_runner',
                os.path.join(os.path.dirname(sys.argv[0]), '../../saltstack/salt/_runners/own_stack.py'))
        nums = own_stack_runner.av_name_numbers('web-', 5, ['web-1', 'web-5', 'web-6'])
        self.assertListEqual([2, 3, 4, 7, 8], nums)

    def test_parse_scale_profile_args_decrease_by_positive_int(self):
        own_stack_runner = imp.load_source('own_stack_runner',
                os.path.join(os.path.dirname(sys.argv[0]), '../../saltstack/salt/_runners/own_stack.py'))
        machines_by_profile = {'dev-jobs': ['dev-jobs-1', 'dev-jobs-2'], 'dev-web': ['dev-web-1', 'dev-web-2']}
        result = own_stack_runner._parse_scale_args({'profiles': {'dev-jobs': 1}}, machines_by_profile)
        self.assertEqual(result['dev-jobs'], -1)

    def test_parse_scale_profile_args_decrease_by_negative_int(self):
        own_stack_runner = imp.load_source('own_stack_runner',
                os.path.join(os.path.dirname(sys.argv[0]), '../../saltstack/salt/_runners/own_stack.py'))
        machines_by_profile = {'dev-jobs': ['dev-jobs-1', 'dev-jobs-2'], 'dev-web': ['dev-web-1', 'dev-web-2']}
        result = own_stack_runner._parse_scale_args({'profiles': {'dev-jobs': -1}}, machines_by_profile)
        self.assertEqual(result['dev-jobs'], -1)

    def test_parse_scale_profile_args_decrease_by_negative_int_string(self):
        own_stack_runner = imp.load_source('own_stack_runner',
                os.path.join(os.path.dirname(sys.argv[0]), '../../saltstack/salt/_runners/own_stack.py'))
        machines_by_profile = {'dev-jobs': ['dev-jobs-1', 'dev-jobs-2'], 'dev-web': ['dev-web-1', 'dev-web-2']}
        result = own_stack_runner._parse_scale_args({'profiles': {'dev-jobs': '-1'}}, machines_by_profile)
        self.assertEqual(result['dev-jobs'], -1)

    def test_parse_scale_profile_args_increase_by_positive_int(self):
        own_stack_runner = imp.load_source('own_stack_runner',
                os.path.join(os.path.dirname(sys.argv[0]), '../../saltstack/salt/_runners/own_stack.py'))
        machines_by_profile = {'dev-jobs': ['dev-jobs-1', 'dev-jobs-2'], 'dev-web': ['dev-web-1', 'dev-web-2']}
        result = own_stack_runner._parse_scale_args({'profiles': {'dev-jobs': 4}}, machines_by_profile)
        self.assertEqual(result['dev-jobs'], 2)

    def test_parse_scale_profile_args_increase_by_positive_int_string(self):
        own_stack_runner = imp.load_source('own_stack_runner',
                os.path.join(os.path.dirname(sys.argv[0]), '../../saltstack/salt/_runners/own_stack.py'))
        machines_by_profile = {'dev-jobs': ['dev-jobs-1', 'dev-jobs-2'], 'dev-web': ['dev-web-1', 'dev-web-2']}
        result = own_stack_runner._parse_scale_args({'profiles': {'dev-jobs': '+2'}}, machines_by_profile)
        self.assertEqual(result['dev-jobs'], 2)

if __name__ == '__main__':
    unittest.main()
