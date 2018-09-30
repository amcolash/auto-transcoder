# amcolash/auto-transcoding:0.1

FROM ntodd/video-transcoding:latest
LABEL maintainer="Andrew McOlash <amcolash@gmail.com>"

COPY ./auto-transcode.sh /data/auto-transcode.sh

WORKDIR /videos

CMD [ "/data/auto-transcode.sh" ]