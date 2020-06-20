from flask import Flask, request
from waitress import serve
from flask_restplus import Api, Resource
from clock_mirror import calculate_mirror_time, validate_mirror_time

app = Flask(__name__)
api = Api(app=app)
clock_namespace = api.namespace('clock', description='Clock API')


@clock_namespace.route("")
class ClockHandler(Resource):
    @api.doc(description='Endpoint that will return actual time for given mirror time.')
    @api.doc(responses={500: 'Internal server error', 200: 'Time successfully converted',
                        400: 'Bad request, no mirror_time given'},
             params={'mirror_time': 'Time seen in the mirror'})
    def get(self):
        args = request.args
        if 'mirror_time' not in args:
            return "mirror_time is required", 400

        try:
            mirror_time = validate_mirror_time(args['mirror_time'])
        except ValueError as e:
            return str(e), 400

        return {
            'mirror_time': mirror_time,
            'actual_time': calculate_mirror_time(mirror_time)
        }


if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=8080)
