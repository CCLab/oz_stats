var __ = require('csv');

var voi_csv = __().toPath('./voivodeships.csv', {
                                quoted: true,
                                delimiter: ';',
                                columns: ['voivodeship','count','percent'],
                                header: true
                            });
var results = {total: 0};

__().fromPath('./relics_history.csv', {columns: true})
    .transform(function (row, index) {
        // filter out original data
        if(row.export_id.match(/^rel/)) {
            return;
        }
        return row;
    })
    .on('data', function (row, index) {
        var voi = row.voivodeship;
        var mon = row.nid_id;

        if(!results[voi]) {
            results[voi] = {total: 0};
        }
        if(!results[voi][mon]) {
            results[voi][mon] = true;
            results[voi].total += 1;

            results.total += 1;
        }
    })
    .on('end', function (count) {
        var key;
        var percent;
        var v_total;
        var g_total = results.total;

        for(key in results) { if(results.hasOwnProperty(key)) {
            v_total = results[key].total;
            percent = (v_total / g_total * 100).toFixed(2);

            if(key === 'total') {
                voi_csv.write({voivodeship: key, count: g_total, percent: 100});
            }
            else {
                voi_csv.write({voivodeship: key, count: v_total, percent: percent});
            }
        }}
        voi_csv.end();
    })
    .on('error', function (err) {
        console.log('!!! '+ err);
        process.exit();
    });
