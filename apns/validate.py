#!/usr/bin/env python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

import sys

import xmlschema

schema = xmlschema.XMLSchema('apns-conf.xsd')

if __name__ == '__main__':
    ret = 0

    for xml_path in sys.argv[1:]:
        try:
            schema.validate(xml_path)
        except xmlschema.XMLSchemaValidationError as e:
            print(xml_path, e, file=sys.stderr)
            ret = -1

    exit(ret)
