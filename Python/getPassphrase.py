#!/usr/bin/env python3
### requires pandas lxml htm5lib BeautifulSoup4

import pandas as pd
from random import randrange
import argparse


def getPassphrase(url):
    tables = pd.read_html(url)
    index = randrange(10)
    passphrases = tables[2]
    return passphrases.Passphrase[index]

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Gets a passphrase from untroubled.org')
    parser.add_argument('-w', '--wordcount', default='3', type=int, help='Number of words in passphrase')
    parser.add_argument('-m', '--minlen', default='1', type=int, help='Minimum length of words')
    parser.add_argument('-M', '--maxlen', default='8', type=int, help='Maximum length of words')
    parser.add_argument('-r', '--randcaps', default='first', type=str, help='Option for what to capitalize. Default is first letter of words at random.')
    parser.add_argument('-n', '--numlen', default='1', type=int, help='length of numbers in between words')
    args = parser.parse_args()

    url = "https://untroubled.org/pwgen/ppgen.cgi?wordcount={0}&minlen={1}&maxlen={2}&randcaps={3}&numlen={4}&submit=Generate+Passphrase".format(
        str(args.wordcount), 
        str(args.minlen), 
        str(args.maxlen), 
        str(args.randcaps), 
        str(args.numlen)
    )

    print (getPassphrase(url))