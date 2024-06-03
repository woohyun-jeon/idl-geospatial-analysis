PRO LandsatLST

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
  infile_tir = infile[3] ; Thermal

  ; apply radiometric calibration
  task_1_ms = ENVITask('RadiometricCalibration')
  task_1_ms.input_raster = infile_ms
  task_1_ms.calibration_type = 'Top-of-Atmosphere Reflectance'
  task_1_ms.Execute

  task_1_tir = ENVITask('RadiometricCalibration')
  task_1_tir.input_raster = infile_tir
  task_1_tir.calibration_type = 'Brightness Temperature'
  task_1_tir.Execute

  ; resample thermal band
  task_2_grid = ENVITask('BuildGridDefinitionFromRaster')
  task_2_grid.input_raster = infile_ms
  task_2_grid.pixel_size = [30.0, 30.0]
  task_2_grid.Execute

  task_2_resamp = ENVITask('BuildLayerStack')
  task_2_resamp.input_rasters = task_1_tir.output_raster
  task_2_resamp.grid_definition = task_2_grid.output_griddefinition
  task_2_resamp.Execute

  ; apply QUAC
  task_3_quac = ENVITASK('QUAC')
  task_3_quac.input_raster = task_1_ms.output_raster
  task_3_quac.sensor = 'Landsat TM/ETM/OLI'
  task_3_quac.Execute

  ; estimate NDVI
  task_4_ndvi = ENVITASK('SpectralIndex')
  task_4_ndvi.input_raster = task_3_quac.output_raster
  task_4_ndvi.index = 'NDVI'
  task_4_ndvi.Execute

  ; estimate LST
  NR = task_4_ndvi.output_raster.NROWS
  NC = task_4_ndvi.output_raster.NCOLUMNS
  newFile_1 = e.GetTemporaryFilename(CLEANUP_ON_EXIT = 'True')
  Output_LST = ENVIRaster(URI = newFile_1, NROWS = NR, NCOLUMNS = NC, NBANDS = 1, $
    DATA_TYPE = 'float', SPATIALREF = task_4_ndvi.output_raster.SPATIALREF)

  Raster_NDVI = task_4_ndvi.output_raster.GetData(BANDS = [0])
  Raster_BT = task_2_resamp.output_raster.GetData(BANDS = [0])
  Raster_EMI = FLTARR(NC, NR)
  Raster_LST = FLTARR(NC, NR)

  FOR m = 0, NC-1 DO BEGIN
    FOR n = 0, NR-1 DO BEGIN
      IF (Raster_NDVI[m,n] LT -0.185) THEN BEGIN
        Raster_EMI[m,n] = 0.995
      ENDIF ELSE BEGIN
        IF (Raster_NDVI[m,n] GE -0.185) && (Raster_NDVI[m,n] LT 0.157) THEN BEGIN
          Raster_EMI[m,n] = 0.970
        ENDIF ELSE BEGIN
          IF (Raster_NDVI[m,n] GE 0.157) && (Raster_NDVI[m,n] LE 0.727) THEN BEGIN
            Raster_EMI[m,n] = 1.0094 + 0.047*ALOG(Raster_NDVI[m,n])
          ENDIF ELSE BEGIN
            IF (Raster_NDVI[m,n] GT 0.727) THEN BEGIN
              Raster_EMI[m,n] = 0.990
            ENDIF
          ENDELSE
        ENDELSE
      ENDELSE
    ENDFOR
  ENDFOR

  Raster_LST = SQRT(SQRT(Raster_EMI))*Raster_BT - 273.15

  Output_LST.SetData, Raster_LST
  Output_LST.SAVE

  task_5_lst = ENVITask('EditRasterMetadata')
  task_5_lst.input_raster = Output_LST
  task_5_lst.data_ignore_value = infile_ms.metadata['DATA IGNORE VALUE']
  task_5_lst.Execute

  ; export to TIFF
  task_6 = ENVITask('ExportRasterToTIFF')
  task_6.input_raster = task_5_lst.output_raster
  task_6.data_ignore_value = infile_ms.metadata['DATA IGNORE VALUE']
  task_6.output_raster_uri = outDIR + PATH_SEP() + STRMID(metadata, 47, 25, /REVERSE_OFFSET) + '_lst' + '.tif'
  task_6.Execute

  ; terminate ENVI
  e.Close

END