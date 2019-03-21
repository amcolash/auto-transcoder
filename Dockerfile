# amcolash/auto-transcoder:0.1

FROM ntodd/video-transcoding:latest
LABEL maintainer="Andrew McOlash <amcolash@gmail.com>"

RUN apt-get update && apt-get install -y bc && rm -rf /var/lib/apt/lists/*

COPY ./auto-transcode.sh /data/auto-transcode.sh

WORKDIR /videos

CMD [ "/data/auto-transcode.sh" ]