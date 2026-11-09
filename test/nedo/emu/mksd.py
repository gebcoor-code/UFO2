# mksd.py base.vhd out.vhd dir files...: copy files into folder dir of the FAT32 partition (sector 2048), zip it
import sys, shutil, os
from pyfatfs.PyFatFS import PyFatFS
base, out, folder, files = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
shutil.copy(base, out)
fs = PyFatFS(out, offset=2048 * 512)
if not fs.exists('/' + folder): fs.makedir('/' + folder)
for f in files:
    if f.startswith('^'): f = f[1:]; p = '/' + os.path.basename(f).upper()      # (^: into the root)
    else: p = '/' + folder + '/' + os.path.basename(f).upper()
    with fs.openbin(p, 'w') as o: o.write(open(f, 'rb').read())
fs.close()
