PRO LandsatCloudRemovalUsingQA

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Landsat satellite metadata file and output directory
  metadata = DIALOG_PICKFILE(TITLE = 'Select Landsat satellite Level-1 metadata file', FILTER = '*_MTL.txt')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; set mask value based on Landsat satellite
  IF STRMID(FILE_BASENAME(metadata), 0, 4) EQ 'LC08' THEN BEGIN ; LC08
    mask_values = [[2800.0,2800.0],[2804.0,2804.0],[2808.0,2808.0],$
      [2812.0,2812.0],[6896.0,6896.0],[6900.0,6900.0],$
      [6904.0,6904.0],[6908.0,6908.0]]
  ENDIF ELSE BEGIN ; LC07, LC05, LC04
    mask_values = [[752.0,752.0],[756.0,756.0],[760.0,760.0],[764.0,764.0]]
  ENDELSE

  ; import metadata file
  infile = e.OpenRaster(metadata)
  infile_ms = infile[0] ; Multispectral
  infile_qa = infile[4] ; Quality Assessment

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

  ; mask QA by data values
  task_3 = ENVITask('DataValuesMaskRaster')
  task_3.input_raster = infile_qa
  task_3.input_mask_data_values = mask_values
  task_3.data_ignore_value = infile_qa.metadata['DATA IGNORE VALUE']
  task_3.Execute

  ; mask MS by QA
  task_4 = ENVITask('MaskRaster')
  task_4.input_mask_raster = task_3.output_raster
  task_4.input_raster = task_2.output_raster
  task_4.data_ignore_value = infile_ms.metadata['DATA IGNORE VALUE']
  task_4.Execute

  ; export to TIFF
  task_5 = ENVITask('ExportRasterToTIFF')
  task_5.input_raster = task_4.output_raster
  task_5.data_ignore_value = infile_ms.metadata['DATA IGNORE VALUE']
  task_5.output_raster_uri = outDIR + PATH_SEP() + STRMID(metadata, 47, 25, /REVERSE_OFFSET) + '_nocloud' + '.tif'
  task_5.Execute

  ; terminate ENVI
  e.Close

END