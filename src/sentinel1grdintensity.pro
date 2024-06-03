PRO Sentinel1GRDIntensity

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Sentinel-1 GRD file and output directory
  s1zip = DIALOG_PICKFILE(TITLE = 'Select Sentinel-1 zip file', FILTER = 'S1*.zip')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; set up
  task_0 = ENVITASK('SARscape_setting_output_folder')
  task_0.output_folder = outDIR
  task_0.Execute

  ; import Sentinel-1 data
  task_1 = ENVITask('SARsImportSentinel1Format')
  task_1.input_file_list = s1zip
  task_1.generate_iw_ew_power = !FALSE
  task_1.cross_copolarization = 'ALL_POL'
  task_1.make_slc_list_mosaic = !TRUE
  task_1.remove_noise_from_lut = !TRUE
  task_1.skip_sample = !FALSE
  task_1.rename_the_file_using_parameters = !TRUE
  task_1.generate_ql = !FALSE
  task_1.root_uri_for_output = task_0.root_uri_for_output
  task_1.Execute

  ; get SRTM 3 arc-sec DEM
  task_2 = ENVITask('SARsToolsDEMExtractionSRTM4')
  task_2.reference_sarscapedata = task_1.output_sarscapedata
  task_2.grid_size_x_val = 90.0
  task_2.grid_size_y_val = 90.0
  task_2.replace_dummy_with_min_val = !TRUE
  task_2.output_cartographic_system =  ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_2.root_uri_for_output = task_0.root_uri_for_output
  task_2.Execute

  ; apply speckle filter
  task_3 = ENVITask('SARsDespeckleConventionalSingle')
  task_3.input_sarscapedata = task_1.output_sarscapedata
  task_3.filt_type = 'Refined Lee'
  task_3.rows_window_number = 5.0
  task_3.cols_window_number = 5.0
  task_3.equivalent_looks = 4.0
  task_3.root_uri_for_output = task_0.root_uri_for_output
  task_3.Execute

  ; apply geocoding and radiometric calibration
  task_4 = ENVITask('SARsBasicGeocoding')
  task_4.input_sarscapedata = task_3.output_sarscapedata
  task_4.dem_sarscapedata = task_2.output_sarscapedata
  task_4.geocode_grid_size_x = 10.0
  task_4.geocode_grid_size_y = 10.0
  task_4.calibration = !TRUE
  task_4.output_type = 'output_type_db'
  task_4.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_4.root_uri_for_output = task_0.root_uri_for_output
  task_4.Execute

  ; terminate ENVI
  e.Close

END