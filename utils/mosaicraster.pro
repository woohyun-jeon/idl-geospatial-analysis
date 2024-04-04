PRO MosaicRaster

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get raster file
  tiffDIR = DIALOG_PICKFILE(/MULTIPLE_FILES, TITLE = 'Select GeoTIFF files', FILTER = ['*.tif', '*.dat'])
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; open dataset
  aggregator_1 = Dictionary()
  aggregator_1.output = !NULL
  list_aggregator_1 = List()

  FOR idx = 0, SIZE(tiffDIR, /N_ELEMENTS)-1 DO list_aggregator_1.Add, e.OpenRaster(tiffDIR[idx]), /EXTRACT
  aggregator_1.output = list_aggregator_1

  ; mosaic
  task_1 = ENVITask('BuildMosaicRaster')
  task_1.input_rasters = aggregator_1.output
  task_1.color_matching_method = 'Histogram Matching'
  task_1.color_matching_statistics = 'Entire Scene'
  task_1.feathering_method = 'Edge'
  task_1.feathering_distance = 100
  task_1.Execute

  ; export to TIFF
  task_2 = ENVITask('ExportRasterToTIFF')
  task_2.input_raster = task_1.output_raster
  task_2.interleave = 'BSQ'
  task_2.output_raster_uri = outDIR + PATH_SEP() + 'mosaic.tif'
  task_2.Execute

  ; terminate ENVI
  e.Close

END