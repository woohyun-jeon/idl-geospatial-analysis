PRO LandsatVI

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Landsat satellite metadata file and output directory
  metadata = DIALOG_PICKFILE(TITLE = 'Select Landsat satellite metadata file', FILTER = '*_MTL.txt')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; import metadata file
  infile = e.OpenRaster(metadata)
  infile_ms = infile[0] ; Multi-Spectral

  ; apply radiometric calibration
  task_1 = ENVITask('RadiometricCalibration')
  task_1.input_raster = infile_ms
  task_1.calibration_type = 'Top-of-Atmosphere Reflectance'
  task_1.Execute

  ; apply QUAC
  task_2 = ENVITask('QUAC')
  task_2.input_raster = task_1.output_raster
  task_2.sensor = 'Landsat TM/ETM/OLI'
  task_2.Execute

  ; get spectral indices
  task_3 = ENVITask('SpectralIndices')
  task_3.input_raster = task_2.output_raster
  task_3.index = ['Enhanced Vegetation Index', 'Normalized Difference Vegetation Index']
  task_3.Execute

  ; aggregate
  aggregator_1 = Dictionary()
  aggregator_1.output = !NULL
  list_aggregator_1 = List()

  list_aggregator_1.Add, task_2.output_raster, /EXTRACT
  list_aggregator_1.Add, task_3.output_raster, /EXTRACT
  aggregator_1.output = list_aggregator_1

  ; extract Properties and Metadata
  propertyExtractor_1 = Obj_New('ENVIExtractObjectPropertyTask')
  propertyExtractor_1.input_object = task_3.output_raster
  propertyExtractor_1.Execute

  ; stack spectral band and indices
  task_4 = ENVITask('BuildBandStack')
  task_4.input_rasters = aggregator_1.output
  task_4.spatial_reference = propertyExtractor_1.auxiliary_spatialref
  task_4.Execute

  ; export to TIFF
  task_5 = ENVITask('ExportRasterToTIFF')
  task_5.input_raster = task_4.output_raster
  task_5.data_ignore_value = infile_ms.metadata['DATA IGNORE VALUE']
  task_5.output_raster_uri = outDIR + PATH_SEP() + STRMID(metadata, 47, 25, /REVERSE_OFFSET) + '_indices' + '.tif'
  task_5.Execute

  ; terminate ENVI
  e.Close

END