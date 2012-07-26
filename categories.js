var __ = require('csv');

var cats_csv = __().toPath('./categories.csv', {
                                quoted: true,
                                delimiter: ';',
                                columns: ['category','count'],
                                header: true
                            });
var monuments = {};
var results = {};

__().fromPath('./relics_history.csv', {columns: true})
    .transform(function (row, index) {
        // filter out original data
        if(row.export_id.match(/^rel/)) {
            return;
        }
        return row;
    })
    .on('data', function (row, index) {
        var id = row.nid_id;
        var cats;
        // not every entry has categories
        try {
            cats = row.categories.split(',');
        }
        // so just ommit these ones
        catch (e) { return; }

        if(!monuments[row.nid_id]) {
            monuments[row.nid_id] = {revisions: 0};
        }
        cats.forEach(function (e) {
            monuments[id][e] = (monuments[id][e] || 0) + 1;
        });
        monuments[id].revisions += 1;
    })
    .on('end', function (count) {
        var id;
        var cat;

        for(id in monuments ) { if(monuments.hasOwnProperty(id)) {
            for(cat in monuments[id]) { if(monuments[id].hasOwnProperty(cat)) {
                // get only these categories that occured in every revision
                if(cat !== 'revisions' && monuments[id].revisions === monuments[id][cat]) {
                    results[cat] = (results[cat] || 0) + 1;
                }
            }}
        }}

        for(cat in results) {
            cats_csv.write({category: cat, count: results[cat]});
        }
        cats_csv.end();
    })
    .on('error', function (err) {
        console.log('!!! '+ err);
        process.exit();
    });
