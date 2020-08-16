ARG NODE_IMAGE=node:14.8.0-alpine3.10
ARG RUNTIME_IMAGE=archlinux:20200705
ARG BUILDDIR=/usr/src/flood/
ARG WORKDIR=/opt/flood
ARG USER=alaneuler

FROM ${NODE_IMAGE} as BUILD
ARG BUILDDIR
WORKDIR $BUILDDIR

COPY package.json \
 	 package-lock.json \
   	 .babelrc \
	 .eslintrc.js \
	 .eslintignore \
	 .prettierrc \
     ABOUT.md \
	 $BUILDDIR
RUN apk add --no-cache --virtual=build-dependencies \
    python build-base && \
    npm install && \
    apk del --purge build-dependencies
COPY client ./client
COPY server ./server
COPY shared ./shared
COPY scripts ./scripts
COPY config.js ./config.js
RUN npm run build && \
    npm prune --production

FROM ${RUNTIME_IMAGE}
ARG WORKDIR
ARG BUILDDIR
ARG USER
WORKDIR $WORKDIR

RUN pacman -Sy --noconfirm --needed rtorrent npm
COPY --from=BUILD $BUILDDIR $WORKDIR
COPY rtorrent.rc /etc/
COPY start.sh /usr/bin
RUN chmod a+x /usr/bin/start.sh

RUN useradd -m -s /bin/bash $USER
RUN mkdir -p /opt/ && chown -R alaneuler:alaneuler /opt/

USER alaneuler
EXPOSE 3000
CMD [ "start.sh" ]
