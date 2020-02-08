FROM arm32v6/alpine:latest
COPY qemu-arm-static /usr/bin/

RUN apk add python3

RUN cd /usr/bin \
  && ln -sf python3 python \
  && ln -sf pip3 pip \
  && cd -

# Install required packages
RUN apk add --update --virtual=.build-dependencies alpine-sdk nodejs ca-certificates musl-dev gcc python-dev make cmake g++ gfortran libpng-dev freetype-dev libxml2-dev libxslt-dev linux-headers zeromq-dev
RUN apk add --update git

# Install Jupyter
RUN pip install jupyter
RUN pip install ipywidgets
RUN jupyter nbextension enable --py widgetsnbextension

# Install JupyterLab
RUN pip install jupyterlab && jupyter serverextension enable --py jupyterlab

# Additional packages for compatability (glibc)
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub && \
  wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-2.30-r0.apk && \
  wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-i18n-2.30-r0.apk && \
  wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-bin-2.30-r0.apk && \
  apk add --no-cache glibc-2.30-r0.apk glibc-bin-2.30-r0.apk glibc-i18n-2.30-r0.apk && \
  rm "/etc/apk/keys/sgerrand.rsa.pub" && \
  /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
  echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
 ln -s /usr/include/locale.h /usr/include/xlocale.h

# Optional Clean-up
#  RUN apk del glibc-i18n && \
#  apk del .build-dependencies && \
#  rm glibc-2.30-r0.apk glibc-bin-2.30-r0.apk glibc-i18n-2.30-r0.apk && \
#  rm -rf /var/cache/apk/*

ENV LANG=C.UTF-8

# Install Python Packages & Requirements (Done near end to avoid invalidating cache)
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Expose Jupyter port & cmd
EXPOSE 8888
VOLUME /notebooks
ENTRYPOINT jupyter lab --ip=* --port=8888 --no-browser --allow-root --notebook-dir=/notebooks

