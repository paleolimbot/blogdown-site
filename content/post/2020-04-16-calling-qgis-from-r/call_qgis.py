
import os
import sys
import json

qgis_algorithm  = sys.argv[1]
qgis_params = json.loads(sys.argv[2])

if sys.platform == "darwin":
  qgis_app = os.path.abspath(os.path.join(sys.executable, "..", "..", "..", ".."))
  # for QT
  os.environ['QT_QPA_PLATFORM_PLUGIN_PATH'] = f'{qgis_app}/Contents/PlugIns'
  # for Processing
  sys.path.append(f'{qgis_app}/Contents/Resources/python/plugins')

from qgis.core import QgsApplication
from qgis.analysis import QgsNativeAlgorithms 

qgs = QgsApplication([], False)
QgsApplication.initQgis()
QgsApplication.processingRegistry().addProvider(QgsNativeAlgorithms())

from processing.core.Processing import Processing
Processing.initialize()

result = Processing.runAlgorithm(qgis_algorithm, qgis_params)

QgsApplication.exitQgis()

print(json.dumps(result))
