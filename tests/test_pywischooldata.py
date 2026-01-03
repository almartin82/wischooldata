"""
Tests for pywischooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pywischooldata
    assert pywischooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pywischooldata
    assert hasattr(pywischooldata, 'fetch_enr')
    assert callable(pywischooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pywischooldata
    assert hasattr(pywischooldata, 'get_available_years')
    assert callable(pywischooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pywischooldata
    assert hasattr(pywischooldata, '__version__')
    assert isinstance(pywischooldata.__version__, str)
