import os
import sys

def get_url(data):
    for l in data.split('\n'):
        if 'http' in l and '://' in l:
            l = l[l.index('http'):]

            for v in ',"':
                l = l.removesuffix(v)

            return l

def get_url_2(data):
    for l in data.split('\n'):
        if 'http' in l and 'self.version' in l:
            return l

def check_ver(v):
    if len(v) < 3:
        return False

    for x in v:
        if x not in '1234567890.':
            return False

    return True

def prepend(data, block):
    for l in data.split('\n'):
        if l:
            yield l
        elif block:
            yield l
            yield block
            block = None
        else:
            yield l

def add_ver(data):
    if 'block version' in data:
        return data

    if 'block git_sha' in data:
        return data

    url = get_url(data)

    if not url:
        return data

    bn = os.path.basename(url)

    if '.exe' in bn:
        return data

    if '.dmg' in bn:
        return data

    while '-' in bn:
        bn = bn[bn.index('-') + 1:]

    for i in range(0, 3):
        for p in ['tar', 'gz', 'xz', 'bz2', 'zip', 'lz', 'tgz']:
            bn = bn.removesuffix('.' + p)

    bn = bn.removeprefix('v')
    bn = bn.removeprefix('V')

    if not check_ver(bn):
        print(f'unsupported ver {url} -> {bn}')

        return data

    nn = bn
    nurl = url.replace(bn, '{{self.version().strip()}}')

    data = data.replace(url, nurl)

    prep  = '{% block version %}'
    prep += '\n'
    prep += nn
    prep += '\n'
    prep += '{% endblock %}'
    prep += '\n'

    return '\n'.join(prepend(data, prep)).strip() + '\n'

def parse_1(url):
    parts = url.split('/')

    for p in parts[2:-1]:
        if '{{' in p:
            continue

        if p in parts[-1]:
            yield p

def parse_name(url):
    if 'github.com' in url:
        return url.split('/')[4]

    if 'gitlab.gnome.org' in url:
        return url.split('/')[4]

    if 'gitlab.freedesktop.org' in url:
        return url.split('/')[4]

    if 'ftp.gnu.org' in url:
        return url.split('/')[4]

    if 0:
        v = list(parse_1(url))

        if v:
            return list(sorted(v, key=lambda x: len(x)))[-1]

    if 1:
        bn = os.path.basename(url)

        if '{{' in bn:
            bn = bn[:bn.index('{{')]
            bn = bn.removesuffix('_')
            bn = bn.removesuffix('-')
            bn = bn.removeprefix('v')
            bn = bn.removeprefix('V')

            return bn

def add_name(data):
    if 'block version' not in data:
        return data

    if 'block pkg_name' in data:
        return data

    url = get_url_2(data)

    if not url:
        return data

    name = parse_name(url)

    if not name:
        print(f'unknown url {url}')
        return data

    print(name, url)

    prep = '{% block pkg_name %}'
    prep += '\n'
    prep += name
    prep += '\n'
    prep += '{% endblock %}'
    prep += '\n'

    return '\n'.join(prepend(data, prep)).strip() + '\n'

def patch(path):
    with open(path) as f:
        orig = f.read()

    data = orig
    #data = add_ver(data)
    #data = add_name(data)

    if 'block fetch' in data:
        if 'block version' not in data:
            print(path)

    if data != orig:
        print(f'fix {path}')

        with open(path, 'w') as f:
            f.write(data)
    else:
        pass
        #print(f'skip {path}')

for a, b, c in os.walk('.'):
    for x in c:
        if 'ix.sh' in x:
            patch(a + '/' + x)
