# --- call_download_ex.py ---

import os
import sys

# add additional directories that QGIS needs to find Python plugins
# this is different for all the OSes
if sys.platform == "darwin":
  qgis_app = os.path.abspath(os.path.join(sys.executable, "..", "..", "..", ".."))
  # for QT
  os.environ['QT_QPA_PLATFORM_PLUGIN_PATH'] = f'{qgis_app}/Contents/PlugIns'
  # for Processing
  sys.path.append(f'{qgis_app}/Contents/Resources/python/plugins')
  
elif sys.platform in ('linux', 'linux2'):
  # for Processing
  # may be different on different flavours of linux
  sys.path.append('/usr/share/qgis/python/plugins')

# load QGIS modules
from qgis.core import QgsApplication, QgsProcessingFeedback
from qgis.analysis import QgsNativeAlgorithms 

# make an "application" (False for no UI)
qgs = QgsApplication([], False)
QgsApplication.initQgis()

# add the native routines to the processing registry
QgsApplication.processingRegistry().addProvider(QgsNativeAlgorithms())

# load the processing library
from processing.core.Processing import Processing
Processing.initialize()

# run the algorithm
result = Processing.runAlgorithm(
  "native:filedownloader", 
  {'OUTPUT': 'response.json', 'URL': 'http://httpbin.org/get'}
)

# exit QGIS
QgsApplication.exitQgis()

# print result to stdout
print(result)
