#!/usr/bin/sh
echo ">>> Downloading the revisions history file"
wget http://otwartezabytki.pl/system/relics_history.csv

echo ">>> Installing csv library for Node"
npm install

for f in *js; do
    echo ">>> Processing " $f
    node $f;
done
echo ">>> I'm all done!"

