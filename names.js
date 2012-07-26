var __ = require('csv');

var names_csv = __().toPath('./names.csv', {
                                quoted: true,
                                delimiter: ';',
                                columns: ['name','count'],
                                header: true
                            });
var monuments = {};
var long_name = '';

__().fromPath('./relics_history.csv', {columns: true})
    .transform(function (row, index) {
        // filter out original data
        if(row.export_id.match(/^rel/)) {
            return;
        }
        return row;
    })
    .on('data', function (row, index) {
        // aggregate names into one long string
        if(!monuments[row.nid_id]) {
            monuments[row.nid_id] = true;
            long_name += " " + row.identification;
        }
    })
    .on('end', function (count) {
        var key;
        // filter out short words and rarly present
        var shorts = 3;
        var threshold = 50;
        var results = {};

        long_name.split(' ').forEach(function (e) {
            var token = e.replace(/[ ,\."\(\)]/g, '').toLowerCase();
            results[token] = (results[token] || 0) + 1;
        });

        for(key in results) {
            if(results[key] > threshold && key.length > shorts) {
                names_csv.write({name: key, count: results[key]});
            }
        }
        names_csv.end();
    })
    .on('error', function (err) {
        console.log('ERROR: '+ err);
        process.exit();
    });
