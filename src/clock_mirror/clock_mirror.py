import re


def add_leading_zero(time_part: int) -> str:
    """
    Function that will add missing leading zero if needed.

    :param time_part:
    :return: leading zero guaranteed time part
    """

    if time_part <= 9:
        return f'0{time_part}'

    return str(time_part)


def calculate_mirror_time(time: str) -> str:
    """
    Function that will calculate actual time from the mirror time.

    :param time: time seen in the mirror
    :return: actual time
    """
    MAX_HOURS = 12
    MAX_MINUTES = 60

    hour, minute = time.split(':')
    hour = int(hour)
    minute = int(minute)

    if minute != 0:
        minute = MAX_MINUTES - minute

        next_hour = hour + 1
        if next_hour >= MAX_HOURS:
            next_hour -= MAX_HOURS

        hour = MAX_HOURS - next_hour
    else:
        if hour != 12:
            hour = MAX_HOURS - hour

    return f'{add_leading_zero(hour)}:{add_leading_zero(minute)}'


def validate_mirror_time(time: str) -> str:
    """
    Function that will validate that time is
    in expected format (HH:MM, where HH is 1 <= HH < 13)
    If leading zero is missing, function will add it.

    :param time: time seen in the mirror
    :raises ValueError: if time isn't valid
    :returns validated time
    """

    TIME_PATTERN = re.compile(r'(1[0-2]|0?[1-9]):([0-5][0-9])')
    if not TIME_PATTERN.fullmatch(time):
        raise ValueError(f'{time} is not valid time, '
                         f'expecting HH:MM, where HH is 1 <= HH < 13.')

    if len(time.split(':')[0]) == 1:
        return f'0{time}'

    return time
