version: 0.2

phases:
  install:
    commands:
      - pip3 install --upgrade pipenv
      - pipenv install --dev

  build:
    commands:
      - echo Unit Test started on `date`
      - pipenv run pytest -v