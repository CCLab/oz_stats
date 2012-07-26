var __ = require('csv');

var general_csv = __().toPath('./general.csv', {
                                quoted: true,
                                delimiter: ';',
                                columns: ['label','count']
                            });
var results = {
    total: 0,
    single: {total: 0},
    double: {total: 0},
    triple: {total: 0}
};

__().fromPath('./relics_history.csv', {columns: true})
    .transform(function (row, index) {
        // filter out original data
        if(row.export_id.match(/^rel/)) {
            return;
        }
        return row;
    })
    .on('data', function (row, index) {
        results.total += 1;
        if(!results.single[row.nid_id]) {
            results.single[row.nid_id] = true;
            results.single.total += 1;
        }
        else if(!results.double[row.nid_id]) {
            results.double[row.nid_id] = true;
            results.double.total += 1;
        }
        else if(!results.triple[row.nid_id]) {
            results.triple[row.nid_id] = true;
            results.triple.total += 1;
        }
    })
    .on('end', function (count) {
        general_csv.write({label: 'W sumie przejść przez wizard', 
                           count: results.total});
        general_csv.write({label: 'Przynajmniej raz', 
                           count: results.single.total});
        general_csv.write({label: 'Przynajmniej dwa razy', 
                           count: results.double.total});
        general_csv.write({label: 'Przynajmniej trzy razy', 
                           count: results.triple.total});
        general_csv.end();
    })
    .on('error', function (err) {
        console.log('!!! '+ err);
        process.exit();
    });
