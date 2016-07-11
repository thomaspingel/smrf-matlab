# smrf
smrf - A Simple Morphological Filter for Ground Identification of LIDAR Data

SMRF is designed to apply a series of opening operations against a digital surface model derived from a LIDAR point cloud, with the dual purpose of creating a gridded model of the ground surface and a vector of boolean values for each tuple (x,y,z) describing it as either ground (0) or object (1).

SMRF must be minimally called with x,y,z (all vectors of the same length) as well as a cellsize (c), a slope threshold value (s), and a maximum window size (w). The slope threshold value governs the identification process, and roughly corresponds to the maximum slope of the terrain you are working with. The maximum window size defines a window radius (in map units), and corresponds to the size of largest feature to be removed.

SMRF was tested against the ISPRS LIDAR reference data set, assembled by Sithole and Vosselman (2003). It achieved a mean total error rate of 2.97% and a mean Cohen's Kappa score of 90.02%.

Pingel, T. J., Clarke K. C., & McBride, W. A. (2013). An Improved Simple Morphological Filter for the Terrain Classification of Airborne LIDAR Data. ISPRS Journal of Photogrammetry and Remote Sensing, 77, 31-30. http://dx.doi.org/10.1016/j.isprsjprs.2012.12.002
