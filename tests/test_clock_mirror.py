import pytest

from src.clock_mirror import validate_mirror_time, \
    calculate_mirror_time, add_leading_zero


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

    @pytest.fixture
    def calculated_times(self):
        return [
            {
                'mirror': '12:22',
                'actual': '11:38'
            },
            {
                'mirror': '05:25',
                'actual': '06:35'
            },
            {
                'mirror': '01:50',
                'actual': '10:10'
            },
            {
                'mirror': '11:58',
                'actual': '12:02'
            },
            {
                'mirror': '12:01',
                'actual': '11:59'
            },
            {
                'mirror': '04:25',
                'actual': '07:35'
            },
            {
                'mirror': '12:00',
                'actual': '12:00'
            }
        ]

    def test_calculate_mirror_time(self, calculated_times):
        for time in calculated_times:
            assert calculate_mirror_time(time['mirror']) == time['actual']

    def test_add_leading_zero(self):
        expected = '09'
        assert add_leading_zero(9) == expected

    def test_add_leading_zero_skip(self):
        expected = '11'
        assert add_leading_zero(11) == expected
