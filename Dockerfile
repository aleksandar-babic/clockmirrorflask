FROM python:3.8-slim

# Prevents Python from writing pyc files to disc
ENV PYTHONDONTWRITEBYTECODE 1
# Prevents Python from buffering stdout and stderr
ENV PYTHONUNBUFFERED 1

# Utilize layer caching
COPY Pipfile Pipfile.lock ./

# Install package manager and dependencies
RUN pip install pipenv && \
    pipenv install --deploy --system && \
    # Always clean up behind youself!
    pip uninstall pipenv -y

# Run app as non-privileged user
RUN useradd --create-home appuser
WORKDIR /home/appuser
USER appuser

COPY app.py ./

CMD ["python", "app.py"]