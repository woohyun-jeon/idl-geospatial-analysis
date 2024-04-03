PRO MaskRasterbyVector

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get raster and vector file
  tiffDIR = DIALOG_PICKFILE(TITLE = 'Select raster file', FILTER = '*.tif')
  shpDIR = DIALOG_PICKFILE(TITLE = 'Select vector file', FILTER = '*.shp')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; open dataset
  inRaster = e.OpenRaster(tiffDIR)
  inVector = e.OpenVector(shpDIR)

  ; mask raster by shapefile
  task_1 = ENVITask('VectorMaskRaster')
  task_1.input_raster = inRaster
  task_1.input_mask_vector = inVector
  task_1.data_ignore_value = -9999.
  task_1.Execute

  ; export to TIFF
  task_2 = ENVITask('ExportRasterToTIFF')
  task_2.input_raster = task_1.output_raster
  task_2.interleave = 'BSQ'
  task_2.data_ignore_value = -9999.
  task_2.output_raster_uri = outDIR + PATH_SEP() + STRMID(FILE_BASENAME(tiffDIR), 0, STRLEN(FILE_BASENAME(tiffDIR))-4) + '_mask.tif'
  task_2.Execute

  ; terminate ENVI
  e.Close

END