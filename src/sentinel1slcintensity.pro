PRO Sentinel1SLCIntensity

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2

  ; execute ENVI
  e = ENVI(/HEADLESS)

  ; get Sentinel-1 SLC files and output directory
  s1files = DIALOG_PICKFILE(/MULTIPLE_FILES, TITLE = 'Select Sentinel-1 files', FILTER = 'S1*.zip')
  s1aoi = DIALOG_PICKFILE(TITLE = 'Select AoI shapefile', FILTER = '*.shp')
  outDIR = DIALOG_PICKFILE(/DIRECTORY,TITLE = 'Select output directory')

  ; set up
  task_0 = ENVITASK('SARscape_setting_output_folder')
  task_0.output_folder = outDIR
  task_0.Execute

  ; open Sentinel-1
  task_1 = ENVITask('SARsImportSentinel1Format')
  task_1.input_file_list = s1files
  IF FILE_TEST(s1aoi) THEN task_1.input_roi_file = s1aoi
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
  task_2.slope_flag_val = !FALSE
  task_2.replace_dummy_with_min_val = !FALSE
  task_2.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_2.generate_ql = !FALSE
  task_2.root_uri_for_output = task_0.root_uri_for_output
  task_2.Execute

  ; apply multilooking
  task_3 = ENVITask('SARsBasicMultilooking')
  task_3.input_sarscapedata = task_1.output_sarscapedata
  task_3.multilook_method = 'frequency_domain'
  task_3.range_multilook = 8.0
  task_3.azimuth_multilook = 2.0
  task_3.fill_dummy = !TRUE
  task_3.fill_dummy_method = 'mean_near_pixels'
  task_3.generate_ql = !FALSE
  task_3.root_uri_for_output = task_0.root_uri_for_output
  task_3.Execute

  ; apply coregistration
  task_4 = ENVITask('SARsBasicCoregistration')
  task_4.input_sarscapedata = task_3.output_sarscapedata
  task_4.dem_sarscapedata = task_2.output_sarscapedata
  task_4.recalculate_for_each_image = !FALSE
  task_4.compute_param = !FALSE
  task_4.coregistration_with_dem = !TRUE
  task_4.generate_ql = !FALSE
  task_4.root_uri_for_output = task_0.root_uri_for_output
  task_4.Execute

  ; apply image filter
  task_5 = ENVITask('SARsDespeckleConventionalSingle')
  task_5.input_sarscapedata = task_4.output_sarscapedata
  task_5.filt_type = 'Refined Lee'
  task_5.rows_window_number = 5.0
  task_5.cols_window_number = 5.0
  task_5.equivalent_looks = 4.0
  task_5.generate_ql = !FALSE
  task_5.root_uri_for_output = task_0.root_uri_for_output
  task_5.Execute

  ; apply geocoding and radiometric calibration
  task_6 = ENVITask('SARsBasicGeocoding')
  task_6.input_sarscapedata = task_5.output_sarscapedata
  task_6.dem_sarscapedata = task_2.output_sarscapedata
  task_6.geocode_grid_size_x = 20.0
  task_6.geocode_grid_size_y = 20.0
  task_6.calibration = !TRUE
  task_6.geo_scattering_area_method = 'sine_area_estimation'
  task_6.rad_normalization = !FALSE
  task_6.generate_lia = !FALSE
  task_6.output_type = 'output_type_linear_and_db'
  task_6.dummy_removal = !FALSE
  task_6.output_cartographic_system = ["GEO-GLOBAL","","GEO","","WGS84","","0.0000000"]
  task_6.generate_ql = !FALSE
  task_6.root_uri_for_output = task_0.root_uri_for_output
  task_6.Execute

  ; terminate ENVI
  e.Close

END