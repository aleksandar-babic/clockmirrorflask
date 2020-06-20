import re


def calculate_mirror_time(time: str) -> str:
    """
    Function that will calculate actual time from the mirror time.

    :param time: time seen in the mirror
    :return: actual time
    """
    return time


def validate_mirror_time(time: str) -> str:
    """
    Function that will validate that time is in expected format (HH:MM, where HH is 1 <= HH < 13)
    If leading zero is missing, function will add it.

    :param time: time seen in the mirror
    :raises ValueError: if time isn't valid
    :returns validated time
    """

    TIME_PATTERN = re.compile(r'(1[0-2]|0?[1-9]):([0-5][0-9])')
    if not TIME_PATTERN.fullmatch(time):
        raise ValueError(f'{time} is not valid time, expecting HH:MM format.')

    if len(time.split(':')[0]) == 1:
        return f'0{time}'

    return time
