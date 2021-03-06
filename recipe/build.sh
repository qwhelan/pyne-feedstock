#!/usr/bin/env bash
set -e

if [ "$(uname)" == "Darwin" ]; then
  skiprpath="-DCMAKE_SKIP_RPATH=TRUE"
else
  skiprpath=""
fi
export FC=gfortran

# Install PyNE
export VERBOSE=1
${PYTHON} setup.py install \
  --build-type="Release" \
  --prefix="${PREFIX}" \
  --hdf5="${PREFIX}" \
  --moab="${PREFIX}" \
  -DMOAB_INCLUDE_DIR="${PREFIX}/include" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_VERSION_MIN}" \
  ${skiprpath} \
  --clean \
  -j "${CPU_COUNT}"

# PyNE's build system is wack
# mv the shared object to the standard location and then softlink it back
# likewise for the headers
# Create data library
eggname=$(ls build/dist)
egglib=$(ls -d "${SP_DIR}/${eggname}/lib")
if [ -d "${egglib}" ]; then
  eggdir=$(dirname "${egglib}")
else
  eggdir="${SP_DIR}"
fi
ls "${eggdir}"
mv "${eggdir}/lib/libpyne${SHLIB_EXT}" "${PREFIX}/lib/libpyne${SHLIB_EXT}"
ln -s "${PREFIX}/lib/libpyne${SHLIB_EXT}" "${eggdir}/lib/libpyne${SHLIB_EXT}"
mv "${eggdir}/include/pyne" "${PREFIX}/include"
ln -s "${PREFIX}/include/pyne" "${eggdir}/include"

# Create data library
cd build
if [ "$(uname)" == "Darwin" ]; then
  export DYLD_FALLBACK_LIBRARY_PATH="${DYLD_FALLBACK_LIBRARY_PATH}:${PREFIX}/lib"
else
  export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${PREFIX}/lib"
fi
${PYTHON} ${PREFIX}/bin/nuc_data_make