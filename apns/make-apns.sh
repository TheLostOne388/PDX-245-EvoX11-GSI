#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

APNS="<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
APNS+="<!--\n"
APNS+="    SPDX-FileCopyrightText: Google Inc\n"
APNS+="    SPDX-FileCopyrightText: The LineageOS Project\n"
APNS+="    SPDX-License-Identifier: Apache-2.0\n"
APNS+="-->\n"
APNS+="<apns version=\"8\" xmlns:xi=\"http://www.w3.org/2001/XInclude\">\n"

for f in "$@"; do
    APNS+="<!-- $f -->\n"
    APNS+="<xi:include href=\"$f\" xpointer=\"xpointer(apns/*)\"/>\n"
done

APNS+="</apns>\n"

printf "$APNS" | "${XMLLINT:-xmllint}" --format --nofixup-base-uris --xinclude -
