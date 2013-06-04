#
#	Example usage:
#
matlab::install { 'R2011a':
	iso => 'puppet://files/matlab/MATHWORKS_R2011A.iso',
	licensekey => '#####-#####-#####-#####',	# provide your own here
	licensefile => 'puppet:///files/matlab/license.lic',	# get your own!
	licenseagree => true,	# setting this to true 'acknowledges' their (C)
	prefix => '/usr/local',
}

# Note: The large iso will cause puppet to take a while on first copy

