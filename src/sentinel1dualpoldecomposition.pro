PRO Sentinel1DualPolDecomposition

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Sentinel-1 SLC file and output directory
  s1zip = DIALOG_PICKFILE(TITLE = 'Select Sentinel-1 zip file', FILTER = 'S1*.zip')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; set up
  task_0 = ENVITASK('SARscape_setting_output_folder')
  task_0.output_folder = outDIR
  task_0.Execute

  ; import Sentinel-1 data
  task_1 = ENVITask('SARsImportSentinel1Format')
  task_1.input_file_list = s1zip
  task_1.generate_iw_ew_power = !TRUE
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

  ; search VV, VH data
  vv_pwr = FILE_SEARCH(outDIR + PATH_SEP() + '*_VV_slc_list_pwr')
  vh_pwr = FILE_SEARCH(outDIR + PATH_SEP() + '*_VH_slc_list_pwr')

  ; apply speckle filter
  task_3 = ENVITask('SARsDespeckleConventionalSingle')
  task_3.input_sarscapedata = [vv_pwr[0], vh_pwr[0]]
  task_3.filt_type = 'Refined Lee'
  task_3.rows_window_number = 5.0
  task_3.cols_window_number = 5.0
  task_3.equivalent_looks = 4.0
  task_3.root_uri_for_output = task_0.root_uri_for_output
  task_3.Execute

  ; search VV, VH data
  vv_fil = FILE_SEARCH(outDIR + PATH_SEP() + '*_VV_slc_list_pwr_fil')
  vh_fil = FILE_SEARCH(outDIR + PATH_SEP() + '*_VH_slc_list_pwr_fil')

  ; apply dual polarimetric Entropy-Alpha-Anisotropy decomposition
  task_4 = ENVITask('SARsDualPolEADecomposition')
  task_4.in_copol_file_name = vv_fil[0]
  task_4.in_crosspol_file_name = vh_fil[0]
  task_4.win_lines_size = 5.0
  task_4.win_columns_size = 5.0
  task_4.win_type = 'BOXCAR'
  task_4.grid_size_for_suggested_looks = 20.0
  task_4.root_uri_for_output = task_0.root_uri_for_output
  task_4.Execute

  ; search entropy and alpha
  alpha_file = FILE_SEARCH(outDIR + PATH_SEP() + '*_alpha')
  entropy_file = FILE_SEARCH(outDIR + PATH_SEP() + '*_entropy')

  ; apply geocoding
  task_5 = ENVITask('SARsBasicGeocoding')
  task_5.input_sarscapedata = [vv_fil[0], vh_fil[0], alpha_file[0], entropy_file[0]]
  task_5.geocode_grid_size_x = 20.0
  task_5.geocode_grid_size_y = 20.0
  task_5.calibration = !TRUE
  task_5.rad_normalization = !FALSE
  task_5.generate_lia = !TRUE
  task_5.output_type = 'output_type_linear_and_db'
  task_5.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_5.generate_ql = !FALSE
  task_5.root_uri_for_output = task_0.root_uri_for_output
  task_5.Execute

  ; terminate ENVI
  e.Close

END