#!/usr/bin/python3

#------------------------------------------------------------------------------#
# found at https://forum.acronis.com/comment/422777 script also requires       #
# sudo apt install python3-dateutil on ubuntu systems.                         #
#                                                                              #
# Script will check the last hour (edit hours=1 below for more) which jobs ran #
# and print the status, for example:                                           #
#                                                                              #
# Machine name: testbox                                                        #
# Backup plan name: Backup testbox to rsync.net                                #
# Start time: 2019-07-04T10:48:32Z                                             #
# Finish time: 2019-07-04T10:49:16Z                                            #
# CompletionResult: ok                                                         #
#------------------------------------------------------------------------------#

import getopt
import dateutil.parser
import requests
import sys

from datetime import datetime, timedelta

# Get command line options, confrm it's a whole integer or complain

timeperiod = 0
nodename = ''

def main(argv):
    try:
      opts, args = getopt.getopt(argv,"ht:n:",["timeperiod=","nodename="])
    except getopt.GetoptError:
      # nodename is not implemented yet
      print ('acronis_info.py -t <time period in hrs of history to show> -n <node name>')
      sys.exit(2)
    for opt, arg in opts:
      if opt == '-h':
         print ('acronis_info.py -t <time period in hrs of history to show> -n <node name>')
         sys.exit()
      elif opt in ("-t", "--timeperiod"):
         global timeperiod
         timeperiod = int(arg)
      elif opt in ("-n", "--nodename"):
         global nodename
         nodename = arg
#    print ('Time Period Is: ', timeperiod)
#    print ('Node Name Is: ', nodename)

if __name__ == "__main__":
   main(sys.argv[1:])

# We can't filter out activities by direct 'finish_time' filter in url, because it is not supported.
# To workaround it, request 100 most recent activities and throw away old objects manually
r = requests.get('http://127.0.0.1:30677/api/task_manager/v1/activities?state=completed&type=D332948D-A7A9-4E07-B76C-253DCF6E17FB&order=completed_at.desc&limit=100')
if r.status_code != requests.codes.ok:
    print(r.text)
else:
    activities = r.json()['items']
    last_hour = datetime.utcnow() - timedelta(hours=timeperiod) # The "hours" parameter defines the period for tracking activities
    for activity in activities:
#        finish_time = dateutil.parser.parse(activity.get('finishTime')).replace(tzinfo=None)
#        print(finish_time.timestamp())
#        if finish_time < last_hour:
#           continue

        print('Machine hostname:', activity.get('resourceName'))
        print('Backup plan name:', activity.get('details', {}).get('BackupPlanName'))
        print('Job Start time  :', activity.get('startTime'))
        print('Job Start stamp :', dateutil.parser.parse(activity.get('startTime')).replace(tzinfo=None).timestamp())
        print('Job Finish time :', activity.get('finishTime'))
        print('Job Finish stamp:', dateutil.parser.parse(activity.get('finishTime')).replace(tzinfo=None).timestamp())
        print('CompletionResult:', activity.get('status'), end='\n\n')

## For those wanting things on a single line
#        print('Machine hostname:', activity.get('agentName'), 'Backup plan name:', activity.get('details', {}).get('BackupPlanName'), 'Job Start time:', activity.get('startTime'), 'Job Finish time:', activity.get('finishTime'), 'CompletionResult:', activity.get('status'), end='\n')
