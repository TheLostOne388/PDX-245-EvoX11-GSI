#!/usr/bin/env python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

import sys
from xml.etree import ElementTree
from xml.sax.saxutils import escape

apn_attribute_order = ['mcc', 'mnc', 'carrier', 'apn']


def sort_apn_attributes(item):
    key, _ = item
    try:
        return (0, apn_attribute_order.index(key))
    except ValueError:
        return (1, key)


def pretty_apn(elem, indent):
    attrs = sorted(elem.attrib.items(), key=sort_apn_attributes)
    lines = [f'{indent}<{elem.tag}']
    for k, v in attrs:
        lines.append(f'{indent}    {k}="{escape(v)}"')
    lines.append(f'{indent}/>')
    return '\n'.join(lines)


def format_elem(elem, depth=0):
    indent = ' ' * 4 * depth
    out = []

    if elem.tag == 'apn':
        out.append(pretty_apn(elem, indent))
    else:
        attrs = ' '.join(f'{k}="{v}"' for k, v in elem.attrib.items())
        if attrs:
            out.append(f'{indent}<{elem.tag} {attrs}>')
        else:
            out.append(f'{indent}<{elem.tag}>')

        for child in sorted(
            elem,
            key=lambda e: tuple(
                e.get(attr) or '' for attr in apn_attribute_order
            ),
        ):
            out.append(format_elem(child, depth + 1))

        out.append(f'{indent}</{elem.tag}>')

    return '\n'.join(out)


def process_file(xml_path):
    tree = ElementTree.parse(xml_path)
    formatted = format_elem(tree.getroot())

    with open(xml_path, 'w', encoding='utf-8') as f:
        header = [
            '<?xml version="1.0" encoding="utf-8"?>',
            '<!--',
            '    SPDX-FileCopyrightText: Google Inc',
            '    SPDX-FileCopyrightText: The LineageOS Project',
            '    SPDX-License-Identifier: Apache-2.0',
            '-->\n',
        ]
        f.write('\n'.join(header))
        f.write(formatted + '\n')


if __name__ == '__main__':
    for xml_path in sys.argv[1:]:
        process_file(xml_path)
