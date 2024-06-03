PRO ViewRaster

  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  
  ; get files to visualize
  infile1 = DIALOG_PICKFILE(TITLE = 'Select first file to visualize', FILTER = '*')
  infile2 = DIALOG_PICKFILE(TITLE = 'Select second file to visualize', FILTER = '*')

  ; execute ENVI
  e = ENVI()
  
  ; open dataset
  raster1 = e.OpenRaster(infile1)
  raster2 = e.OpenRaster(infile2)

  ; display data in two views
  view1 = e.GetView()
  layer1 = view1.CreateLayer(raster1)
  view2 = e.CreateView()
  layer2 = view2.CreateLayer(raster2)

  ; geographically link two views
  view1.GeoLink, view2, /zoom_link

END