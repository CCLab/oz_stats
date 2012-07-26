var __ = require('csv');

var hourly_csv = __().toPath('./hourly.csv', {
                                quoted: true,
                                delimiter: ';',
                                columns: ['hour','count'],
                                header: true
                            });
var results = [];

__().fromPath('./relics_history.csv', {columns: true})
    .transform(function (row, index) {
        // filter out original data
        if(row.export_id.match(/^rel/)) {
            return;
        }
        return row;
    })
    .on('data', function (row, index) {
        var h = parseInt(row.suggested_at.match(/\d\d (\d\d)/)[1], 10);
        // take care about the time diff on the server
        h = (h + 2) % 24;

        results[h] = (results[h] || 0) + 1;
    })
    .on('end', function (count) {
        results.forEach(function (e, h) {
            hourly_csv.write({hour: h, count: e});
        });
        hourly_csv.end();
    })
    .on('error', function (err) {
        console.log('!!! '+ err);
        process.exit();
    });
