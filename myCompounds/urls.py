#!/usr/bin/python
# -*- coding: utf-8 -*-

from django.conf.urls.defaults import *
from views import *

urlpatterns = patterns('', url(r'^addCompounds/$', uploadCompound),
                       url(r'^(?P<resource>\S*)$', showCompounds))
