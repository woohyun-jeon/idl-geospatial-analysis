PRO Sentinel2LabelwithEMSR

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Sentinel-2 satellite metadata file and output directory
  s2meta = DIALOG_PICKFILE(TITLE = 'Select Sentinel-2 satellite metadata file', FILTER = 'M*.xml')
  s2aoi = DIALOG_PICKFILE(TITLE = 'Select aoi shapefile', FILTER = '*observedEvent*.shp')
  s2boundary = DIALOG_PICKFILE(TITLE = 'Select boundary shapefile', FILTER = '*areaOfInterest*.shp')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; import metadata file
  infile = e.OpenRaster(s2meta)
  infile10m = infile[0] ; 10 meter bands
  infile20m = infile[4] ; 20 meter bands

  ; resample
  task_1_grid = ENVITask('BuildGridDefinitionFromRaster')
  task_1_grid.input_raster = infile10m
  task_1_grid.pixel_size = [10.0,10.0]
  task_1_grid.Execute

  task_1_resample = ENVITask('BuildLayerStack')
  task_1_resample.input_rasters = [infile10m, infile20m]
  task_1_resample.grid_definition = task_1_grid.output_griddefinition
  task_1_resample.Execute

  ; convert vector to ROI
  inaoi = e.OpenVector(s2aoi)
  inboundary = e.OpenVector(s2boundary)

  task_2_aoi = ENVITask('VectorRecordsToROI')
  task_2_aoi.input_vector = inaoi
  task_2_aoi.Execute

  task_2_boundary = ENVITask('VectorRecordsToROI')
  task_2_boundary.input_vector = inboundary
  task_2_boundary.Execute

  ; create subrects from ROI
  task_3 = ENVITask('CreateSubrectsFromROI')
  task_3.input_roi = task_2_boundary.output_roi
  task_3.input_raster = task_1_resample.output_raster
  task_3.Execute

  ; subset raster
  task_4 = ENVITask('SubsetRaster')
  task_4.sub_rect = task_3.subrects
  task_4.input_raster = task_1_resample.output_raster
  task_4.Execute

  ; convert ROIs to classification
  task_5 = ENVITask('ROIToClassification')
  task_5.input_raster = task_4.output_raster
  task_5.input_roi = task_2_aoi.output_roi
  task_5.Execute

  ; export to TIFF
  task_6_origin = ENVITask('ExportRasterToTIFF')
  task_6_origin.input_raster = task_4.output_raster
  task_6_origin.output_raster_uri = outDIR + PATH_SEP() + STRMID(FILE_BASENAME(FILE_DIRNAME(s2meta)), 0, 19) + '_origin' + '.tif'
  task_6_origin.Execute

  task_6_label = ENVITask('ExportRasterToTIFF')
  task_6_label.input_raster = task_5.output_raster
  task_6_label.output_raster_uri = outDIR + PATH_SEP() + STRMID(FILE_BASENAME(FILE_DIRNAME(s2meta)), 0, 19) + '_label' + '.tif'
  task_6_label.Execute

  ; terminate ENVI
  e.Close

END