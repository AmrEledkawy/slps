#!/usr/bin/python
import os
import sys
import slpsns
import slpsXPath
import elementtree.ElementTree as ET

names   = []
targets = {}
results = {}

def report(keys,key,note):
 s = note.replace('xbgf:','')
 cx = 0
 for x in keys:
  cx += results[key][x]
  if results[key][x]:
   s += '&'+`results[key][x]`
  else:
   s += '& ---'
 if cx:
  print s+'&'+`cx`+'\\\\'

if __name__ == "__main__":
 if len(sys.argv) != 4:
  print 'This tool generates an overview of a bunch of XBGF scripts.'
  print 'Usage:'
  print '      xbgfover <xbgf.xsd> <lcf> <xbgfs-path>'
  sys.exit(1)
 xsd = ET.parse(sys.argv[1])
 gn = 0
 for x in xsd.findall('/'+slpsns.xsd_('group')+'/'+slpsns.xsd_('choice')):
  names.append([])
  for y in x.findall(slpsns.xsd_('element')):
   if y.attrib.has_key('ref'):
    names[gn].append(y.attrib['ref'])
  gn += 1
 names.remove([])
 lcf = ET.parse(sys.argv[2])
 for x in lcf.findall('/target'):
  name = x.findtext('name')
  targets[name] = []
  for y in x.findall('branch/*/perform'):
   targets[name].append(y.text)
 path = sys.argv[3]
 if path[-1] != '/':
  path += '/'
 results['LOC'] = {}
 results['NOI'] = {}
 results['NOX'] = {}
 for x in names:
  for y in x:
   results[y] = {}
   for z in targets.keys():
    results[y][z] = 0
 for x in targets.keys():
  results['LOC'][x] = 0
  results['NOI'][x] = 0
  results['NOX'][x] = 0
  for y in targets[x]:
   results['LOC'][x] += slpsXPath.loc(path+y+'.xbgf')
   results['NOI'][x] += slpsXPath.noi(path+y+'.xbgf')
   xbgf = ET.parse(path+y+'.xbgf')
   results['NOX'][x] += len(xbgf.findall('/*'))
   for z in names:
    for q in z:
     results[q][x] += len(xbgf.findall(q.replace('xbgf:',slpsns.xbgf_(''))))
 for x in names:
  for y in x:
   used = False
   for z in targets.keys():
    if results[y][z]:
     used = True
   if not used:
    print '%%',y,'not used in any XBGF script'
 sorted = targets.keys()[:]
 sorted.sort()
 print '\\begin{tabular}{l|'+('c|'*len(targets))+'|c}'
 for x in sorted:
  print '&\\textbf{'+x+'}',
 print '&\\textbf{Total}\\\\\\hline'
 for x in names:
  for y in x:
   report(sorted,y,'\\xbgfNumber{'+y+'}')
  print '\\hline'
 print '\\end{tabular}'
 sys.exit(0)

