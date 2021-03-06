#!/usr/bin/python
import os
import sys
import slpsns
import slpsXPath
import elementtree.ElementTree as ET

names   = []
targets = {}
results = {}

if __name__ == "__main__":
 if len(sys.argv) != 2:
  print 'This tool generates an overview of an XBGF script.'
  print 'Usage:'
  print '      checkxbgf <file>'
  sys.exit(1)
 xbgfFile = sys.argv[1]
 xbgf = ET.parse(xbgfFile)
 print "%30s" % xbgfFile.split('.')[0]+':',
 cx = slpsXPath.countSemanticPreserving(xbgf,xbgfFile), \
      slpsXPath.countSemanticIncDec(xbgf,xbgfFile), \
      slpsXPath.countSemanticRevising(xbgf,xbgfFile)
 early = slpsXPath.nosi(xbgfFile,'KNOWNBUG'),  slpsXPath.nosi(xbgfFile,'POSTEXTR'),   slpsXPath.nosi(xbgfFile,'INITCORR')
 final = slpsXPath.nosi(xbgfFile,'EXTENSION'), slpsXPath.nosi(xbgfFile,'RELAXATION'), slpsXPath.nosi(xbgfFile,'CORRECTION')
 realSum = slpsXPath.notr(xbgf)
 print "%3i +%3i +%3i =%4i" % (cx[0],cx[1],cx[2],realSum),
 if sum(early):
  print '[',
  if early[0]:
   print 'K'+`early[0]`,
  if early[1]:
   print 'P'+`early[1]`,
  if early[2]:
   print 'I'+`early[2]`,
  print ']',
 if sum(final):
  print '{',
  if final[0]:
   print 'E'+`final[0]`,
  if final[1]:
   print 'R'+`final[1]`,
  if final[2]:
   print 'C'+`final[2]`,
  print '}',
 if sum(early)+sum(final) != cx[1]+cx[2]:
  if sum(cx) != realSum:
   print 'TAGERROR',sum(cx),realSum,'ERROR'
  else:
   print 'TAGERROR',sum(early)+sum(final),cx[1]+cx[2]
  sys.exit(1)
 if sum(cx) != realSum:
  print 'ERROR'
  sys.exit(1)
 else:
  print
  sys.exit(0)

