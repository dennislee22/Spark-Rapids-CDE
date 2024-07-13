FROM xxxxx/cloudera/dex/dex-livy-runtime-gpu-3.2.3-7.1.7.2035:1.20.2-b75
USER root
RUN yum update -y
RUN subscription-manager register --username=xxx --password=xxx --auto-attach

RUN yum install ${YUM_OPTIONS} gcc openssl-devel libffi-devel bzip2-devel wget python39 python39-devel  && yum clean all && rm -rf /var/cache/yum
RUN update-alternatives --remove-all python
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

RUN rm /usr/bin/python3
RUN ln -s /usr/bin/python3.9 /usr/bin/python3
RUN ln -s /usr/bin/python3.9 /usr/bin/python
RUN yum -y install python39-pip
RUN /usr/bin/python3.9 -m pip install --upgrade pip
ENV PYTHONPATH="${PYTHONPATH}:/usr/local/lib64/python3.9/site-packages:/usr/local/lib/python3.9/site-packages"

ENV distro=rhel8
ENV arch=x86_64
RUN dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.repo
RUN yum update -y
ENV LD_LIBRARY_PATH "$LD_LIBRARY_PATH:/usr/local/cuda-12.1/compat:/usr/local/cuda-12.1/targets/x86_64-linux/lib/"

RUN yum -y install cuda-toolkit-12-1
#RUN dnf -y install --allowerasing cudnn9-cuda-12
#RUN dnf -y install libnccl libnccl-devel libnccl-static
#RUN dnf -y install libcutensor1 libcutensor-devel libcutensor-doc
#RUN dnf -y install libcusparselt0 libcusparselt-devel

RUN rm /usr/local/cuda 
RUN ln -s /usr/local/cuda-12.1 /usr/local/cuda
#ENV PATH=""$PATH:/usr/local/cuda-12.1/bin"
#ENV NVCC="/usr/local/cuda-12.1/bin/nvcc"
#ENV CUDA_PATH="/usr/local/cuda-12.1"
#ENV LDFLAGS="/usr/local/cuda-12.1/lib64"
#ENV LIBRARY_PATH="/usr/local/cuda-12.1/lib64"
#ENV CFLAGS="/usr/local/cuda-12.1/include"

RUN /usr/bin/python3.9 -m pip install cupy-cuda12x
RUN /usr/bin/python3.9 -m pip install cudf-cu12

#RUN python -c 'import cupy'

#USER sparkuser
RUN pip3 install nvitop
RUN pip3 install bpytop
