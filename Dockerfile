FROM ubuntu:16.04

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libatlas-base-dev \
    libboost-all-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libhdf5-serial-dev \
    libleveldb-dev \
    liblmdb-dev \
    libprotobuf-dev \
    libsnappy-dev \
    protobuf-compiler \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-numpy \
    python3-scipy \
    libusb-1.0-0 \
    wget \
    git \
    automake \
    cmake \
    pkg-config \
    unzip \
    curl \
    sudo \
    libgtk2.0-dev \
    libsm6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 

RUN git clone https://github.com/opencv/opencv.git && \
    mkdir opencv/build && \
    echo 'set(PYTHON_DEFAULT_EXECUTABLE "${PYTHON3_EXECUTABLE}")' >> opencv/cmake/OpenCVDetectPython.cmake && \
    cd opencv/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D BUILD_EXAMPLES=OFF \
    -D BUILD_TESTS=OFF \
    -D BUILD_opencv_stitching=OFF \
    -D BUILD_opencv_superres=OFF \
    -D BUILD_opencv_python2=OFF \
    -D BUILD_opencv_python3=ON \
    -D WITH_FFMPEG=OFF \
    -D WITH_CUDA=OFF \
    -D WITH_GTK=ON \
    -D WITH_VTK=OFF \
    -D INSTALL_TESTS=OFF \
    -D BUILD_EXAMPLES=OFF \
    .. && make all -j4 && make install && \
    cd ../.. && rm -r ./opencv

ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

ENV CLONE_TAG=1.0

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git . && \
    pip3 install --upgrade pip && \
    cd python && for req in $(cat requirements.txt) pydot; do pip3 install $req; done && cd .. && \
    pip3 install python-dateutil --upgrade && \
    pip3 install graphviz && \
    sed -i 's/python_version "2"/python_version "3"/' CMakeLists.txt && \
    mkdir build && cd build && \
    cmake -DCPU_ONLY=1 .. && \
    make -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

RUN mkdir /opt/movidius

WORKDIR /opt/movidius

RUN wget -c --quiet https://ncsforum.movidius.com/uploads/editor/ho/up2ggsopcmuy.tgz && \
    tar xvf up2ggsopcmuy.tgz && \
    tar xvf MvNC_API-1.07.06.tgz 

RUN cd ncapi/redist && dpkg -i * && cd ../../ && rm -rf ncapi

RUN groupadd -g 1000 ubuntu && \
    useradd -g ubuntu -G sudo -m -s /bin/bash ubuntu && \
    echo 'ubuntu:ubuntu' | chpasswd

RUN usermod -a -G users ubuntu

RUN mkdir -p /home/ubuntu/data
RUN chown -R ubuntu:ubuntu /home/ubuntu

USER ubuntu

WORKDIR "/home/ubuntu"

RUN wget -c --quiet https://ncsforum.movidius.com/uploads/editor/ho/up2ggsopcmuy.tgz && \
    tar xvf up2ggsopcmuy.tgz && \
    tar xvf MvNC_API-1.07.06.tgz && \
    tar xvf MvNC_Toolkit-1.07.06.tgz && \
    rm *.tgz

CMD ["/bin/bash"]
