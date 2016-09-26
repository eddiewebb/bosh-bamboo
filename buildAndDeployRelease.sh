#!/bin/bash
pushd release
bosh create release --force
bosh upload release
bosh deploy --recreate --skip-drain
popd