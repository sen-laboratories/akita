#!/bin/bash
HAIKU_OUT_DIR=$HOME/Develop/senryu/generated/objects/haiku/x86_64/release

cp $HAIKU_OUT_DIR/kits/tracker/libtracker.so ./bin/lib/ && \
cp $HAIKU_OUT_DIR/apps/tracker/Tracker ./bin/Akita && \
echo "Akita updated and ready to roll." || \
echo "Error updating Akita."

