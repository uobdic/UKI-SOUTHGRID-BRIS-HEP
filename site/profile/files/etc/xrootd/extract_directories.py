from __future__ import print_function
import re

# regex from https://regex101.com/r/15CeSi/1
match = re.compile(r'(\/xrootd\/[A-z0-9|\/]+)\s.*')

with open('Authfile') as f:
    content = f.read()

results = match.findall(content)

for result in sorted(set(results)):
    print(result)
