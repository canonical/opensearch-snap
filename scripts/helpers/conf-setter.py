#!/usr/bin/python
import ast
import json
import sys
from argparse import ArgumentParser
from collections.abc import Mapping
from enum import Enum

import ruamel.yaml.nodes
from ruamel.yaml import YAML

"""Utilities for editing yaml configuration files at any level of nestedness."""


class OutputType(Enum):
    file = 'file'
    console = 'console'
    all = 'all'

    def __str__(self):
        return self.value


def __deep_update(source, node_keys: list[str], val: object):
    if not node_keys:
        return val

    if source is None:
        if node_keys[0].startswith('['):
            source = []
        else:
            source = {}

    current_key: str = node_keys.pop(0)

    # handling the insert / update on json objects
    if isinstance(source, Mapping):
        current_val = source.get(current_key, None)
        source[current_key] = __deep_update(current_val, node_keys, val)
        return source

    # handling the insert / update on arrays
    if isinstance(source, list):
        target_index = __target_array_index(source, current_key)
        if target_index == -1:
            source.append(__deep_update(None, node_keys, val))
        else:
            source[target_index] = __deep_update(source[target_index], node_keys, val)

        return source

    return source


def __deep_delete(source, node_keys: list[str]):
    if not node_keys:
        return

    if source is None:
        return

    leaf_level = __leaf_level(source, node_keys)
    leaf_key = node_keys.pop(0)

    if leaf_key in leaf_level and (isinstance(leaf_level[leaf_key], Mapping) or not leaf_key.startswith('[')):
        del leaf_level[leaf_key]
        return

    # list
    target_index = __target_array_index(leaf_level, leaf_key)
    del leaf_level[target_index]


def __leaf_level(current, node_names: list[str]):
    if len(node_names) == 1:
        return current

    current_key = node_names.pop(0)
    if current_key.startswith('[') and current_key.endswith(']'):
        target_index = __target_array_index(current, current_key)
        return __leaf_level(current[target_index], node_names)

    return __leaf_level(current[current_key], node_names)


def __target_array_index(source: list, node_key: str) -> int:
    str_index = node_key[1:-1].strip()

    index = None

    # where user provides a key [key:val] or [key]
    if str_index and not str_index.isnumeric():
        key = str_index.split(':')
        if len(key) == 1:
            index = source.index(str_index)
        else:
            index = -1
            for elt, i in zip(source, range(len(source))):
                if elt.get(key[0], None) == key[1]:
                    index = i
                    break

            if index == -1:
                raise ValueError(f'{str_index} not found in the object.')

    exists = index is not None or (str_index and (int(str_index) < len(source)))
    if not exists:
        return -1

    return int(str_index) if index is None else index


def __inline_array_format(data, node_keys: list[str], val: object):

    def __flow_style():
        ret = ruamel.yaml.CommentedSeq()
        ret.fa.set_flow_style()
        return ret

    leaf_k = node_keys[-1]
    leaf_l = __leaf_level(data, node_keys)
    leaf_l[leaf_k] = __flow_style()
    leaf_l[leaf_k].extend(val)

    return data


def put(target_file: str, key_path: str, val: object, sep='/',
        output_type: OutputType = OutputType.all, inline_array: bool = False):

    yaml = YAML()

    with open(target_file, mode='r') as f:
        data = yaml.load(f)

    data = __deep_update(data, key_path.split(sep), val)

    if inline_array:
        data = __inline_array_format(data, key_path.split(sep), val)

    if output_type in [OutputType.all, OutputType.console]:
        yaml.dump(data, sys.stdout)

    if output_type in [OutputType.all, OutputType.file]:
        with open(target_file, mode='w') as f:
            yaml.dump(data, f)


def delete(target_file: str, key_path: str, sep='/',
           output_type: OutputType = OutputType.all):

    yaml = YAML()

    with open(target_file, mode='r') as f:
        data = yaml.load(f)

    __deep_delete(data, key_path.split(sep))

    if output_type in [OutputType.all, OutputType.console]:
        yaml.dump(data, sys.stdout)

    if output_type in [OutputType.all, OutputType.file]:
        with open(target_file, mode='w') as f:
            yaml.dump(data, f)


def parse_args():

    def __single_char_arg(input_val: str) -> str:
        clean_input = input_val.strip()
        if len(clean_input) == 1:
            return clean_input

        raise ValueError('Expected single character.')

    def __body_value_arg(input_val):
        if input_val.isnumeric():
            return int(input_val)

        if input_val.startswith('{') and input_val.endswith('}'):
            return json.loads(input_val)

        if input_val.startswith('[') and input_val.endswith(']'):
            return ast.literal_eval(input_val)

        return input_val

    def __parse():
        parser = ArgumentParser(description='Utility script for editing YAML conf files.')

        parser.add_argument('-f', '--file',
                            type=str,
                            required=True,
                            help='Path of the source/target YAML file.')

        parser.add_argument('-k', '--key',
                            type=str,
                            required=True,
                            help='Key of the element to target.')

        parser.add_argument('-v', '--value',
                            type=__body_value_arg,
                            required=False,
                            help='New value to set - for complex data types, this should be formatted as list / dict.')

        parser.add_argument('-i', '--inline-array',
                            type=bool,
                            required=False,
                            default=False,
                            help='If value is an array of simple values (str, int etc.), whether to write it between '
                                 'square brackets on the same line or as a multiline yaml list.')

        parser.add_argument('-s', '--sep',
                            type=__single_char_arg,
                            default='/',
                            required=False,
                            help='Separator character for traversal.')

        parser.add_argument('-o', '--out',
                            type=OutputType,
                            choices=list(OutputType),
                            default=OutputType.all,
                            required=False,
                            help='Output type of the transformation.')

        parser.add_argument('-d', '--delete',
                            type=bool,
                            default=False,
                            required=False,
                            help='Delete node (Not implemented).')

        return parser.parse_args()

    return __parse()


if __name__ == "__main__":
    args = parse_args()

    if args.delete:
        delete(args.file,
               args.key,
               sep=args.sep,
               output_type=args.out)
    else:
        put(args.file,
            args.key,
            args.value,
            sep=args.sep,
            output_type=args.out,
            inline_array=args.inline_array)

    # path = 'opensearch_put.yml'
    # put(path, 'cluster.name', 'new_name')
    # put(path, 'cluster.core/target.obj/key3/key3.a/obj', {'a': 'new_name_1', 'b': ['hello', 'world']})
    # put(path, 'cluster.core/target.arr.simple/[0]', 'hello')
    # put(path, 'cluster.core/target.arr.complex/[name:complex3]', {'a': 'new_name_1', 'b': ['hello', 'world']})
    # put(path, 'cluster.core/target.arr.complex/[name:complex5]/val/key', 'new_val25')
    # put(path, 'cluster.core/target.arr.complex/[0]/val', 'complex2_updated')
    # put(path, 'cluster.core/target.arr.complex/[0]/new_val/new_sub_key', 'updated')
