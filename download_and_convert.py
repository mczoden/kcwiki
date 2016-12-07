#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function
import os
import re
import time
import sys
if sys.version > '3':
    import urllib.request
else:
    import urllib2


SHIP_DATA_CODE_URL = '''https://zh.kcwiki.moe/wiki/\
%E6%A8%A1%E5%9D%97:%E8%88%B0%E5%A8%98%E6%95%B0%E6%8D%AE'''
SHIP_DATA_HISTORY_URL = '''https://zh.kcwiki.moe/index.php?\
title=%E6%A8%A1%E5%9D%97:%E8%88%B0%E5%A8%98%E6%95%B0%E6%8D%AE\
&offset=&limit=1&action=history'''
SHIP_LIST_HISTORY_URL = '''https://zh.kcwiki.moe/index.php?\
title=%E8%88%B0%E5%A8%98%E5%88%97%E8%A1%A8&offset=&limit=1&action=history'''
TIMEOUT_IN_SECOND = 10


class KcError(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


def do_download(url):
    ret = ''

    if sys.version > '3':
        with urllib.request.urlopen(url=url, timeout=TIMEOUT_IN_SECOND) as f:
            ret = f.read().decode('utf8')
    else:
        #
        # if python version < 2.6
        # urlopen doesn't support parameter 'timeout'
        urllib2.socket.setdefaulttimeout(TIMEOUT_IN_SECOND)
        ret = urllib2.urlopen(url).read()

    return ret


def get_last_upate_time_from_wiki(url):
    pattern = re.compile(r'mw-changeslist-date.+\>(\d\d\d\d.+\d\d:\d\d)',
                         re.S)
    match = pattern.search(do_download(url))
    if not match:
        raise KcError('Get lasted update time failed from:\n' + url)

    localtime = re.findall(r'(\d+)', match.group())
    localtime.extend(['0'] * 4)
    return time.mktime(tuple(int(x) for x in localtime))


def is_need_update():
    print('Compare whether need to update ...')
    return (get_last_upate_time_from_wiki(SHIP_DATA_HISTORY_URL) >
            get_last_upate_time_from_wiki(SHIP_LIST_HISTORY_URL))


def do_convert():
    print('Download orignal data from kcwiki and extract Lua code ...')
    pattern = re.compile(r'local d =.+return d', re.S)
    match = pattern.search(do_download(SHIP_DATA_CODE_URL))
    if not match:
        raise KcError('Extract Lua code from HTML failed')

    with open('wiki_orig_shipdata.lua', 'w') as f:
        print('Write Lua code to wiki_orig_shipdata.lua ...')
        f.write(match.group() + '\n')

    print('Call kcwiki_data_to_list.lua to convert ... ')
    ret = os.system('lua kcwiki_data_to_list.lua > output.txt')
    if ret != 0:
        print('Fail to excute kcwiki_data_to_list.lua')
    else:
        print('Paste all content in output.txt to "舰娘列表"')


def main():
    if is_need_update():
        do_convert()
    else:
        print('Ship list is the lasted.')

if __name__ == '__main__':
    main()
