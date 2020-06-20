import pytest

from src.clock_mirror import validate_mirror_time


class TestClockMirrorSuite:
    def test_validate_time(self):
        given_time = '10:55'
        expected_time = '10:55'

        assert validate_mirror_time(given_time) == expected_time

    def test_validate_time_leading_zero(self):
        given_time = '2:11'
        expected_time = '02:11'

        assert validate_mirror_time(given_time) == expected_time

    def test_validate_time_hour_range_start(self):
        with pytest.raises(ValueError):
            given_time = '00:20'
            validate_mirror_time(given_time)

    def test_validate_time_hour_range_end(self):
        with pytest.raises(ValueError):
            given_time = '13:20'
            validate_mirror_time(given_time)

    def test_validate_time_invalid_minutes(self):
        with pytest.raises(ValueError):
            given_time = '13:66'
            validate_mirror_time(given_time)
