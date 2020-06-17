import flask as f
import time
import uuid

from flask import request
from http import HTTPStatus

from . import database
from . import auth
from . import cache

bp = f.Blueprint('weight', __name__)

#maximum acceptable offset between our clock and the client's
sMAX_TIME_ERROR = 300

#@bp.route('/entry/<uuid:id>', methods=['GET'])
#@auth.requireAuth()
#def entry_get(userid):
#    #TODO

@bp.route('/entry', methods=['POST'])
@database.autocommit_db
@cache.cache
@auth.requireAuth
def entry_add(userid):
    """Add one new weight measurement.

    .. :quickref: Weight; Log new weight measurement

    Omitting any query string parameters results in undefined behavior.

    Requires authentication.

    :query datetime: Integer number of seconds since the Unix epoch, representing the time the measurement was made at
    :query weight: The recorded weight in kilograms
    :status 201: measurement created
    :status 400: possibly returned when missing parameters
    :status 422: possibly returned when provided date is in the future
    """
    dt = request.args.get('datetime', None, type=int)
    weight = request.args.get('weight', None, type=float)

    if dt is None or weight is None:
        msg = ""
        if dt is None and weight is None: # pragma: no cover
            msg = "Query is missing both the datetime (int) and weight (float) parameters"
        elif dt is None: # pragma: no cover
            msg = "Query is missing the datetime (int) parameter"
        elif weight is None: # pragma: no cover
            msg = "Query is missing the weight (float) parameter"
        return (msg, HTTPStatus.BAD_REQUEST)

    now = time.time()
    if dt > now + sMAX_TIME_ERROR:
        sErr=dt - now
        msg = f"Given time is in the future."
        if sErr > 995*now: # pragma: no cover
            msg += "\nMaybe the time parameter was provided in units of milliseconds instead of seconds?"

        return (msg, HTTPStatus.UNPROCESSABLE_ENTITY)

    uid = uuid.uuid4()

    db = database.get_db()
    db.execute('INSERT INTO weight (id, userid, datetime, weight) VALUES (?, ?, ?, ?)',
               (str(uid), userid, dt, weight))

    return f"{uid}", HTTPStatus.CREATED

@bp.route('/batch', methods=['GET'])
@auth.requireAuth()
def batch_get(userid):
    """Get weight measurements for a given time range.

    .. :quickref: Weight; Get collection of weight measurements.

    Results are sorted by date, from oldest to newest. Omitting any query parameter results in undefined behavior.

    Requires authentication.

    :query since: Integer number of seconds since the Unix epoch; return only measurements occuring on or after this time
    :query before: Integer number of seconds since the Unix epoch; return only measurements occuring before this time
    :query limit: Maximum number of results to return. Behavior is undefined when strictly greater than 100.
    :query offset: Instead of returning the start of the sorted list of results, start from this offset.
    :resheader Content-Type: application/csv
    :returns: csv with one row for each measurement. In order, the columns are: unique id for the measurement, the time of the measurement, and the recorded weight in kilograms.
    """
    since = request.args.get('since', None, type=int)
    before = request.args.get('before', None, type=int)
    limit = request.args.get('limit', None, type=int)
    offset = request.args.get('offset', None, type=int)

    if before is None or since is None or limit is None or offset is None:
        return ("Query is missing missing at least one of the required int parameters: before, since, limit, offset", 400)

    db = database.get_db()

    rows = db.execute('SELECT * FROM weight WHERE userid = ? AND ? <= datetime AND datetime < ? ORDER BY datetime LIMIT ? OFFSET ?',
               (userid, since, before, limit, offset)).fetchall()

    data = ""
    for row in rows:
        data += f"{row['id']}, {row['datetime']}, {row['weight']}\n"

    return f.Response(data, mimetype='text/csv')

#@bp.route('/batch', methods=['POST'])
#@auth.requireAuth()
#def batch_add(userid):
#    #TODO
