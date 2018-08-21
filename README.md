Bio::Galaxy::API
================

[![Build Status](https://travis-ci.org/jvolkening/p5-Bio-Galaxy-API.svg?branch=master)](https://travis-ci.org/jvolkening/p5-Bio-Galaxy-API)

``Bio::Galaxy::API`` is an interface to the REST API of the [Galaxy informatics
platform](https://galaxyproject.org).

WARNING: This library is currently in early development. The API (of this
library, not of the Galaxy REST service) is not stable and will likely change.
Many endpoints of the REST API remain unimplemented. This warning will be
removed when the library reaches a more mature state.

INSTALLATION
------------

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Bio::Galaxy::API

LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2016-2018 Jeremy Volkening <jdv@base2bio.com>

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 3 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

See the LICENSE file in the top-level directory of this distribution for the
full license terms.
