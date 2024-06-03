PRO ExportBandToPNG

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)
  
  ; get raster file
  tiffDIR = DIALOG_PICKFILE(TITLE = 'Select GeoTIFF file', FILTER = '*.tif')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; open dataset
  infile = e.OpenRaster(tiffDIR)

  ; extract spectral bands
  task_1 = ENVITask('ExtractBandsFromRaster')
  task_1.input_raster = infile
  task_1.Execute

  ; save as PNG
  FOREACH iterator_1, task_1.output_rasters, iterator_1_index DO BEGIN

    ; generate Filename
    task_2 = ENVITask('GenerateFilename')
    task_2.number = iterator_1_index
    task_2.directory = outDIR
    task_2.prefix = 'band_'
    task_2.random = !FALSE
    task_2.Execute

    ; apply optimized linear stretch
    task_3 = ENVITask('OptimizedLinearStretchRaster')
    task_3.input_raster = iterator_1
    task_3.Execute

    ; export to PNG
    task_4 = ENVITask('ExportRasterToPNG')
    task_4.input_raster = task_3.output_raster
    task_4.output_uri = task_2.output_filename
    task_4.Execute

  ENDFOREACH

  ; terminate ENVI
  e.Close

END