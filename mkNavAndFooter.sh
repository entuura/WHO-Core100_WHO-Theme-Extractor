#!/bin/bash
#PROJ		 :WHO_core100_WHO-Theme-Extractor
#title           :mkNavAndFooter.sh
#description     :This script will make html snippits from the WHO web site 'emptynavandfooterpage' for use in external applications 
#author		 :Started by Philippe Boucher <boucherp@who.int>, heavily modified by Steven Uggowitzer <steven@entuura.org>
#date            :20180925
#version         :0.6    
#usage		 :bash mkNavAndFooter.sh
#notes           :Created for use on the 100 Indicators / WHO INdicator Metadata Registry Project 
#==============================================================================

# Root folder for work
BASEDIR=$(dirname "$0")

# Subfolder to be created with HTML snippit elements
BASEHTMLDIR="cabinet/common"
WHOELEMENTS="$BASEDIR/$BASEHTMLDIR"

# Create the directory for the snippit files if it does not exist
[ -d $WHOELEMENTS ] || mkdir -p $WHOELEMENTS

# File extender of HTML snippit files to be created
FTYPE="shtml"

# <title> text
#FTITLE="Indicator Metadata Registry"
FTITLE="WHO | Global Reference List of 100 Core Health Indicators (plus health-related SDGs), registry, 2018"
FURL="indicators.who.int/core100"

# Java Script function that handles the translation / multi-language view
# e.g. function imrOpenLinkWithTranslation(culture) {
#         window.location = "?lang=" + culture;
#      }
# To be placed in <head> Java Scripting
TXSCRIPT="imrOpenLinkWithTranslation"
####

# Suppress the <title> section all together
suppress_title=false
####

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ ! -d "$SCRIPTDIR/$WHOELEMENTS" ]; then
  mkdir -p "$SCRIPTDIR/$WHOELEMENTS"
fi

for culture in "fr" "en" "ar" "zh" "ru" "es" ; do
 wget -q -O - "http://www.who.int/${culture}/emptynavandfooterpage" | \
   sed \
       -e "s/\r//g" \
       -e "s/<head/\n<head/g" \
       -e "s/<body/\n<body/g" \
       -e "s/<\/title>/<\/title>\n<!-- HEADCONTENT -->\n/g"  \
       -e "s/SYSTEM DO NOT MOVE OR EDIT/$FTITLE/g" \
       -e "s|www.who.int/emptynavandfooterpage|$FURL|g" \
       -e "s/openLinkWithTranslation/$TXSCRIPT/" \
       -e "s/href=\([\"']\)\/\//href=\1http:\/\//g" \
       -e "s/href=\([\"']\)\([^h][^t][^t][^p]\)/href=\1http:\/\/www.who.int\/\2/g" \
       -e "s/src=\([\"']\)\([^h][^t][^t][^p]\)/src=\1http:\/\/www.who.int\/\2/g" \
       -e "s|'\/WebResource.axd|'http:\/\/www.who.int\/WebResource.axd|g" \
       -e "s|'\/ScriptResource.axd|'http:\/\/www.who.int\/ScriptResource.axd|g" \
       -e "s|\/api\/|http:\/\/www.who.int\/api\/|g" \
       -e "s/<section class=\"content\">/\n<section class=\"content\">\n<!-- PAGECONTENT -->\n/g" \
   > $WHOELEMENTS/empty_page_${culture}.html

# Split the file based on per-body (page000) and post-body (page001)
csplit -s $WHOELEMENTS/empty_page_${culture}.html "/<body/" -f $WHOELEMENTS/page0

# Split pre-body to pre-head (page200) and full head block (page201)
csplit -s $WHOELEMENTS/page000 "/<head/" -f $WHOELEMENTS/page2

# Split full head block (page201) to prehead (page300) and posthead (page301)
csplit -s $WHOELEMENTS/page201 "/<!-- HEADCONTENT -->/" -f $WHOELEMENTS/page3

# Split body block (page001) to precontent (page400) and postcontent (page401)
csplit -s $WHOELEMENTS/page001 "/<!-- PAGECONTENT -->/" -f $WHOELEMENTS/page4


# As we write the snippit files, in some cases use sed to remove the HTML comments
# cat $WHOELEMENTS/page200  | sed -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba'  > $WHOELEMENTS/page_prefix_${culture}.$FTYPE
cat $WHOELEMENTS/page200  | sed -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba'  > $WHOELEMENTS/page_prefix_${culture}.$FTYPE
cat $WHOELEMENTS/page300 > $WHOELEMENTS/page_headprefix_${culture}.$FTYPE
# cat $WHOELEMENTS/page301 | sed -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba'  > $WHOELEMENTS/page_headpostfix_${culture}.$FTYPE
cat $WHOELEMENTS/page301 | sed -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba'  > $WHOELEMENTS/page_headpostfix_${culture}.$FTYPE
cat $WHOELEMENTS/page400 > $WHOELEMENTS/page_bodyprefix_${culture}.$FTYPE
# cat $WHOELEMENTS/page401 | sed -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba'  > $WHOELEMENTS/page_bodypostfix_${culture}.$FTYPE
cat $WHOELEMENTS/page401 > $WHOELEMENTS/page_bodypostfix_${culture}.$FTYPE


# Clean up the <title> problem with carriage returns
sed -i ':a;N;$!ba;s/\n//g' $WHOELEMENTS/page_headprefix_${culture}.$FTYPE
# And remove tab characters which can also find there way into the <title>
sed -i 's/\t//g' $WHOELEMENTS/page_headprefix_${culture}.$FTYPE

# Suppress the whole <title ... </title  section in page_head_prefix
if [ "$suppress_title" = true ] ; then
  sed -i 's/<title.\+\/title>//g' $WHOELEMENTS/page_headprefix_${culture}.$FTYPE
fi

# Clean up the temporary files
rm -rf cabinet/common/page???
rm -rf cabinet/common/empty_page_${culture}.html

done
