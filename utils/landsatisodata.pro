PRO LandsatISODATA

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Landsat satellite metadata file and output directory
  metadata = DIALOG_PICKFILE(TITLE = 'Select Landsat satellite metadata file', FILTER = '*_MTL.txt')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; import metadata file
  infile = e.OpenRaster(metadata)
  infile_ms = infile[0] ; Multispectral
  infile_pan = infile[1] ; Panchromatic

  ; apply radiometric calibration
  task_1_ms = ENVITask('RadiometricCalibration')
  task_1_ms.input_raster = infile_ms
  task_1_ms.calibration_type = 'Top-of-Atmosphere Reflectance'
  task_1_ms.Execute

  task_1_pan = ENVITask('RadiometricCalibration')
  task_1_pan.input_raster = infile_pan
  task_1_pan.calibration_type = 'Top-of-Atmosphere Reflectance'
  task_1_pan.Execute

  ; apply Gram-Schmidt pansharpening
  task_2 = ENVITask('GramSchmidtPanSharpening')
  task_2.input_low_resolution_raster = task_1_ms.output_raster
  task_2.input_high_resolution_raster = task_1_pan.output_raster
  task_2.Execute

  ; apply ISODATA classification
  task_3 = ENVITask('ISODATAClassification')
  task_3.input_raster = task_2.output_raster
  task_3.number_of_classes = 5
  task_3.change_threshold_percent = 10.0
  task_3.iterations = 10
  task_3.Execute

  ; apply classification smoothing
  task_4 = ENVITask('ClassificationSmoothing')
  task_4.input_raster = task_3.output_raster
  task_4.Execute

  ; export to TIFF
  task_5 = ENVITask('ExportRasterToTIFF')
  task_5.input_raster = task_4.output_raster
  task_5.data_ignore_value = infile_ms.metadata['DATA IGNORE VALUE']
  task_5.output_raster_uri = outDIR + PATH_SEP() + STRMID(metadata, 47, 25, /REVERSE_OFFSET) + '_isodata' + '.tif'
  task_5.Execute

  ; terminate ENVI
  e.Close

END