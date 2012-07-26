var __ = require('csv');

var dayly_csv  = __().toPath('./dayly.csv', {
                                quoted: true,
                                delimiter: ';',
                                columns: ['day','count'],
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
        var ts = row.suggested_at.match(/(\d\d) (\d\d)/);
        var d  = parseInt(ts[1], 10);
        var h  = parseInt(ts[2], 10);

        // there is a 2 hours diff on the server
        d = h < 21 ? d : d + 1;

        results[d] = (results[d] || 0) + 1;
    })
    .on('end', function (count) {
        results.forEach(function (e, i) {
            dayly_csv.write({day: i, count: e});
        });
        dayly_csv.end();
    })
    .on('error', function (err) {
        console.log('!!! '+ err);
        process.exit();
    });
